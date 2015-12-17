$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class CalculationsTest < Minitest::Test
  def setup
    @user = Factory(:user)
    5.times  { |x| instance_variable_set(:"@user#{x+1}",  Factory(:user))  }
    5.times { |x| instance_variable_set(:"@movie#{x+1}", Factory(:movie)) }
    5.upto(9) { |x| instance_variable_set(:"@movie#{x+1}", Factory(:documentary)) }
    10.times { |x| instance_variable_set(:"@book#{x+1}",  Factory(:book))  }

    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user.score(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user.score(obj, -1) }

    # @user.similarity_with(@user1) should ==  1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user1.score(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user1.score(obj, -1) }

    # @user.similarity_with(@user2) should ==  0.25
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user2.score(obj) }
    [@book1, @book2, @book3].each { |obj| @user2.score(obj) }

    # @user.similarity_with(@user3) should ==  0.0
    [@movie1, @movie2, @movie3].each { |obj| @user3.score(obj) }
    [@book1, @book2, @book3].each { |obj| @user3.score(obj) }

    # @user.similarity_with(@user4) should == -0.25
    [@movie1, @movie2, @movie3].each { |obj| @user4.score(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user4.score(obj) }

    # @user.similarity_with(@user5) should == -1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user5.score(obj, -1) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user5.score(obj) }
  end

  def test_similarity_between_calculates_correctly
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user1.id), 1
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user2.id), 0.58
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user3.id), 0
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user4.id), -0.58
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user5.id), -1
  end

  def test_update_recommendations_ignores_rated_items
    Recommendable::Helpers::Calculations.update_similarities_for(@user.id)
    Recommendable::Helpers::Calculations.update_recommendations_for(@user.id)

    movies = @user.bookmarked_movies
    books  = @user.bookmarked_books

    movies.each { |m| refute_includes @user.recommended_movies, m }
    books.each  { |b| refute_includes @user.recommended_books,  b }
  end

  def test_predict_for_returns_predictions
    Recommendable::Helpers::Calculations.update_similarities_for(@user.id)
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book3.class, @book3.id), -0.33
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book4.class, @book4.id), 0.65
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book5.class, @book5.id), 0.65
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book6.class, @book6.id), 0.65
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie3.class, @movie3.id), 0.33
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie4.class, @movie4.id), -0.65
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie5.class, @movie5.id), -0.65
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie6.class, @movie6.id), -0.65
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
