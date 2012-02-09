require 'spec_helper'

class UserBenchmarkSpec < MiniTest::Unit::TestCase
  def test_update_recommendations
    if ENV["BENCH"] then
      Recommendable.redis.flushdb
      @actions = [:like, :dislike]

      puts "\n"
      
      assert_performance_exponential do |n|
        @user = Factory(:user)
        @users = []
        @movies = []

        # Make n users, 5n movies
        n.times do
          @users << Factory(:user)
          @movies << Factory(:movie)
          @movies << Factory(:movie)
          @movies << Factory(:movie)
          @movies << Factory(:movie)
          @movies << Factory(:movie)
        end
  
        # Main user randomly likes/dislikes 1/4 of the movies
        @movies.sample(n/4).each do |m|
          @user.send(@actions.sample, m)
        end
  
        # Other users randomly like/dislike some movies
        @movies.sample(n/2).each do |m|
          @users.sample.send(@actions.sample, m)
          @users.sample.send(@actions.sample, m)
          @users.sample.send(@actions.sample, m)
        end
  
        @user.send :update_similarities
        @user.send :update_recommendations
        Recommendable.redis.flushdb

        User.delete_all
        Movie.delete_all
        Recommendable::Like.delete_all
        Recommendable::Dislike.delete_all
      end
    end
  end
end
