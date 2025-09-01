require 'openssl'

class WebhookReceiverService
  def self.call(request)
    new(request).process
  end

  def initialize(request)
    @request = request
    @headers = request.headers
    @raw_body = read_body
    @payload = parse_payload
    @provider = detect_provider
    @repo = find_repo 
  end

  def process
    case @provider
    when :github
      return { status: :unauthorized, message: "Invalid signature" } unless verify_github_signature
      handle_github
    when :gitlab
      verify_gitlab_token
      handle_gitlab
    when :bitbucket
      handle_bitbucket
    else
      { status: :error, message: "Unknown provider" }
    end
  end

  private

  def read_body
    @request.body.rewind
    @request.body.read
  end

  def parse_payload
    JSON.parse(@raw_body) rescue {}
  end

  def detect_provider
    if @headers["X-GitHub-Event"]
      :github
    elsif @headers["X-Gitlab-Event"]
      :gitlab
    elsif @headers["X-Event-Key"]
      :bitbucket
    else
      :unknown
    end
  end

  def find_repo
    case @provider
    when :github
      repo_name = @payload.dig("repository", "name")
      GitConnector::Repo.find_by(repo_name: repo_name)
    when :gitlab
      repo_name = @payload.dig("project", "path_with_namespace")
      GitConnector::Repo.find_by(repo_name: repo_name)
    when :bitbucket
      repo_name = @payload.dig("repository", "name")
      GitConnector::Repo.find_by(repo_name: repo_name)
    else
      nil
    end
  end

  def verify_github_signature
    signature = @headers['X-Hub-Signature-256'].to_s
    secret    = @repo&.webhook_secret

    return false if signature.blank? || secret.blank?

    expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret,
      @raw_body
    )

    Rack::Utils.secure_compare(expected_signature, signature)
  end

  def verify_gitlab_token
    expected = ENV['GITLAB_WEBHOOK_SECRET']
    token    = @headers['X-Gitlab-Token']

    return true if expected.blank?
    token.present? && Rack::Utils.secure_compare(expected, token)
  end

  def handle_github
    event = @headers["X-GitHub-Event"]

    case event
    when "push"
      {
        provider: :github,
        event: event,
        repo_short_name: @payload.dig("repository", "name"),
        repo: @payload.dig("repository", "full_name"),
        branch: extract_github_branch,
        commit: @payload.dig("head_commit", "id"),
        message: @payload.dig("head_commit", "message"),
        user: @payload.dig("pusher", "name"),
        email: @payload.dig("pusher", "email")
      }

    when "pull_request"
      pr = @payload["pull_request"]

      {
        provider: :github,
        event: event,
        action: @payload["action"],
        repo_short_name: @payload.dig("repository", "name"),
        repo: @payload.dig("repository", "full_name"),
        branch: pr.dig("head", "ref"),
        commit: pr.dig("head", "sha"),
        title: pr["title"],
        description: pr["body"],
        user: pr.dig("user", "login"),
        url: pr["html_url"],
        merged: pr["merged"] || false
      }

    else
      { provider: :github, event: event, raw: @payload }
    end
  end

  def extract_github_branch
    ref = @payload["ref"]
    ref&.split("/")&.last
  end

  def handle_gitlab
    {
      provider: :gitlab,
      event: @headers["X-Gitlab-Event"],
      repo: @payload.dig("project", "path_with_namespace"),
      branch: extract_gitlab_branch,
      commit: @payload.dig("checkout_sha"),
      message: @payload.dig("commits")&.last&.dig("message"),
      user: @payload.dig("user_username")
    }
  end

  def extract_gitlab_branch
    ref = @payload["ref"]
    ref&.split("/")&.last
  end

  def handle_bitbucket
    {
      provider: :bitbucket,
      event: @headers["X-Event-Key"],
      repo: @payload.dig("repository", "full_name"),
      branch: extract_bitbucket_branch,
      commit: @payload.dig("push", "changes")&.first&.dig("new", "target", "hash"),
      message: @payload.dig("push", "changes")&.first&.dig("new", "target", "message"),
      user: @payload.dig("actor", "username")
    }
  end

  def extract_bitbucket_branch
    @payload.dig("push", "changes")&.first&.dig("new", "name")
  end
end