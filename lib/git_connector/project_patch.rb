module GitConnector
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :git_connector_repos, dependent: :destroy, class_name: 'GitConnector::Repo'
        has_many :git_connector_commits, dependent: :destroy, class_name: 'GitConnector::Commit'
        has_many :git_connector_pull_requests, dependent: :destroy, class_name: 'GitConnector::PullRequest'
      end
    end
  end
end