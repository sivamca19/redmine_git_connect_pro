class GitConnector::Commit < ApplicationRecord
  self.table_name = 'git_connector_commits'
  belongs_to :repo, class_name: "GitConnector::Repo"
  belongs_to :issue, optional: true
end