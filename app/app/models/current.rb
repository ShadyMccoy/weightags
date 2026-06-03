class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :org
  delegate :user, to: :session, allow_nil: true
end
