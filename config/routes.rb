Rails.application.routes.draw do
  namespace :git_connector do
    namespace :admin do
      resources :global_settings
    end

    resources :projects, only: [:show] do
      resources :repos, controller: 'repos'
    end
    patch 'projects/:project_id/repos/:id/toggle_webhook', to: 'repos#toggle_webhook', as: :project_repo_toggle_webhook
    get '/projects/:project_id/connect', to: 'repos#connect', as: :project_repo_connect
    delete '/projects/:project_id/disconnect', to: 'repos#disconnect', as: :project_repo_disconnect
    get 'projects/oauth/callback', to: 'repos#oauth_callback', as: :project_oauth_callback
  end
  post '/webhooks/receive/:provider', to: 'webhooks#receive', as: :webhook_receive
end