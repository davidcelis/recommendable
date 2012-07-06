require 'spec_helper'

class StashSpec < MiniTest::Spec
  describe Recommendable::Stash do
    before :each do
      @user = User.create(:username => "dave")
    end
    
    it "should not be created for an object that does not act_as_recommendedable" do
      web2py = PhpFramework.create(:name => "web2py")
      proc { @user.stash(web2py) }.must_raise Recommendable::UnrecommendableError
    end
    
    it "should be created for an object that does act_as_recommendable" do
     movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
     @user.stash(movie).must_equal true
    end
    
    it "should not be created twice for the same user-object pair" do
      movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
      
      @user.stash(movie).must_equal true
      @user.stash(movie).must_be_nil
      Recommendable::Stash.count.must_equal 1
    end
  end
end
