require 'spec_helper'

class DislikeSpec < MiniTest::Spec
  describe Recommendable::Dislike do
    before :each do
      @user = User.create(:username => "dave")
    end
    
    it "should not be created for an object that does not act_as_recommendedable" do
      django = PhpFramework.create(:name => "django")
      proc { @user.dislike(django) }.must_raise Recommendable::UnrecommendableError
    end
    
    it "should be created for an object that does act_as_recommendable" do
     movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
     @user.dislike(movie).must_equal true
    end
    
    it "should not be created twice for the same user-object pair" do
      movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
      
      @user.dislike(movie).must_equal true
      @user.dislike(movie).must_be_nil
      Recommendable::Dislike.count.must_equal 1
    end

    it "should cache the number of dislikes" do
      movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
      @user2 = User.create(:username => "frank")

      @user.dislike(movie)
      movie.dislike_count.must_equal 1

      @user2.dislike(movie)
      movie.dislike_count.must_equal 2

      @user.undislike(movie)
      movie.dislike_count.must_equal 1
    end
  end
end
