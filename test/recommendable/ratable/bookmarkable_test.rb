$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class BookmarkableTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    @friend = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_bookmarked_by_returns_relevant_users
    assert_empty @movie.bookmarked_by
    @user.bookmark(@movie)
    assert_includes @movie.bookmarked_by, @user
    refute_includes @movie.bookmarked_by, @friend
    @friend.bookmark(@movie)
    assert_includes @movie.bookmarked_by, @friend
  end

  def test_bookmarked_by_count_returns_an_accurate_count
    assert_empty @movie.bookmarked_by
    @user.bookmark(@movie)
    assert_equal @movie.bookmarked_by_count, 1
    @friend.bookmark(@movie)
    assert_equal @movie.bookmarked_by_count, 2
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
