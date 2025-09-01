class CreateGlobalSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :git_connector_global_settings do |t|
      t.integer :provider, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :base_url
      t.timestamps
    end
    add_index :git_connector_global_settings, :provider, unique: true
  end
end