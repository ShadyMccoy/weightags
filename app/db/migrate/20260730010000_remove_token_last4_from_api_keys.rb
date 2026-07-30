class RemoveTokenLast4FromApiKeys < ActiveRecord::Migration[8.1]
  # The digest is the only thing worth keeping. token_last4 was never read — the
  # dashboard identifies a credential by its non-secret public_id — so it was
  # plaintext fragments of a secret stored for nothing. Dropping it makes "a
  # database dump exposes no usable credential material" true by construction.
  #
  # Also flips the scope default to the weaker credential. A row that arrives
  # without an explicit scope is one where nobody decided, and the safe reading of
  # "nobody decided" is read-only. Existing keys keep the scope they were minted
  # with; only the default for new rows moves.
  def up
    remove_column :api_keys, :token_last4
    change_column_default :api_keys, :scope, from: "read_write", to: "read_only"
  end

  def down
    change_column_default :api_keys, :scope, from: "read_only", to: "read_write"
    add_column :api_keys, :token_last4, :string
    execute "UPDATE api_keys SET token_last4 = '' WHERE token_last4 IS NULL"
    change_column_null :api_keys, :token_last4, false
  end
end
