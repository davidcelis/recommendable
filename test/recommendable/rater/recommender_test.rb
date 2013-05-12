require "test_helper"

class RecommenderTest < MiniTest::Unit::TestCase
  def setup
    @user = Factory(:user)
    5.times  { |x| instance_variable_set(:"@user#{x+1}",  Factory(:user))  }
    10.times { |x| instance_variable_set(:"@movie#{x+1}", Factory(:movie)) }
    10.times { |x| instance_variable_set(:"@book#{x+1}",  Factory(:book))  }

    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user.dislike(obj) }

    # @user.similarity_with(@user2) should ==  1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6, @book7, @book8, @movie9, @movie10].each { |obj| @user2.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6, @movie8, @movie8, @book9, @book10].each { |obj| @user2.dislike(obj) }

    # @user.similarity_with(@user4) should ==  0.25
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user4.like(obj) }
    [@book1, @book2, @book3].each { |obj| @user4.like(obj) }

    # @user.similarity_with(@user3) should ==  0.0
    [@movie1, @movie2, @movie3].each { |obj| @user3.like(obj) }
    [@book1, @book2, @book3].each { |obj| @user3.like(obj) }

    # @user.similarity_with(@user1) should == -0.25
    [@movie1, @movie2, @movie3].each { |obj| @user1.like(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user1.like(obj) }

    # @user.similarity_with(@user5) should == -1.0
    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each { |obj| @user5.dislike(obj) }
    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each { |obj| @user5.like(obj) }

    Recommendable::Helpers::Calculations.update_similarities_for(@user.id)
    Recommendable::Helpers::Calculations.update_recommendations_for(@user.id)
  end

  def test_similar_raters_returns_sorted_similar_users
    similar_raters = @user.similar_raters(5)

    assert_equal similar_raters[0], @user2
    assert_equal similar_raters[1], @user4
    assert_equal similar_raters[2], @user3
    assert_equal similar_raters[3], @user1
    assert_equal similar_raters[4], @user5
  end

  def test_recommended_for_only_returns_relevant_recommendations
    [@book7, @book8, @book9, @book10].each  { |book|  refute_includes @user.recommended_movies, book }
    [@movie7, @movie8, @movie9, @movie10].each { |movie| refute_includes @user.recommended_books, movie }
  end

  def test_unrecommend_removes_items_from_recommendations

  end

  def test_that_it_is_removed_from_recommendable_after_destroy
    Recommendable::Helpers::Calculations.update_similarities_for(@user2.id)

    @user.hide(@movie10)
    @user.hide(@book10)
    @user.bookmark(@movie9)
    @user.bookmark(@book9)

    sets = [
      @user.liked_movie_ids,
      @user.disliked_movie_ids,
      @user.liked_book_ids,
      @user.disliked_book_ids,
      @user.hidden_movie_ids,
      @user.hidden_book_ids,
      @user.bookmarked_movie_ids,
      @user.bookmarked_book_ids,
      @user.recommended_movies,
      @user.recommended_books,
      @user.similar_raters
    ]

    sets.each { |set| refute_empty set }
    assert_includes @user2.similar_raters(5), @user

    redis_sets = [
      Recommendable::Helpers::RedisKeyMapper.liked_set_for(Movie, @user.id),
      Recommendable::Helpers::RedisKeyMapper.liked_set_for(Book, @user.id),
      Recommendable::Helpers::RedisKeyMapper.disliked_set_for(Movie, @user.id),
      Recommendable::Helpers::RedisKeyMapper.disliked_set_for(Book, @user.id),
      Recommendable::Helpers::RedisKeyMapper.hidden_set_for(Movie, @user.id),
      Recommendable::Helpers::RedisKeyMapper.hidden_set_for(Book, @user.id),
      Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(Movie, @user.id),
      Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(Book, @user.id),
    ]

    redis_zsets = [
      Recommendable::Helpers::RedisKeyMapper.recommended_set_for(Movie, @user.id),
      Recommendable::Helpers::RedisKeyMapper.recommended_set_for(Book, @user.id),
      Recommendable::Helpers::RedisKeyMapper.similarity_set_for(@user.id)
    ]

    id = @user.id
    @user.destroy

    redis_sets.each  { |set|  assert_equal Recommendable.redis.scard(set),  0 }
    redis_zsets.each { |zset| assert_equal Recommendable.redis.zcard(zset), 0 }

    [@movie1, @movie2, @movie3, @book4, @book5, @book6].each do |obj|
      refute_includes obj.liked_by_ids, id.to_s
    end

    [@book1, @book2, @book3, @movie4, @movie5, @movie6].each do |obj|
      refute_includes obj.disliked_by_ids, id.to_s
    end

    refute_includes @user2.similar_raters(5).map(&:id), id
  end

  def teardown
    Recommendable.redis.flushdb
  end
end
