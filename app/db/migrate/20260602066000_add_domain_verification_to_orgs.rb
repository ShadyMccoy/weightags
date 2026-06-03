class AddDomainVerificationToOrgs < ActiveRecord::Migration[8.1]
  def change
    # When the org proved control of its domain (D3) — enables same-domain
    # admin recovery, which closes the orphaned-org risk.
    add_column :orgs, :domain_verified_at, :datetime
  end
end
