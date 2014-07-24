require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "share strategy" do
    s = strategies(:one)
    u = users(:one)
    other = users(:two)

    u.strategies << s

    u.reload
    s.reload

    assert s.user

    u.share_strategy(other, s.id)

    other.reload
    assert_equal other.shared_strategies.length, 1
  end
end
