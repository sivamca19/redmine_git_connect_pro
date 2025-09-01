Redmine::Plugin.register :redmine_git_connect_pro do
  name 'Redmine Git Connect Pro plugin'
  author 'Sivamanikandan'
  description 'Git Connector Pro is a Redmine plugin that integrates Git repositories seamlessly into Redmine projects. It allows teams to manage repositories, configure global and project-level settings, and link code activity directly with project management workflows in Redmine.'
  version '0.0.1'
  url 'https://github.com/sivamca19/redmine_git_connect_pro.git'
  author_url 'https://github.com/sivamca19'

  # admin menu
  menu :admin_menu, :git_connector, { controller: 'git_connector/admin/global_settings', action: 'index' }, caption: 'Git Connector', html: { class: 'icon icon-git' }
  
  # project menu
  menu :project_menu, :git_connector, { controller: 'git_connector/repos', action: 'index' }, 
    caption: 'Git Connector', after: :settings, param: :project_id, selected: true


  project_module :git_connector do
    permission :view, { 'git_connector/repos': [:index, :show]  }
    permission :create, { 'git_connector/repos': [:new, :create, :index, :show]  }
    permission :edit, { 'git_connector/repos': [:index, :edit, :update, :show]  }
    permission :delete, { 'git_connector/repos': [:destroy, :toggle_webhook]  }
    permission :authenticate, { 'git_connector/repos': [:connect]  }
    permission "Enable / Disable Webhook", { 'git_connector/repos': [:toggle_webhook]  }
  end
end
require_relative 'lib/git_connector/hooks'
require_relative 'lib/git_connector/project_patch'
Project.include GitConnector::ProjectPatch unless Project.included_modules.include?(GitConnector::ProjectPatch)