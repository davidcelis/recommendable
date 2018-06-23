$LOAD_PATH.unshift File.expand_path('../../test', __FILE__)
require 'test_helper'

class SimilarityCalculationTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    5.times  { |x| instance_variable_set(:"@user#{x+1}",  Factory(:user))  }
    5.times { |x| instance_variable_set(:"@movie#{x+1}", Factory(:movie)) }
    5.upto(9) { |x| instance_variable_set(:"@movie#{x+1}", Factory(:documentary)) }
    10.times { |x| instance_variable_set(:"@book#{x+1}",  Factory(:book))  }

    like(@user, [@movie1, @movie2, @movie3, @book4, @book5, @book6])
    dislike(@user, [@book1, @book2, @book3, @movie4, @movie5, @movie6])

    # @user.similarity_with(@user1) should ==  1.0
    like(@user1, [@movie1, @movie2, @movie3, @book4, @book5, @book6, @book7, @book8, @movie9, @movie10])
    dislike(@user1, [@book1, @book2, @book3, @movie4, @movie5, @movie6, @movie7, @movie8, @book9, @book10])

    # @user.similarity_with(@user2) should ==  0.25
    like(@user2, [@movie1, @movie2, @movie3, @book4, @book5, @book6])
    like(@user2, [@book1, @book2, @book3])

    # @user.similarity_with(@user3) should ==  0.0
    like(@user3, [@movie1, @movie2, @movie3])
    like(@user3, [@book1, @book2, @book3])

    # @user.similarity_with(@user4) should == -0.25
    like(@user4, [@movie1, @movie2, @movie3])
    like(@user4, [@book1, @book2, @book3, @movie4, @movie5, @movie6])

    # @user.similarity_with(@user5) should == -1.0
    dislike(@user5, [@movie1, @movie2, @movie3, @book4, @book5, @book6])
    like(@user5, [@book1, @book2, @book3, @movie4, @movie5, @movie6])
  end

  def test_similarity_between_calculates_correctly
    assert_equal similarity(@user.id, @user1.id), 1.0
    assert_equal similarity(@user.id, @user2.id), 0.25
    assert_equal similarity(@user.id, @user3.id), 0
    assert_equal similarity(@user.id, @user4.id), -0.25
    assert_equal similarity(@user.id, @user5.id), -1.0
  end

  def teardown
    Recommendable.redis.flushdb
  end

  def similarity(user_id, other_user_id)
    Recommendable::Helpers::Calculations::Similarity.new(user_id, other_user_id).calculate
  end

  def like(user, collection)
    collection.each { |obj| user.like(obj) }
  end

  def dislike(user, collection)
    collection.each { |obj| user.dislike(obj) }
  end
end
