require "test_helper"

class RatableTest < MiniTest::Unit::TestCase
  def setup
    @movie = Factory(:movie)
    @book = Factory(:book)
    @rock = Factory(:rock)
  end

  def test_recommendable_predicate_works
    assert Movie.recommendable?
    assert @movie.recommendable?
    assert Book.recommendable?
    assert @book.recommendable?
    refute Rock.recommendable?
    refute @rock.recommendable?
  end

  def test_rated_predicate_works
    refute @movie.rated?
    user = Factory(:user)
    user.like(@movie)
    assert @movie.rated?
  end

  def test_top_scope_returns_best_things
    @book2 = Factory(:book)
    @book3 = Factory(:book)
    @user = Factory(:user)
    @friend = Factory(:user)

    @user.like(@book2)
    @friend.like(@book2)
    @user.like(@book3)
    @user.dislike(@book)

    top = Book.top(3)
    assert_equal top[0], @book2
    assert_equal top[1], @book3
    assert_equal top[2], @book
  end

  def test_removed_from_recommendable_upon_destruction
    @user = Factory(:user)
    @friend = Factory(:user)
    @buddy = Factory(:user)
    @user.like(@movie)
    @friend.dislike(@movie)
    @user.dislike(@book)
    @friend.like(@book)
    @buddy.hide(@movie)
    @buddy.bookmark(@book)

    liked_by_sets = [@movie, @book].map { |obj| Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(obj.class, obj.id) }
    disliked_by_sets = [@movie, @book].map { |obj| Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(obj.class, obj.id) }
    [liked_by_sets, disliked_by_sets].flatten.each { |set| assert_equal Recommendable.redis.scard(set), 1 }

    assert @user.likes?(@movie)
    assert @user.dislikes?(@book)
    assert @friend.likes?(@book)
    assert @friend.dislikes?(@movie)
    assert @buddy.hides?(@movie)
    assert @buddy.bookmarks?(@book)

    @movie.destroy
    @book.destroy

    [liked_by_sets, disliked_by_sets].flatten.each { |set| assert_equal Recommendable.redis.scard(set), 0 }

    assert_empty @buddy.hidden_movies
    assert_empty @buddy.bookmarked_books
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
