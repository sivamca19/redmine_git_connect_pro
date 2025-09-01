require 'net/http'
require 'uri'
require 'json'
module GitConnector
  class ReposController < ApplicationController
    helper :sort
    include SortHelper
    before_action :find_project, except: [:oauth_callback]
    before_action :authorize, except: [:connect, :oauth_callback]

    def index
      sort_init 'name', 'asc'
      sort_update 'name' => "#{Repo.table_name}.name",
                  'created_at' => "#{Repo.table_name}.created_at",
                  'updated_at' => "#{Repo.table_name}.updated_at"
      scope = @project.git_connector_repos
      if params[:search].present?
        scope = scope.where("repo_name LIKE ? OR repo_url LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
      end

      # Provider filter
      if params[:provider].present?
        scope = scope.where(provider: params[:provider].downcase)
      end

      # Status filter
      if params[:status] == "connected"
        scope = scope.where.not(access_token: [nil, ""])
      elsif params[:status] == "disconnected"
        scope = scope.where(access_token: [nil, ""])
      end
      @repos = scope.reorder(sort_clause)
      paginate_repos(scope)
    end

    def new
      @repo = @project.git_connector_repos.build
      @providers = GitConnector::GlobalSetting.all
    end

    def create
      @repo = @project.git_connector_repos.build(repo_params)
      if @repo.save
        flash[:notice] = "Repository connected successfully"
        redirect_to action: :index
      else
        @repos = @project.git_connector_repos
        @providers = GitConnector::GlobalSetting.all
        render :new
      end
    end

    def edit
      @repo = @project.git_connector_repos.find(params[:id])
      @providers = GitConnector::GlobalSetting.all
    end


    def create
      @repo = @project.git_connector_repos.build(repo_params)
      if @repo.save
        flash[:notice] = "Repository connected successfully"
        redirect_to action: :index
      else
        @repos = @project.git_connector_repos
        @providers = GitConnector::GlobalSetting.all
        render :new
      end
    end

    def toggle_webhook
      @repo = @project.git_connector_repos.find(params[:id])
      service = WebhookService::Factory.build(
        @repo.provider,
        repo_url: @repo.repo_url,
        access_token: @repo.access_token,
        callback_url: webhook_callback_url("github")
      )

      if @repo.webhook_active?
        service.deactivate_webhook(@repo.webhook_id, active: false)
        @repo.update(webhook_active: false)
        flash[:notice] = "Webhook deactivated"
      else
        if @repo.webhook_id.blank?
          result = service.create_webhook
          @repo.update(
            webhook_id: result[:id],
            webhook_secret: result[:secret],
            webhook_active: true
          )
        else
          service.activate_webhook(@repo.webhook_id, active: true)
          @repo.update(webhook_active: true)
        end
        flash[:notice] = "Webhook activated"
      end

      redirect_to git_connector_project_repos_path(@project)
    end

    def connect
      # OAuth redirect: user clicks "Connect GitHub"
      provider = params[:provider]
      global_setting = GitConnector::GlobalSetting.find_by(provider: provider)
      redirect_to oauth_url(provider, global_setting, repo_id: params[:repo_id])
    end

    def disconnect
      @repo = @project.git_connector_repos.find(params[:repo_id])
      @repo.update(access_token: nil, refresh_token: nil)
      redirect_to git_connector_project_repos_path(@project)
    end

    def oauth_callback
      state = JSON.parse(params[:state]) rescue {}
      provider = state['provider']
      repo_id = state['repo_id']
      project_id = state['project_id']
      @project = Project.find(project_id)
      global_setting = GitConnector::GlobalSetting.find_by(provider: provider)
      token_data = exchange_code_for_token(provider, global_setting, params[:code])

      repo = @project.git_connector_repos.find(repo_id)
      repo.update(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"]
      )
      flash[:notice] = "#{provider.titleize} connected successfully!"
      redirect_to git_connector_project_repos_path(@project)
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    end

    def repo_params
      params.require(:git_connector_repo).permit(:repo_name, :repo_url, :provider, :access_token, :refresh_token)
    end

    def oauth_url(provider, global_setting, repo_id:)
      state = { repo_id: repo_id, project_id: @project.id, provider: provider }.to_json
      case provider
      when "github"
        "https://github.com/login/oauth/authorize?" \
        "client_id=#{global_setting.client_id}" \
        "&redirect_uri=#{oauth_callback_url}" \
        "&scope=repo,admin:repo_hook" \
        "&state=#{CGI.escape(state)}"
      when "gitlab"
        "https://gitlab.com/oauth/authorize?client_id=#{global_setting.client_id}&redirect_uri=#{oauth_callback_url(provider)}&response_type=code&scope=api"
      end
    end

    def exchange_code_for_token(provider, global_setting, code)
      case provider
      when "github"
        uri = URI.parse("https://github.com/login/oauth/access_token")
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(
          client_id: global_setting.client_id,
          client_secret: global_setting.client_secret,
          code: code,
          redirect_uri: oauth_callback_url
        )
        req['Accept'] = 'application/json'  # << important

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end

        JSON.parse(res.body)   # now this will work
      when "gitlab"
        uri = URI.parse("https://gitlab.com/oauth/token")
        res = Net::HTTP.post_form(uri,
          client_id: global_setting.client_id,
          client_secret: global_setting.client_secret,
          code: code,
          grant_type: "authorization_code",
          redirect_uri: oauth_callback_url
        )
        JSON.parse(res.body)
      end
    end

    def oauth_callback_url
      "http://localhost:3000/git_connector/projects/oauth/callback"
    end
    def webhook_callback_url(provider)
      Rails.application.routes.url_helpers.webhook_receive_url(provider, host: "https://6383042217e1.ngrok-free.app")
    end

    def paginate_repos(scope)
      @repo_count = scope.count
      @limit        = per_page_option
      @repo_pages = Paginator.new(@repo_count, @limit, params[:page])
      @offset       = @repo_pages.offset
      @repos      = scope.offset(@offset).limit(@limit)
    end
  end
end