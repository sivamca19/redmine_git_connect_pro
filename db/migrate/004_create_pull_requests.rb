class CreatePullRequests < ActiveRecord::Migration[6.0]
  create_table :git_connector_pull_requests do |t|
    t.references :repo, foreign_key: { to_table: :git_connector_repos }
    t.integer :issue_id
    t.string :pr_number, null: false
    t.string :title
    t.string :url
    t.string :author_name
    t.string :author_email
    t.string :state # open, merged, closed
    t.datetime :opened_at
    t.datetime :closed_at
    t.datetime :merged_at
    t.timestamps
  end
end