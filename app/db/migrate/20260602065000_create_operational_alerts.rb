class CreateOperationalAlerts < ActiveRecord::Migration[8.1]
  def change
    # D5 — operational alerts so WE find out before customers do: dispute-clock
    # anomalies, auto-accept misfires, notification delivery failures, CSV ingest
    # errors. Persisted (and logged) so they're queryable and testable.
    create_table :operational_alerts do |t|
      t.string :kind, null: false
      t.text :message, null: false
      t.jsonb :context, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :operational_alerts, :kind
    add_index :operational_alerts, :created_at
  end
end
