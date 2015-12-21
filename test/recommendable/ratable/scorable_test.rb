$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class ScorableTest < Minitest::Test
  def setup
    @user = Factory(:user)
    @friend = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_scored_by_returns_relevant_users
    assert_empty @movie.scored_by
    @user.score(@movie, 1)
    assert_includes @movie.scored_by, @user
    refute_includes @movie.scored_by, @friend
    @friend.score(@movie, 1)
    assert_includes @movie.scored_by, @friend
  end

  def test_scored_by_count_returns_an_accurate_count
    assert_empty @movie.scored_by
    @user.score(@movie, 1)
    assert_equal @movie.scored_by_count, 1
    @friend.score(@movie, 1)
    assert_equal @movie.scored_by_count, 2
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
