class CreateInvoiceBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_batches do |t|
      t.references :sender_org, null: false, foreign_key: { to_table: :orgs }
      t.references :receiver_org, null: false, foreign_key: { to_table: :orgs }
      t.string :external_invoice_number, null: false
      t.date :invoice_date
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # A closed load belongs to at most one batch (C4). Enforced by the unique
    # invoice_batch_id on loads; the column lives here to keep loads ordered first.
    add_reference :loads, :invoice_batch, foreign_key: true
  end
end
