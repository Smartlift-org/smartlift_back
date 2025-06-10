require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "cant create without email" do
    user = User.new(
      first_name: "Pepe",
      last_name: "Perez",
      password: "123123"
    )
    assert_not user.save, "user saved without email"
  end
end
