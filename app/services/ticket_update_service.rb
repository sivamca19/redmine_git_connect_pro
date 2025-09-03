class TicketUpdateService
  ISSUE_PATTERN = /#(\d+)/

  def self.call(webhook_data)
    new(webhook_data).process
  end

  def initialize(webhook_data)
    @data    = webhook_data
    @message = webhook_data[:message].to_s
    @event   = webhook_data[:event].to_s
  end

  def process
    issue_ids.each do |id|
      update_issue(id)
    end
  end

  private

  def issue_ids
    text_sources = [@message, @data[:title], @data[:description]].compact
    text_sources.join(" ").scan(ISSUE_PATTERN).flatten.uniq
  end

  def update_issue(issue_id)
    issue = Issue.find_by(id: issue_id)
    return unless issue
    persist_event(issue)
    note = sanitize_note(build_note)
    issue.init_journal(find_author, note)
    update_status(issue)
    issue.save!
  end

  def build_note
    commit_link = commit_url
    action      = case @event
                  when "push"          then "Commit pushed"
                  when "pull_request"  then "Pull Request #{@data[:merged] ? "merged" : @data[:action]}"
                  else "Update"
                  end

    <<~MSG
      🔔 **#{action}** from *#{@data[:provider].to_s.titleize}*

      Repository: #{@data[:repo]}
      Branch: #{@data[:branch]}
      Commit: [#{@data[:commit]}](#{commit_link})
      Author: #{@data[:user]}

      **Message:**
      #{@data[:message]}
    MSG
  end

  def commit_url
    case @data[:provider]
    when :github
      "https://github.com/#{@data[:repo]}/commit/#{@data[:commit]}"
    when :gitlab
      "https://gitlab.com/#{@data[:repo]}/-/commit/#{@data[:commit]}"
    when :bitbucket
      "https://bitbucket.org/#{@data[:repo]}/commits/#{@data[:commit]}"
    else
      ""
    end
  end

  def find_author
    login = @data[:email].to_s.strip
    return User.anonymous if login.blank?

    User.joins(:email_addresses)
      .where("users.login = :login OR email_addresses.address = :login", login: login)
      .where(email_addresses: { is_default: true })
      .order("users.id DESC")
      .first || create_user(login)
  end

  def create_user(login)
    firstname = @data[:name].to_s.strip
    firstname = firstname[0, 29].capitalize if firstname.present?
    User.create!(
      login: login,
      firstname: firstname.presence || "Auto",
      lastname: "(auto)",
      mail: "#{login.parameterize}@autogen.local",
      language: Setting.default_language || "en",
      status: User::STATUS_ACTIVE,
      auth_source_id: nil
    )
  end

  def update_status(issue)
    return unless @event == "pull_request"
    settings = Setting.plugin_redmine_git_connect_pro
    case @data[:action]
    when "opened"
      in_progress = IssueStatus.find_by(name: settings['status_opened'])
      issue.status = in_progress if in_progress

    when "closed"
      if @data[:merged]
        resolved = IssueStatus.find_by(name: settings['status_closed_merged'])
        issue.status = resolved if resolved
      else
        rejected = IssueStatus.find_by(name: settings['status_closed_reopened'])
        issue.status = rejected if rejected
      end
    end
  end

  def persist_event(issue)
    case @event
    when "push"
      GitConnector::Commit.create!(
        repo: GitConnector::Repo.find_by(repo_name: @data[:repo_short_name]),
        issue: issue,
        commit_hash: @data[:commit],
        message: @data[:message],
        author_name: @data[:user],
        author_email: @data[:email],
        committed_at: Time.current
      )
    when "pull_request"
      GitConnector::PullRequest.find_or_create_by!(
        repo: GitConnector::Repo.find_by(repo_name: @data[:repo_short_name]),
        issue: issue,
        pr_number: @data[:commit] # or PR number if available
      ) do |pr|
        pr.title = @data[:title]
        pr.url   = @data[:url]
        pr.author_name = @data[:user]
        pr.state = @data[:action] # opened, closed, merged
        pr.opened_at = Time.current if @data[:action] == "opened"
        pr.closed_at = Time.current if @data[:action] == "closed"
        pr.merged_at = Time.current if @data[:merged]
      end
    end
  end

  def closes_issue?
    @message.match?(/(fixes|closes|resolves)\s+#\d+/i)
  end

  def sanitize_note(note)
    note.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        .gsub(/[\u{1F300}-\u{1FAFF}]/, '') # remove emojis
  end
end