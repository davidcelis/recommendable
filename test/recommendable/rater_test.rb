require "test_helper"

class RaterTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
  end

  def test_that_it_belongs_to_recommendables_user_class
    assert_instance_of Recommendable.config.user_class, @user
  end

  def test_that_its_class_responds_to_recommendable_hooks
    %w[like dislike hide bookmark].each do |action|
      assert_respond_to @user.class, "before_#{action}"
      assert_respond_to @user.class, "before_un#{action}"
      assert_respond_to @user.class, "after_#{action}"
      assert_respond_to @user.class, "after_un#{action}"
    end
  end

  def test_that_rated_anything_is_false_by_default
    refute @user.rated_anything?
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
