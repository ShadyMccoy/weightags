class AddDisputeClockToLoads < ActiveRecord::Migration[8.1]
  def change
    # Window snapshot (days) taken at pairing time, like tolerance_bps, so the
    # clock is deterministic even if the partnership setting changes later.
    add_column :loads, :dispute_window_days, :integer, null: false, default: 14
    # Idempotency markers so each reminder fires at most once (B5 retry-safety).
    add_column :loads, :clock_reminded_half_at, :datetime
    add_column :loads, :clock_reminded_final_at, :datetime

    # The sweep finds due/reminder-due loads by clock_due_at; index it.
    add_index :loads, :clock_due_at
  end
end
