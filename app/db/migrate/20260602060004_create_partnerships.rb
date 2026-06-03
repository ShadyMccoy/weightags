class CreatePartnerships < ActiveRecord::Migration[8.1]
  def change
    create_table :partnerships do |t|
      # Directional: each org keeps its own settings toward a counterparty.
      t.references :org, null: false, foreign_key: true
      t.references :counterparty_org, null: false, foreign_key: { to_table: :orgs }
      # Tolerance in basis points of net weight (50 = 0.5%); drives the "within
      # tolerance" flag (C3). Dispute window in days drives the clock (B5).
      t.integer :tolerance_bps, null: false, default: 50
      t.integer :dispute_window_days, null: false, default: 14
      # Set while the counterparty is still a ghost org awaiting claim (A5).
      t.string :invite_email

      t.timestamps
    end
    add_index :partnerships, [ :org_id, :counterparty_org_id ], unique: true
  end
end
