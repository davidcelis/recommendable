$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class RatableTest < Minitest::Test
  def setup
    @movie = Factory(:movie)
    @book = Factory(:book)
    @rock = Factory(:rock)
    @vehicle = Factory(:vehicle)
  end

  def test_recommendable_predicate_works
    assert Movie.recommendable?
    assert @movie.recommendable?
    assert Documentary.recommendable?
    assert Factory(:documentary).recommendable?
    assert Book.recommendable?
    assert @book.recommendable?
    refute Rock.recommendable?
    refute @rock.recommendable?
    assert Car.recommendable?
    assert Factory(:car).recommendable?
    refute Vehicle.recommendable?
    refute @vehicle.recommendable?
    refute Boat.recommendable?
    refute Factory(:boat).recommendable?
  end

  def test_rated_predicate_works
    refute @movie.rated?
    user = Factory(:user)
    user.score(@movie, 1)
    assert @movie.rated?
  end

  def test_top_scope_deprecated_syntax_returns_best_things
    @book2 = Factory(:book)
    @book3 = Factory(:book)
    @user = Factory(:user)
    @friend = Factory(:user)

    @user.score(@book2, 1)
    @friend.score(@book2, 1)
    @user.score(@book3, 1)
    @user.score(@book, -1)

    top = Book.top(:count => 3)
    assert_equal top[0], @book2
    assert_equal top[1], @book3
    assert_equal top[2], @book
  end

  def test_top_scope_returns_best_things
    @book2 = Factory(:book)
    @book3 = Factory(:book)
    @user = Factory(:user)
    @friend = Factory(:user)

    @user.score(@book2, 1)
    @friend.score(@book2, 1)
    @user.score(@book3, 1)
    @user.score(@book, -1)

    top = Book.top(:count => 3)
    assert_equal top[0], @book2
    assert_equal top[1], @book3
    assert_equal top[2], @book
  end

  def test_top_scope_returns_best_things_for_ratable_base_class
    @movie2 = Factory(:movie)
    @doc = Factory(:documentary)
    @user = Factory(:user)
    @friend = Factory(:user)

    @user.score(@doc, 1)
    @friend.score(@doc, 1)
    @user.score(@movie2, 1)
    @user.score(@movie, -1)

    top = Movie.top(:count => 3)
    assert_equal top[0], @doc
    assert_equal top[1], @movie2
    assert_equal top[2], @movie
  end

  def test_top_scope_returns_best_things_with_start
    @movie2 = Factory(:movie)
    @doc = Factory(:documentary)
    @user = Factory(:user)
    @friend = Factory(:user)

    @user.score(@doc, 1)
    @friend.score(@doc, 1)
    @user.score(@movie2, 1)
    @user.score(@movie, -1)

    top = Movie.top(:count =>2, :offset => 1)
    assert_equal top[0], @movie2
    assert_equal top[1], @movie
  end

  def test_removed_from_recommendable_upon_destruction
    @user = Factory(:user)
    @friend = Factory(:user)
    @buddy = Factory(:user)
    @user.score(@movie, 1)
    @friend.score(@movie, -1)
    @user.score(@book, -1)
    @friend.score(@book, 1)
    @buddy.bookmark(@book)

    scoreed_by_sets = [@movie, @book].map { |obj| Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(obj.class, obj.id) }
    scoreed_by_sets.flatten.each { |set| assert_equal Recommendable.redis.scard(set), 2 }

    assert @user.scores?(@movie)
    assert @user.scores?(@book)
    assert @friend.scores?(@book)
    assert @friend.scores?(@movie)
    assert @buddy.bookmarks?(@book)

    @movie.destroy
    @book.destroy

    scoreed_by_sets.flatten.each { |set| assert_equal Recommendable.redis.scard(set), 0 }
    assert_empty @buddy.bookmarked_books
  end

  def test_ratable_subclass_object_removed_from_recommendable_upon_destruction
    @doc = Factory(:documentary)
    @user = Factory(:user)
    @friend = Factory(:user)
    @stranger = Factory(:user)

    @user.score(@doc, 1)
    @friend.score(@doc, -1)
    @stranger.bookmark(@doc)

    scored_by_set = Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(@doc.class, @doc.id)
    assert_equal Recommendable.redis.scard(scored_by_set), 2

    assert @user.scores?(@doc)
    assert @friend.scores?(@doc)

    @doc.destroy
    assert_equal Recommendable.redis.scard(scored_by_set), 0

    assert_empty @stranger.bookmarked_books
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
