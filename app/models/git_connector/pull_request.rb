class GitConnector::PullRequest < ApplicationRecord
  self.table_name = 'git_connector_pull_requests'
  belongs_to :repo, class_name: "GitConnector::Repo"
  belongs_to :issue, optional: true
end