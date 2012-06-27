require 'spec_helper'

class MovieSpec < MiniTest::Spec
  describe Movie do
    describe "before_destroy filters" do
      before :each do
        Recommendable.redis.flushdb

        @user1 = Factory(:user)

        @movie1 = Factory(:movie)
        @movie2 = Factory(:movie)
      end

      it "should be removed from scores" do
        @user1.like @movie1
        @user1.like @movie2

        @movie2.destroy

        Movie.top(2).wont_include @movie2
      end

      it "should be removed from recommendations" do
        @user2 = Factory(:user)
        @user1.like @movie1
        @user2.like @movie1
        @user2.like @movie2

        @user1.send :update_recommendations
        @movie2.destroy

        @user2.liked.size.must_equal 1
        @user1.recommendations.size.must_equal 0
      end
    end

    describe ".top" do
      before :each do
        Recommendable.redis.flushdb

        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        @user4 = Factory(:user)
        @user5 = Factory(:user)

        @movie1 = Factory(:movie)
        @movie2 = Factory(:movie)
        @movie3 = Factory(:movie)
        @movie4 = Factory(:movie)
        @movie5 = Factory(:movie)
      end

      it "should sort movies accordingly" do
        movies = Movie.all

        movies.each { |m| @user1.like m }
        movies.pop
        movies.each { |m| @user2.like m }
        movies.pop
        movies.each { |m| @user3.like m }
        movies.pop
        movies.each { |m| @user4.dislike m }

        @user5.dislike @movie1
        @user5.dislike @movie2
        @user5.dislike @movie3
        @user5.like @movie4
        @user5.like @movie5

        top_movies = Movie.top(5)

        top_movies[0].must_equal @movie4
        top_movies[1].must_equal @movie5
        top_movies[2].must_equal @movie3
        top_movies[3].must_equal @movie2
        top_movies[4].must_equal @movie1
      end
    end    
  end
end
