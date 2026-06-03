class AddDomainVerificationTokenToOrgs < ActiveRecord::Migration[8.1]
  def change
    # Stable token placed in the DNS TXT record (and the email-confirmation link).
    # Stored, not a rotating signed token, so the published DNS value stays valid.
    add_column :orgs, :domain_verification_token, :string
    add_index :orgs, :domain_verification_token, unique: true
  end
end
