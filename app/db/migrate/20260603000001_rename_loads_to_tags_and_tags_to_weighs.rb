class RenameLoadsToTagsAndTagsToWeighs < ActiveRecord::Migration[8.1]
  # v12 ontology: the shipment (was Load) becomes the Tag; a weighing (was Tag)
  # becomes the Weigh. Swap the table names, re-point the FK, and move the RLS
  # policies onto the renamed tables. (Done in dependency-safe order; no existing
  # production data.)
  def up
    # 1. old `tags` (measurements) -> `weighs`; its load_id -> tag_id
    rename_table :tags, :weighs
    rename_column :weighs, :load_id, :tag_id

    # 2. old `loads` (shipments) -> `tags`
    rename_table :loads, :tags

    # 3. pairing suggestions now reference weighs
    rename_column :pairing_suggestions, :sender_tag_id, :sender_weigh_id
    rename_column :pairing_suggestions, :receiver_tag_id, :receiver_weigh_id

    # 4. RLS policies follow their tables but keep their old names — re-create them
    #    with names that match the renamed tables (predicates/columns unchanged).
    execute <<~SQL
      DROP POLICY IF EXISTS tags_org_isolation ON weighs;
      DROP POLICY IF EXISTS loads_org_isolation ON tags;

      CREATE POLICY weighs_org_isolation ON weighs
        USING (org_id = ANY(app_accessible_org_ids()) OR counterparty_org_id = ANY(app_accessible_org_ids()))
        WITH CHECK (org_id = ANY(app_accessible_org_ids()) OR counterparty_org_id = ANY(app_accessible_org_ids()));

      CREATE POLICY tags_org_isolation ON tags
        USING (sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids()))
        WITH CHECK (sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids()));
    SQL
  end

  def down
    execute <<~SQL
      DROP POLICY IF EXISTS weighs_org_isolation ON weighs;
      DROP POLICY IF EXISTS tags_org_isolation ON tags;
    SQL
    rename_column :pairing_suggestions, :receiver_weigh_id, :receiver_tag_id
    rename_column :pairing_suggestions, :sender_weigh_id, :sender_tag_id
    rename_table :tags, :loads
    rename_column :weighs, :tag_id, :load_id
    rename_table :weighs, :tags
    execute <<~SQL
      CREATE POLICY tags_org_isolation ON tags
        USING (org_id = ANY(app_accessible_org_ids()) OR counterparty_org_id = ANY(app_accessible_org_ids()))
        WITH CHECK (org_id = ANY(app_accessible_org_ids()) OR counterparty_org_id = ANY(app_accessible_org_ids()));
      CREATE POLICY loads_org_isolation ON loads
        USING (sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids()))
        WITH CHECK (sender_org_id = ANY(app_accessible_org_ids()) OR receiver_org_id = ANY(app_accessible_org_ids()));
    SQL
  end
end
