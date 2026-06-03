class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :org, null: false, foreign_key: true
      # role lives here, queryable — it is deliberately NOT embedded in audit_events.
      t.integer :role, null: false, default: 0
      t.datetime :joined_at, null: false
      t.datetime :ended_at

      t.timestamps
    end
    # A user has at most one active membership per org. Ended memberships are
    # preserved for audit attribution, so uniqueness only covers active ones.
    add_index :memberships, [ :user_id, :org_id ], unique: true, where: "ended_at IS NULL",
      name: "index_active_memberships_on_user_and_org"
  end
end
