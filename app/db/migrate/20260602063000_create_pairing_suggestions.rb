class CreatePairingSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :pairing_suggestions do |t|
      # The two one-sided tags a near-miss BOL match proposes joining (B2).
      t.references :sender_tag, null: false, foreign_key: { to_table: :tags }
      t.references :receiver_tag, null: false, foreign_key: { to_table: :tags }
      t.references :sender_org, null: false, foreign_key: { to_table: :orgs }
      t.references :receiver_org, null: false, foreign_key: { to_table: :orgs }

      t.string :bol_sender, null: false
      t.string :bol_receiver, null: false
      t.integer :distance, null: false, default: 0
      t.string :corroboration

      # Pairing requires BOTH parties to confirm; either may reject.
      t.integer :state, null: false, default: 0
      t.datetime :sender_confirmed_at
      t.datetime :receiver_confirmed_at

      t.timestamps
    end

    add_index :pairing_suggestions, [ :sender_tag_id, :receiver_tag_id ], unique: true,
      name: "index_pairing_suggestions_on_tag_pair"
    add_index :pairing_suggestions, :state
  end
end
