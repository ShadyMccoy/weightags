class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true   # recipient
      t.references :org, null: false, foreign_key: true    # org context it belongs to
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.references :subject, polymorphic: true
      t.string :url
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :user_id, :org_id, :read_at ]
  end
end
