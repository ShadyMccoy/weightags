class CreateApiKeys < ActiveRecord::Migration[8.1]
  # Headless ingest credential (charter: "Ingest excellence ... production public
  # API (v2)"). An API key is org-owned and carries the user who minted it, so
  # actions taken over the API attribute to a real person in the append-only
  # audit log — same as the UI. Only the SHA-256 digest is stored; the plaintext
  # token is shown once at creation.
  def change
    create_table :api_keys do |t|
      t.references :org,  null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string   :name,         null: false
      t.string   :token_digest, null: false
      t.string   :token_last4,  null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :token_digest, unique: true

    # api_keys is looked up by digest before the request's org scope is known, so
    # it stays outside row-level security. Grant the non-superuser app role the
    # access it needs (the role is created by the RLS migration that runs first;
    # the GRANT in that migration only covered tables existing at the time).
    reversible do |dir|
      dir.up do
        execute <<~SQL
          DO $$ BEGIN
            IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'weightags_app') THEN
              GRANT SELECT, INSERT, UPDATE, DELETE ON public.api_keys TO weightags_app;
              GRANT USAGE, SELECT ON SEQUENCE public.api_keys_id_seq TO weightags_app;
            END IF;
          END $$;
        SQL
      end
    end
  end
end
