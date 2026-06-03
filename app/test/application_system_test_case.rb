require "test_helper"
require "capybara/cuprite"

CHROME_BINARY = Dir["/opt/pw-browsers/chromium-*/chrome-linux/chrome"].first

Capybara.register_driver(:cuprite_chrome) do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [ 1400, 1400 ],
    browser_path: CHROME_BINARY,
    headless: true,
    process_timeout: 30,
    timeout: 20,
    browser_options: { "no-sandbox" => nil })
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite_chrome

  def login_as(user, password: "secret123")
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    assert_current_path tags_path
  end
end
