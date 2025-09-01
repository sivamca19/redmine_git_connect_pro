module GitConnector
  class GlobalSetting < ApplicationRecord
    self.table_name = 'git_connector_global_settings'
    # Stores global client_id / client_secret per provider
    validates :provider, presence: true, uniqueness: true
    validates :client_id, presence: true
    validates :client_secret, presence: true

    enum provider: { github: 0, gitlab: 1, gitbucket: 2 }

    # Encrypt client_secret for security
    encrypts :client_secret
  end
end
