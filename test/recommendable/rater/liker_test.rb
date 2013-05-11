require "test_helper"

class LikerTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_that_like_adds_to_liked_set
    refute_includes @user.liked_movie_ids, @movie.id
    @user.like(@movie)
    assert_includes @user.liked_movie_ids, @movie.id
  end

  def test_that_cant_like_already_liked_object
    assert @user.like(@movie)
    assert_nil @user.like(@movie)
  end

  def test_that_cant_like_unratable_object
    basic_obj = Object.new
    rock = Factory(:rock)

    assert_raises(ArgumentError) { @user.like(basic_obj) }
    assert_raises(ArgumentError) { @user.like(rock) }
  end

  def test_that_likes_returns_true_if_liked
    refute @user.likes?(@movie)
    @user.like(@movie)
    assert @user.likes?(@movie)
  end

  def test_that_unlike_removes_item_from_liked_set
    @user.like(@movie)
    assert_includes @user.liked_movie_ids, @movie.id
    @user.unlike(@movie)
    refute_includes @user.liked_movie_ids, @movie.id
  end

  def test_that_cant_unlike_item_unless_liked
    assert_nil @user.unlike(@movie)
  end

  def test_that_likes_returns_liked_records
    refute_includes @user.likes, @movie
    @user.like(@movie)
    assert_includes @user.likes, @movie
  end

  def test_that_dynamic_liked_finder_only_returns_relevant_records
    book = Factory(:book)
    @user.like(@movie)
    @user.like(book)

    refute_includes @user.liked_movies, book
    refute_includes @user.liked_books, @movie
  end

  def test_that_likes_count_counts_all_likes
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.like(@movie)
    @user.like(movie2)
    @user.like(book)

    assert_equal @user.likes_count, 3
  end

  def test_that_dynamic_liked_count_methods_only_count_relevant_likes
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.like(@movie)
    @user.like(movie2)
    @user.like(book)

    assert_equal @user.liked_movies_count, 2
    assert_equal @user.liked_books_count, 1
  end

  def test_that_likes_in_common_with_returns_all_common_likes
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)
    book2 = Factory(:book)

    @user.like(@movie)
    @user.like(book)
    @user.like(movie2)
    friend.like(@movie)
    friend.like(book)
    friend.like(book2)

    assert_includes @user.likes_in_common_with(friend), @movie
    assert_includes @user.likes_in_common_with(friend), book
    refute_includes @user.likes_in_common_with(friend), movie2
    refute_includes friend.likes_in_common_with(@user), book2
  end

  def test_that_dynamic_liked_in_common_with_only_returns_relevant_records
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)

    @user.like(@movie)
    @user.like(book)
    friend.like(@movie)
    friend.like(book)

    assert_includes @user.liked_movies_in_common_with(friend), @movie
    assert_includes @user.liked_books_in_common_with(friend), book
    refute_includes @user.liked_movies_in_common_with(friend), book
    refute_includes @user.liked_books_in_common_with(friend), @movie
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
