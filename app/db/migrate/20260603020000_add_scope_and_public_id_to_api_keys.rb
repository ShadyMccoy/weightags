class AddScopeAndPublicIdToApiKeys < ActiveRecord::Migration[8.1]
  # public_id: a non-secret, dashboard-visible identifier (the "key id") so a
  # credential is recognizable without exposing its secret.
  # scope: least-privilege — read_only (status sync) vs read_write (upload).
  def up
    add_column :api_keys, :public_id, :string
    add_column :api_keys, :scope, :string, null: false, default: "read_write"

    # Backfill any pre-existing rows (dev/test) before enforcing presence/uniqueness.
    execute <<~SQL
      UPDATE api_keys SET public_id = 'wtk_' || substr(md5(random()::text || id::text), 1, 16)
      WHERE public_id IS NULL;
    SQL

    change_column_null :api_keys, :public_id, false
    add_index :api_keys, :public_id, unique: true
  end

  def down
    remove_index :api_keys, :public_id
    remove_column :api_keys, :scope
    remove_column :api_keys, :public_id
  end
end
