require 'net/http'
require 'uri'
require 'json'

module GitConnector
  class ReposController < ApplicationController
    helper :sort
    include SortHelper

    before_action :find_project, except: [:oauth_callback]
    before_action :authorize, except: [:connect, :oauth_callback]
    before_action :set_repo, only: [:edit, :update, :toggle_webhook, :disconnect]

    def index
      sort_init 'name', 'asc'
      sort_update(
        'name'       => "#{Repo.table_name}.name",
        'created_at' => "#{Repo.table_name}.created_at",
        'updated_at' => "#{Repo.table_name}.updated_at"
      )

      scope = @project.git_connector_repos
      scope = apply_filters(scope)
      scope = scope.reorder(sort_clause)

      paginate_repos(scope)
    end

    def new
      @repo = @project.git_connector_repos.build
      load_providers
    end

    def create
      @repo = @project.git_connector_repos.build(repo_params)
      if @repo.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to action: :index
      else
        load_providers
        render :new
      end
    end

    def edit
      load_providers
    end

    def update
      if @repo.update(repo_params)
        flash[:notice] = l(:notice_successful_update)
        redirect_to action: :index
      else
        load_providers
        render :edit
      end
    end

    def toggle_webhook
      service = build_webhook_service(@repo)

      if @repo.webhook_active?
        service.deactivate_webhook(@repo.webhook_id, active: false)
        @repo.update(webhook_active: false)
        flash[:notice] = l(:notice_webhook_deactivated)
      else
        activate_or_create_webhook(@repo, service)
        flash[:notice] = l(:notice_webhook_activated)
      end

      redirect_to git_connector_project_repos_path(@project)
    end

    def connect
      provider = params[:provider]
      global_setting = GitConnector::GlobalSetting.find_by(provider: provider)
      redirect_to oauth_url(provider, global_setting, repo_id: params[:repo_id])
    end

    def disconnect
      @repo.update(access_token: nil, refresh_token: nil)
      flash[:notice] = l(:notice_successful_disconnect)
      redirect_to git_connector_project_repos_path(@project)
    end

    def oauth_callback
      state = JSON.parse(params[:state]) rescue {}
      @project   = Project.find(state['project_id'])
      repo       = @project.git_connector_repos.find(state['repo_id'])
      provider   = state['provider']
      setting    = GitConnector::GlobalSetting.find_by(provider: provider)

      token_data = exchange_code_for_token(provider, setting, params[:code])

      repo.update(
        access_token:  token_data["access_token"],
        refresh_token: token_data["refresh_token"]
      )

      flash[:notice] = "#{provider.titleize} #{l(:notice_successful_connection)}"
      redirect_to git_connector_project_repos_path(@project)
    end

    private

    ### Helpers ###

    def find_project
      @project = Project.find(params[:project_id])
    end

    def set_repo
      @repo = @project.git_connector_repos.find(params[:id] || params[:repo_id])
    end

    def load_providers
      @providers = GitConnector::GlobalSetting.all
    end

    def repo_params
      params.require(:git_connector_repo).permit(:repo_name, :repo_url, :provider, :access_token, :refresh_token)
    end

    def apply_filters(scope)
      if params[:search].present?
        q = "%#{params[:search]}%"
        scope = scope.where("repo_name LIKE :q OR repo_url LIKE :q", q: q)
      end

      scope = scope.where(provider: params[:provider].downcase) if params[:provider].present?

      case params[:status]
      when "connected"
        scope = scope.where.not(access_token: [nil, ""])
      when "disconnected"
        scope = scope.where(access_token: [nil, ""])
      end

      scope
    end

    def build_webhook_service(repo)
      WebhookService::Factory.build(
        repo.provider,
        repo_url: repo.repo_url,
        access_token: repo.access_token,
        callback_url: webhook_callback_url(repo.provider)
      )
    end

    def activate_or_create_webhook(repo, service)
      if repo.webhook_id.blank?
        result = service.create_webhook
        repo.update(
          webhook_id:     result[:id],
          webhook_secret: result[:secret],
          webhook_active: true
        )
      else
        service.activate_webhook(repo.webhook_id, active: true)
        repo.update(webhook_active: true)
      end
    end

    def oauth_url(provider, setting, repo_id:)
      state = { repo_id: repo_id, project_id: @project.id, provider: provider }.to_json

      case provider
      when "github"
        "https://github.com/login/oauth/authorize?" \
        "client_id=#{setting.client_id}" \
        "&redirect_uri=#{oauth_callback_url}" \
        "&scope=repo,admin:repo_hook" \
        "&state=#{CGI.escape(state)}"
      when "gitlab"
        "https://gitlab.com/oauth/authorize?" \
        "client_id=#{setting.client_id}" \
        "&redirect_uri=#{oauth_callback_url}" \
        "&response_type=code&scope=api"
      end
    end

    def exchange_code_for_token(provider, setting, code)
      case provider
      when "github"
        uri = URI.parse("https://github.com/login/oauth/access_token")
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(
          client_id:     setting.client_id,
          client_secret: setting.client_secret,
          code:          code,
          redirect_uri:  oauth_callback_url
        )
        req['Accept'] = 'application/json'

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
        JSON.parse(res.body)
      when "gitlab"
        uri = URI.parse("https://gitlab.com/oauth/token")
        res = Net::HTTP.post_form(uri,
          client_id:     setting.client_id,
          client_secret: setting.client_secret,
          code:          code,
          grant_type:    "authorization_code",
          redirect_uri:  oauth_callback_url
        )
        JSON.parse(res.body)
      end
    end

    def oauth_callback_url
      "http://localhost:3000/git_connector/projects/oauth/callback"
    end

    def webhook_callback_url(provider)
      Rails.application.routes.url_helpers.webhook_receive_url(
        provider,
        host: ENV["APP_URL"]
      )
    end

    def paginate_repos(scope)
      @repo_count = scope.count
      @limit      = per_page_option
      @repo_pages = Paginator.new(@repo_count, @limit, params[:page])
      @repos      = scope.offset(@repo_pages.offset).limit(@limit)
    end
  end
end