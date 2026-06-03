class EnableRowLevelSecurity < ActiveRecord::Migration[8.1]
  # Defense-in-depth tenancy (charter: "Postgres row-level security is the default
  # safety net underneath" app-level scoping). Org-owned data is visible only to
  # the orgs in app.accessible_org_ids — the set the app sets per request. The
  # app should connect as the non-superuser weightags_app role in production so
  # these policies bind (superusers bypass RLS by design).
  RLS_TABLES = %w[tags loads invoice_batches].freeze

  def up
    execute <<~SQL
      DO $$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'weightags_app') THEN
          CREATE ROLE weightags_app NOLOGIN NOSUPERUSER;
        END IF;
      END $$;

      GRANT USAGE ON SCHEMA public TO weightags_app;
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO weightags_app;
      GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO weightags_app;

      -- The set of org ids the current request is allowed to see (CSV GUC).
      CREATE OR REPLACE FUNCTION app_accessible_org_ids() RETURNS bigint[] AS $fn$
        SELECT COALESCE(
          string_to_array(NULLIF(current_setting('app.accessible_org_ids', true), ''), ',')::bigint[],
          ARRAY[]::bigint[]
        );
      $fn$ LANGUAGE sql STABLE;

      GRANT EXECUTE ON FUNCTION app_accessible_org_ids() TO weightags_app;
    SQL

    policy("tags", "org_id = ANY(app_accessible_org_ids()) OR counterparty_org_id = ANY(app_accessible_org_ids())")
    policy("loads", "sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids())")
    policy("invoice_batches", "sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids())")
  end

  def down
    RLS_TABLES.each do |table|
      execute <<~SQL
        DROP POLICY IF EXISTS #{table}_org_isolation ON #{table};
        ALTER TABLE #{table} NO FORCE ROW LEVEL SECURITY;
        ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY;
      SQL
    end
    execute "DROP FUNCTION IF EXISTS app_accessible_org_ids();"
  end

  private

  def policy(table, predicate)
    execute <<~SQL
      ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY;
      ALTER TABLE #{table} FORCE ROW LEVEL SECURITY;
      DROP POLICY IF EXISTS #{table}_org_isolation ON #{table};
      CREATE POLICY #{table}_org_isolation ON #{table}
        USING (#{predicate})
        WITH CHECK (#{predicate});
    SQL
  end
end
