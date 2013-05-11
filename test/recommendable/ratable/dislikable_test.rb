require "test_helper"

class DislikableTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    @friend = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_disliked_by_returns_relevant_users
    assert_empty @movie.disliked_by
    @user.dislike(@movie)
    assert_includes @movie.disliked_by, @user
    refute_includes @movie.disliked_by, @friend
    @friend.dislike(@movie)
    assert_includes @movie.disliked_by, @friend
  end

  def test_disliked_by_count_returns_an_accurate_count
    assert_empty @movie.disliked_by
    @user.dislike(@movie)
    assert_equal @movie.disliked_by_count, 1
    @friend.dislike(@movie)
    assert_equal @movie.disliked_by_count, 2
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
