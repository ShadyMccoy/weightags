class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    # Append-only event log. NOTE: no updated_at — rows are never modified.
    create_table :audit_events do |t|
      # Actor: the user who performed the action (null for system actions such
      # as auto-pair or auto-accept). Role is deliberately NOT stored here — it
      # is reconstructable from memberships. Org is parenthetical attribution only.
      t.references :user, foreign_key: true
      t.references :actor_org, foreign_key: { to_table: :orgs }

      # What happened, e.g. "tag.posted", "load.paired", "load.disputed".
      t.string :action, null: false

      # Polymorphic subject (a Load or a Tag).
      t.references :subject, polymorphic: true

      # Denormalised for a readable cross-load activity feed (C1).
      t.string :bol

      # Structured details: reasons, before/after values, etc.
      t.jsonb :metadata, null: false, default: {}

      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :audit_events, :action
    add_index :audit_events, :occurred_at
  end
end
