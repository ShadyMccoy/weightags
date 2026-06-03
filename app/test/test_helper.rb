ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    Relationship = Struct.new(:grower, :buyer, :grower_user, :buyer_user, keyword_init: true)

    def build_relationship
      grower = Org.create!(name: "Sycamore Ridge Farms")
      buyer  = Org.create!(name: "Pacific Hulling Co")
      gu = User.create!(name: "Rachel Green", email_address: "rachel-#{SecureRandom.hex(4)}@ex.test", password: "secret123")
      bu = User.create!(name: "Jessica Miller", email_address: "jess-#{SecureRandom.hex(4)}@ex.test", password: "secret123")
      Membership.create!(user: gu, org: grower, role: :admin)
      Membership.create!(user: bu, org: buyer, role: :admin)
      Partnership.ensure!(org: grower, counterparty: buyer)
      Relationship.new(grower: grower, buyer: buyer, grower_user: gu, buyer_user: bu)
    end

    def post_tag(org:, counterparty:, side:, actor:, **attrs)
      Weighs::Poster.call(org: org, counterparty: counterparty, side: side, actor: actor, attributes: attrs)
    end
  end
end
