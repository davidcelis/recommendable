require "test_helper"

class BookmarkerTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    @movie = Factory(:movie)
  end

  def test_that_bookmark_adds_to_bookmarked_set
    refute_includes @user.bookmarked_movie_ids, @movie.id
    @user.bookmark(@movie)
    assert_includes @user.bookmarked_movie_ids, @movie.id
  end

  def test_that_cant_bookmark_already_bookmarked_object
    assert @user.bookmark(@movie)
    assert_nil @user.bookmark(@movie)
  end

  def test_that_cant_bookmark_unratable_object
    basic_obj = Object.new
    rock = Factory(:rock)

    assert_raises(ArgumentError) { @user.bookmark(basic_obj) }
    assert_raises(ArgumentError) { @user.bookmark(rock) }
  end

  def test_that_bookmarks_returns_true_if_bookmarked
    refute @user.bookmarks?(@movie)
    @user.bookmark(@movie)
    assert @user.bookmarks?(@movie)
  end

  def test_that_unbookmark_removes_item_from_bookmarked_set
    @user.bookmark(@movie)
    assert_includes @user.bookmarked_movie_ids, @movie.id
    @user.unbookmark(@movie)
    refute_includes @user.bookmarked_movie_ids, @movie.id
  end

  def test_that_cant_unbookmark_item_unless_bookmarked
    assert_nil @user.unbookmark(@movie)
  end

  def test_that_bookmarks_returns_bookmarked_records
    refute_includes @user.bookmarks, @movie
    @user.bookmark(@movie)
    assert_includes @user.bookmarks, @movie
  end

  def test_that_dynamic_bookmarked_finder_only_returns_relevant_records
    book = Factory(:book)
    @user.bookmark(@movie)
    @user.bookmark(book)

    refute_includes @user.bookmarked_movies, book
    refute_includes @user.bookmarked_books, @movie
  end

  def test_that_bookmarks_count_counts_all_bookmarks
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.bookmark(@movie)
    @user.bookmark(movie2)
    @user.bookmark(book)

    assert_equal @user.bookmarks_count, 3
  end

  def test_that_dynamic_bookmarked_count_methods_only_count_relevant_bookmarks
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.bookmark(@movie)
    @user.bookmark(movie2)
    @user.bookmark(book)

    assert_equal @user.bookmarked_movies_count, 2
    assert_equal @user.bookmarked_books_count, 1
  end

  def test_that_bookmarks_in_common_with_returns_all_common_bookmarks
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)
    book2 = Factory(:book)

    @user.bookmark(@movie)
    @user.bookmark(book)
    @user.bookmark(movie2)
    friend.bookmark(@movie)
    friend.bookmark(book)
    friend.bookmark(book2)

    assert_includes @user.bookmarks_in_common_with(friend), @movie
    assert_includes @user.bookmarks_in_common_with(friend), book
    refute_includes @user.bookmarks_in_common_with(friend), movie2
    refute_includes friend.bookmarks_in_common_with(@user), book2
  end

  def test_that_dynamic_bookmarked_in_common_with_only_returns_relevant_records
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)

    @user.bookmark(@movie)
    @user.bookmark(book)
    friend.bookmark(@movie)
    friend.bookmark(book)

    assert_includes @user.bookmarked_movies_in_common_with(friend), @movie
    assert_includes @user.bookmarked_books_in_common_with(friend), book
    refute_includes @user.bookmarked_movies_in_common_with(friend), book
    refute_includes @user.bookmarked_books_in_common_with(friend), @movie
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
