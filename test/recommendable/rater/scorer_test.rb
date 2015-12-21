$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class ScorerTest < Minitest::Test
  def setup
    @user = Factory(:user)
    @movie = Factory(:movie)
    @doc = Factory(:documentary)
  end

  def test_that_like_adds_to_scored_set
    refute_includes @user.scored_movie_ids, @movie.id
    @user.score(@movie, 1)
    assert_includes @user.scored_movie_ids, @movie.id
  end

  def test_that_like_adds_subclass_scores_to_scored_set
    refute_includes @user.scored_movie_ids, @doc.id
    @user.score(@doc, 1)
    assert_includes @user.scored_movie_ids, @doc.id
  end

  def test_that_cant_like_already_scored_object
    assert @user.score(@movie, 1)
    assert_nil @user.score(@movie, 1)
  end

  def test_that_cant_like_unratable_object
    basic_obj = Object.new
    rock = Factory(:rock)

    assert_raises(ArgumentError) { @user.score(basic_obj) }
    assert_raises(ArgumentError) { @user.score(rock) }
  end

  def test_that_scores_returns_true_if_scored
    refute @user.scores?(@movie)
    @user.score(@movie, 1)
    assert @user.scores?(@movie)
  end

  def test_that_unlike_removes_item_from_scored_set
    @user.score(@movie, 1)
    assert_includes @user.scored_movie_ids, @movie.id
    @user.unscore(@movie)
    refute_includes @user.scored_movie_ids, @movie.id
  end

  def test_that_unlike_removes_subclass_item_from_scored_set
    @user.score(@doc, 1)
    assert_includes @user.scored_movie_ids, @doc.id
    @user.unscore(@doc)
    refute_includes @user.scored_movie_ids, @doc.id
  end

  def test_that_cant_unlike_item_unless_scored
    assert_nil @user.unscore(@movie)
  end

  def test_that_scores_returns_scored_records
    refute_includes @user.scores, @movie
    @user.score(@movie, 1)
    assert_includes @user.scores, @movie

    refute_includes @user.scores, @doc
    @user.score(@doc, 1)
    assert_includes @user.scores, @doc
  end

  def test_that_dynamic_scored_finder_only_returns_relevant_records
    book = Factory(:book)
    @user.score(@movie, 1)
    @user.score(book, 1)

    refute_includes @user.scored_movies, book
    refute_includes @user.scored_books, @movie
  end

  def test_that_scores_count_counts_all_scores
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.score(@movie, 1)
    @user.score(movie2, 1)
    @user.score(book, 1)
    @user.score(@doc, 1)

    assert_equal @user.scores_count, 4
  end

  def test_that_dynamic_scored_count_methods_only_count_relevant_scores
    book = Factory(:book)
    movie2 = Factory(:movie)

    @user.score(@movie, 1)
    @user.score(movie2, 1)
    @user.score(@doc, 1)
    @user.score(book, 1)

    assert_equal @user.scored_movies_count, 3
    assert_equal @user.scored_books_count, 1
  end

  def test_that_scores_in_common_with_returns_all_common_scores
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)
    book2 = Factory(:book)

    @user.score(@movie, 1)
    @user.score(book, 1)
    @user.score(movie2, 1)
    @user.score(@doc, 1)
    friend.score(@movie, 1)
    friend.score(book, 1)
    friend.score(book2, 1)
    friend.score(@doc, 1)

    assert_includes @user.scores_in_common_with(friend), @movie
    assert_includes @user.scores_in_common_with(friend), @doc
    assert_includes @user.scores_in_common_with(friend), book
    refute_includes @user.scores_in_common_with(friend), movie2
    refute_includes friend.scores_in_common_with(@user), book2
  end

  def test_that_dynamic_scored_in_common_with_only_returns_relevant_records
    friend = Factory(:user)
    movie2 = Factory(:movie)
    book = Factory(:book)

    @user.score(@movie, 1)
    @user.score(@doc, 1)
    @user.score(book, 1)
    friend.score(@movie, 1)
    friend.score(@doc, 1)
    friend.score(book, 1)

    assert_includes @user.scored_movies_in_common_with(friend), @movie
    assert_includes @user.scored_movies_in_common_with(friend), @doc
    assert_includes @user.scored_books_in_common_with(friend), book
    refute_includes @user.scored_movies_in_common_with(friend), book
    refute_includes @user.scored_books_in_common_with(friend), @movie
    refute_includes @user.scored_books_in_common_with(friend), @doc
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
