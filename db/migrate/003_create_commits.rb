class CreateCommits < ActiveRecord::Migration[6.0]
  create_table :git_connector_commits do |t|
    t.references :repo, foreign_key: { to_table: :git_connector_repos }
    t.integer :issue_id
    t.string :commit_hash, null: false
    t.string :message
    t.string :author_name
    t.string :author_email
    t.datetime :committed_at
    t.timestamps
  end
end