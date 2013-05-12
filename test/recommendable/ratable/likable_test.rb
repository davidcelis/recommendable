require "test_helper"

class LikableTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    @friend = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_liked_by_returns_relevant_users
    assert_empty @movie.liked_by
    @user.like(@movie)
    assert_includes @movie.liked_by, @user
    refute_includes @movie.liked_by, @friend
    @friend.like(@movie)
    assert_includes @movie.liked_by, @friend
  end

  def test_liked_by_count_returns_an_accurate_count
    assert_empty @movie.liked_by
    @user.like(@movie)
    assert_equal @movie.liked_by_count, 1
    @friend.like(@movie)
    assert_equal @movie.liked_by_count, 2
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
