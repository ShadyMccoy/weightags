# Demo data: a grower↔buyer relationship with tags across the status spectrum.
# Idempotent-ish — safe to run on an empty database. Password for both: "password".
return if Rails.env.production?

ActiveRecord::Base.transaction do
  grower = Org.find_or_create_by!(name: "Sycamore Ridge Farms")
  buyer  = Org.find_or_create_by!(name: "Pacific Hulling Co")

  rachel = User.find_or_create_by!(email_address: "rachel@sycamore.test") do |u|
    u.name = "Rachel Green"; u.password = "password"
  end
  jessica = User.find_or_create_by!(email_address: "jessica@pacific.test") do |u|
    u.name = "Jessica Miller"; u.password = "password"
  end
  Membership.find_or_create_by!(user: rachel, org: grower) { |m| m.role = :admin }
  Membership.find_or_create_by!(user: jessica, org: buyer) { |m| m.role = :admin }
  Partnership.ensure!(org: grower, counterparty: buyer)

  post = ->(org, counterparty, side, actor, attrs) {
    Weighs::Poster.call(org: org, counterparty: counterparty, side: side, actor: actor, attributes: attrs)
  }

  unless Tag.exists?(bol: "WT-2026-0527-001")
    # 1) Clean match (within tolerance) -> matched
    post.(grower, buyer, :sender, rachel, { bol: "WT-2026-0527-001", commodity: "Almonds", truck: "T-118",
      driver: "Carlos M.", ship_date: Date.new(2026, 5, 27), gross: 52_000, tare: 14_000, moisture: 6.2,
      weighed_by: "Rachel Green", scale_id: "SR-SCALE-1", weighed_at: Time.zone.parse("2026-05-27 09:14") })
    post.(buyer, grower, :receiver, jessica, { bol: "WT-2026-0527-001", gross: 51_970, tare: 14_000, moisture: 6.3,
      weighed_by: "Jessica Miller", scale_id: "PH-SCALE-A", weighed_at: Time.zone.parse("2026-05-27 11:02") })

    # 2) Exceeds tolerance -> review
    post.(grower, buyer, :sender, rachel, { bol: "WT-2026-0527-002", commodity: "Soybeans", truck: "T-204",
      driver: "Dana L.", ship_date: Date.new(2026, 5, 27), gross: 61_500, tare: 15_200,
      weighed_by: "Rachel Green", scale_id: "SR-SCALE-1", weighed_at: Time.zone.parse("2026-05-27 10:20") })
    post.(buyer, grower, :receiver, jessica, { bol: "WT-2026-0527-002", gross: 61_150, tare: 15_200,
      notes: "Some spillage observed during unload.", weighed_by: "Jessica Miller", scale_id: "PH-SCALE-A",
      weighed_at: Time.zone.parse("2026-05-27 12:40") })

    # 3) One-sided -> pending (awaiting receiver)
    post.(grower, buyer, :sender, rachel, { bol: "WT-2026-0527-003", commodity: "Walnuts", truck: "T-077",
      driver: "Priya S.", ship_date: Date.new(2026, 5, 27), gross: 48_300, tare: 13_900,
      weighed_by: "Rachel Green", scale_id: "SR-SCALE-2", weighed_at: Time.zone.parse("2026-05-27 14:05") })

    # 4) Disputed
    d = post.(grower, buyer, :sender, rachel, { bol: "WT-2026-0527-004", commodity: "Milo", truck: "T-301",
      driver: "Owen K.", ship_date: Date.new(2026, 5, 27), gross: 59_800, tare: 14_600,
      notes: "Scale certified 05/15/2026.", weighed_by: "Rachel Green", scale_id: "SR-SCALE-1",
      weighed_at: Time.zone.parse("2026-05-27 08:30") }).tag
    post.(buyer, grower, :receiver, jessica, { bol: "WT-2026-0527-004", gross: 58_650, tare: 14_600,
      notes: "Scale recalibrated this morning — readings verified.", weighed_by: "Jessica Miller",
      scale_id: "PH-SCALE-B", weighed_at: Time.zone.parse("2026-05-27 13:15") })
    Tags::Actions.new(tag: d.reload, actor: rachel, actor_org: grower)
      .dispute!(reason: "Weight variance", notes: "Sender disputes receiver measurement — requesting third-party verification.")
  end

  puts "Seeded: #{Org.count} orgs, #{User.count} users, #{Tag.count} tags, #{Weigh.count} weighs, #{AuditEvent.count} audit events."
  puts "Sign in as rachel@sycamore.test or jessica@pacific.test (password: password)."
end
