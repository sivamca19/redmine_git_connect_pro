module GitConnector
  class Repo < ApplicationRecord
    self.table_name = 'git_connector_repos'
    belongs_to :project

    validates :provider, :repo_name, :repo_url, presence: true

    enum provider: { github: 0, gitlab: 1, gitbucket: 2, other: 3 }

    # Encrypt tokens
    encrypts :access_token
    encrypts :refresh_token
  end
end