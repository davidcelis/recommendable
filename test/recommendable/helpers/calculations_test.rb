$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

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
    [@book1, @book2, @book3, @movie4, @movie5, @movie6, @movie8, @movie8, @book9, @book10].each { |obj| @user1.dislike(obj) }

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

  end

  def teardown
    Recommendable.redis.flushdb
  end
end
