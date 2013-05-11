require "test_helper"

class CalculationsTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    5.times  { |x| instance_variable_set(:"@user#{x+1}",  Factory(:user))  }
    10.times { |x| instance_variable_set(:"@movie#{x+1}", Factory(:movie)) }
    10.times { |x| instance_variable_set(:"@book#{x+1}",  Factory(:book))  }

    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user.dislike(obj) }

    # @user.similarity_with(@user1) should ==  1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6, @book7, @book8, @movie9, @movie10].each { |obj| @user1.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6, @movie7, @movie8, @book9, @book10].each { |obj| @user1.dislike(obj) }

    # @user.similarity_with(@user2) should ==  0.25
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user2.like(obj) }
    [@book1, @book2, @book3].each { |obj| @user2.like(obj) }

    # @user.similarity_with(@user3) should ==  0.0
    [@movie1, @movie2, @movie3].each { |obj| @user3.like(obj) }
    [@book1, @book2, @book3].each { |obj| @user3.like(obj) }

    # @user.similarity_with(@user4) should == -0.25
    [@movie1, @movie2, @movie3].each { |obj| @user4.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user4.like(obj) }

    # @user.similarity_with(@user5) should == -1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user5.dislike(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user5.like(obj) }
  end

  def test_similarity_between_calculates_correctly
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user1.id), 1.0
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user2.id), 0.25
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user3.id), 0
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user4.id), -0.25
    assert_equal Recommendable::Helpers::Calculations.similarity_between(@user.id, @user5.id), -1.0
  end

  def test_update_recommendations_ignores_rated_items
    Recommendable::Helpers::Calculations.update_similarities_for(@user.id)
    Recommendable::Helpers::Calculations.update_recommendations_for(@user.id)

    movies = @user.liked_movies + @user.disliked_movies
    books  = @user.liked_books  + @user.disliked_books

    movies.each { |m| refute_includes @user.recommended_movies, m }
    books.each  { |b| refute_includes @user.recommended_books,  b }
  end

  def test_predict_for_returns_predictions
    Recommendable::Helpers::Calculations.update_similarities_for(@user.id)
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book7.class, @book7.id), 1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book8.class, @book8.id), 1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book9.class, @book9.id), -1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @book10.class, @book10.id), -1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie7.class, @movie7.id), -1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie8.class, @movie8.id), -1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie9.class, @movie9.id), 1.0
    assert_equal Recommendable::Helpers::Calculations.predict_for(@user.id, @movie10.class, @movie10.id), 1.0
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
