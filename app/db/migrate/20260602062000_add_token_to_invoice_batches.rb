class AddTokenToInvoiceBatches < ActiveRecord::Migration[8.1]
  def change
    # Public, unguessable handle for the indexable verification page (C4 /
    # product-led distribution — the audit-log moat doing acquisition for free).
    add_column :invoice_batches, :token, :string
    add_index :invoice_batches, :token, unique: true
  end
end
