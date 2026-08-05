# Pembantu untuk request spec: membuat akun tiap peran dan menaruh sesi login.
module AuthHelpers
  def create_user(role:, name: nil, email_address: nil)
    User.create!(
      name: name || role.to_s.titleize,
      email_address: email_address || "#{role}-#{SecureRandom.hex(4)}@uji.test",
      password: "sebuse2026",
      role: role
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "sebuse2026" }

    user
  end

  def sign_in_as(role)
    sign_in(create_user(role: role))
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
