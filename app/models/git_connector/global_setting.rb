module GitConnector
  class GlobalSetting < ApplicationRecord
    self.table_name = "git_connector_global_settings"
    enum provider: { github: 0, gitlab: 1, gitbucket: 2 }
    encrypts :client_secret
    validates :provider, presence: true, uniqueness: true
    validates :client_id, :client_secret, presence: true
  end
end
