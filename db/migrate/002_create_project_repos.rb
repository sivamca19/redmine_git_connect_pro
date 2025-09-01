class CreateProjectRepos < ActiveRecord::Migration[6.0]
  def change
    create_table :git_connector_repos do |t|
      t.integer :provider, null: false
      t.integer :project_id, foreign_key: true
      t.string :repo_name, null: false
      t.string :repo_url, null: false
      t.string :access_token
      t.string :refresh_token
      t.string :webhook_id
      t.string :webhook_secret
      t.boolean :webhook_active, default: false
      t.timestamps
    end
  end
end