class EnforceAuditEventsAppendOnly < ActiveRecord::Migration[8.1]
  # The audit log is the product's moat (charter: Audit defensibility). Its
  # append-only property must be guaranteed by the database itself, not by
  # application code that can drift. Any UPDATE or DELETE raises at the DB level.
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION weightags_audit_events_immutable()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_events is append-only: % is not permitted', TG_OP
          USING ERRCODE = 'restrict_violation';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER audit_events_block_update
        BEFORE UPDATE ON audit_events
        FOR EACH ROW EXECUTE FUNCTION weightags_audit_events_immutable();

      CREATE TRIGGER audit_events_block_delete
        BEFORE DELETE ON audit_events
        FOR EACH ROW EXECUTE FUNCTION weightags_audit_events_immutable();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS audit_events_block_update ON audit_events;
      DROP TRIGGER IF EXISTS audit_events_block_delete ON audit_events;
      DROP FUNCTION IF EXISTS weightags_audit_events_immutable();
    SQL
  end
end
