require 'spec_helper'

class UserSpec < MiniTest::Spec
  describe User do
    describe "that does not act_as_recommendable" do
      before :each do
        @user = Bully.create(:username => "somejerk")
        @movie = Movie.create(:title => "2001: A Space Odyssey", :year => 1968)
      end
      
      it "should not be able to rate or ignore an item, and trying should not be enough to get Redis keys" do
        proc { @user.like(@movie) }.must_raise    NoMethodError
        proc { @user.dislike(@movie) }.must_raise NoMethodError
        proc { @user.ignore(@movie) }.must_raise  NoMethodError
        
        @movie.liked_by.must_be_empty
        @movie.disliked_by.must_be_empty
        
        proc { @user.create_recommended_to_sets }.must_raise NoMethodError
      
        proc { @user.likes_set_for(Movie) }.must_raise NoMethodError
        proc { @user.dislikes_set_for(Movie) }.must_raise NoMethodError
        
        Recommendable.redis.smembers("Bully:#{@user.id}:likes:Movie").must_be_empty
        Recommendable.redis.smembers("Bully:#{@user.id}:dislikes:Movie").must_be_empty
        Recommendable.redis.smembers("Bully:#{@user.id}:similarities").must_be_empty
        Recommendable.redis.smembers("Bully:#{@user.id}:predictions:Movie").must_be_empty
      end
    end
    
    describe "that does act_as_recommendable" do
      before :each do
        @user = User.create(:username => "dave")
        @movie = Movie.create(:title => "2001: A Space Odyssey", :year => 1968)
      end
      
      it "should be able to rate or ignore an item. doing so should allow the creation of Redis keys" do
        
        @user.ignore(@movie).must_equal true
        
        @user.dislike(@movie).must_equal true
        @movie.disliked_by.must_include @user
        @user.send(:create_recommended_to_sets)
        Recommendable.redis.smembers("User:#{@user.id}:dislikes:Movie").must_include @movie.id.to_s
        Recommendable.redis.smembers("User:#{@user.id}:likes:Movie").wont_include @movie.id.to_s
        @user.send(:destroy_recommended_to_sets)
        
        @user.like(@movie).must_equal true
        @movie.liked_by.must_include @user
        @user.send(:create_recommended_to_sets)
        Recommendable.redis.smembers("User:#{@user.id}:likes:Movie").must_include @movie.id.to_s
        Recommendable.redis.smembers("User:#{@user.id}:dislikes:Movie").wont_include @movie.id.to_s
        @user.send(:destroy_recommended_to_sets)
      end
      
      it "should not be able to rate or ignore an item that is not recommendable. doing so should not be enough to create Redis keys" do
        @cakephp = PhpFramework.create(:name => "CakePHP")
        
        proc { @user.like(@cakephp) }.must_raise    Recommendable::RecordNotRecommendableError
        proc { @user.dislike(@cakephp) }.must_raise Recommendable::RecordNotRecommendableError
        proc { @user.ignore(@cakephp) }.must_raise  Recommendable::RecordNotRecommendableError
        
        proc { @cakephp.liked_by }.must_raise    NoMethodError
        proc { @cakephp.disliked_by }.must_raise NoMethodError
        
        @user.send(:create_recommended_to_sets)
      
        Recommendable.redis.smembers("User:#{@user.id}:likes:PhpFramework").must_be_empty
        Recommendable.redis.smembers("User:#{@user.id}:dislikes:PhpFramework").must_be_empty
        Recommendable.redis.smembers("User:#{@user.id}:similarities").must_be_empty
        Recommendable.redis.smembers("User:#{@user.id}:predictions:Movie").must_be_empty
        
        @user.send(:destroy_recommended_to_sets)
      end
      
      it "should not freak out when unrating items or trying to rate them in the same way again" do
        @user.like(@movie).must_equal         true
        @user.likes?(@movie).must_equal       true
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal false
        @user.like(@movie).must_be_nil
        @user.unlike(@movie).must_equal       true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal false
        @user.unlike(@movie).must_be_nil
        
        
        @user.dislike(@movie).must_equal      true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    true
        @user.has_ignored?(@movie).must_equal false
        @user.dislike(@movie).must_be_nil
        @user.undislike(@movie).must_equal    true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal false
        @user.undislike(@movie).must_be_nil
        
        @user.ignore(@movie).must_equal       true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal true
        @user.ignore(@movie).must_be_nil
        @user.unignore(@movie).must_equal     true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal false
        @user.unignore(@movie).must_be_nil
      end
      
      it "should not freak out when re-rating items without unrating them" do
        @user.like(@movie).must_equal         true
        @user.likes?(@movie).must_equal       true
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal false
        @user.dislike(@movie).must_equal      true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    true
        @user.has_ignored?(@movie).must_equal false
        @user.ignore(@movie).must_equal       true
        @user.likes?(@movie).must_equal       false
        @user.dislikes?(@movie).must_equal    false
        @user.has_ignored?(@movie).must_equal true
      end
    end
    
    describe "while getting recommendations" do
      before :each do
        @dave   =  User.create(:username => "dave")
        @frank  =  User.create(:username => "frank")
        @hal    =  User.create(:username => "hal9000")
        @movie1 = Movie.create(:title => "2001: A Space Odyssey", :year => 1986)
        @movie2 = Movie.create(:title => "A Clockwork Orange", :year => 1979)
        @movie3 = Movie.create(:title => "One Flew Over the Cuckoo's Nest", :year => 1975)
        @movie4 = Movie.create(:title => "The Shining", :year => 1989)
        @movie5 = Movie.create(:title => "Lolita", :year => 1962)
      end
      
      after :each do
        Recommendable.redis.del "User:#{@dave.id}:similarities"
        Recommendable.redis.del "User:#{@dave.id}:predictions:Movie"
        Recommendable.redis.del "User:#{@frank.id}:similarities"
        Recommendable.redis.del "User:#{@frank.id}:predictions:Movie"
      end
      
      it "should get populated sorted sets for similarities and recommendations" do
        @dave.like(@movie1)
        @frank.like(@movie1)
        @frank.like(@movie2)
        @dave.update_similarities
        @dave.update_recommendations
        
        @dave.similar_raters.must_include @frank
        @dave.recommendations_for(Movie).must_include @movie2
      end
      
      it "should order similar users by similarity" do
        @dave.like(@movie1)
        @dave.like(@movie2)
        @frank.like(@movie1)
        @frank.dislike(@movie2)
        @hal.like(@movie1)
        @hal.like(@movie2)
        
        # hal should be more similar to dave than frank
        @dave.update_similarities
        @dave.update_recommendations
        
        @dave.similar_raters.must_equal [@hal, @frank]
      end
      
      it "should correctly recommend an awesome movie or two. In the correct order, of course." do
        @dave.like(@movie1)
        @dave.like(@movie2)
        @frank.like(@movie1)
        @frank.like(@movie2)
        @frank.like(@movie4)
        @hal.like(@movie1)
        @hal.like(@movie3)
        
        @dave.update_similarities
        @dave.update_recommendations
        
        @dave.recommendations.must_equal [@movie4, @movie3]
      end
    end
  end
end