$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class DislikerTest < Minitest::Test
  def setup
    @user = Factory(:user)
    @movie = Factory(:movie)
    @doc = Factory(:documentary)
  end

  def test_that_dislike_adds_to_disliked_set
    refute_includes @user.disliked_movie_ids, @movie.id
    @user.dislike(@movie)
    assert_includes @user.disliked_movie_ids, @movie.id
  end

  def test_that_dislike_adds_subclass_dislikes_to_disliked_set
    refute_includes @user.disliked_movie_ids, @doc.id
    @user.dislike(@doc)
    assert_includes @user.disliked_movie_ids, @doc.id
  end

  def test_that_cant_dislike_already_disliked_object
    assert @user.dislike(@movie)
    assert_nil @user.dislike(@movie)
  end

  def test_that_cant_dislike_unratable_object
    basic_obj = Object.new
    rock = Factory(:rock)

    assert_raises(ArgumentError) { @user.dislike(basic_obj) }
    assert_raises(ArgumentError) { @user.dislike(rock) }
  end

  def test_that_dislikes_returns_true_if_disliked
    refute @user.dislikes?(@movie)
    @user.dislike(@movie)
    assert @user.dislikes?(@movie)
  end

  def test_that_undislike_removes_item_from_disliked_set
    @user.dislike(@movie)
    assert_includes @user.disliked_movie_ids, @movie.id
    @user.undislike(@movie)
    refute_includes @user.disliked_movie_ids, @movie.id
  end

  def test_that_undislike_removes_subclass_item_from_disliked_set
    @user.dislike(@doc)
    assert_includes @user.disliked_movie_ids, @doc.id
    @user.undislike(@doc)
    refute_includes @user.disliked_movie_ids, @doc.id
  end

  def test_that_cant_undislike_item_unless_disliked
    assert_nil @user.undislike(@movie)
  end

  def test_that_dislikes_returns_disliked_records
    refute_includes @user.dislikes, @movie
    @user.dislike(@movie)
    assert_includes @user.dislikes, @movie

    refute_includes @user.dislikes, @doc
    @user.dislike(@doc)
    assert_includes @user.dislikes, @doc
  end

  def test_that_dynamic_disliked_finder_only_returns_relevant_records
    book = Factory(:book)
    @user.dislike(@movie)
    @user.dislike(book)

    refute_includes @user.disliked_movies, book
    refute_includes @user.disliked_books, @movie
  end

  def test_that_dislikes_count_counts_all_dislikes
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.dislike(@movie)
    @user.dislike(movie2)
    @user.dislike(book)
    @user.dislike(@doc)

    assert_equal @user.dislikes_count, 4
  end

  def test_that_dynamic_disliked_count_methods_only_count_relevant_dislikes
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.dislike(@movie)
    @user.dislike(movie2)
    @user.dislike(@doc)
    @user.dislike(book)

    assert_equal @user.disliked_movies_count, 3
    assert_equal @user.disliked_books_count, 1
  end

  def test_that_dislikes_in_common_with_returns_all_common_dislikes
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)
    book2 = Factory(:book)

    @user.dislike(@movie)
    @user.dislike(book)
    @user.dislike(movie2)
    @user.dislike(@doc)
    friend.dislike(@movie)
    friend.dislike(book)
    friend.dislike(book2)
    friend.dislike(@doc)

    assert_includes @user.dislikes_in_common_with(friend), @movie
    assert_includes @user.dislikes_in_common_with(friend), @doc
    assert_includes @user.dislikes_in_common_with(friend), book
    refute_includes @user.dislikes_in_common_with(friend), movie2
    refute_includes friend.dislikes_in_common_with(@user), book2
  end

  def test_that_dynamic_disliked_in_common_with_only_returns_relevant_records
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)

    @user.dislike(@movie)
    @user.dislike(@doc)
    @user.dislike(book)
    friend.dislike(@movie)
    friend.dislike(@doc)
    friend.dislike(book)

    assert_includes @user.disliked_movies_in_common_with(friend), @movie
    assert_includes @user.disliked_movies_in_common_with(friend), @doc
    assert_includes @user.disliked_books_in_common_with(friend), book
    refute_includes @user.disliked_movies_in_common_with(friend), book
    refute_includes @user.disliked_books_in_common_with(friend), @movie
    refute_includes @user.disliked_books_in_common_with(friend), @doc
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
