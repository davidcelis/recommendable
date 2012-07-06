require 'spec_helper'

class IgnoreSpec < MiniTest::Spec
  describe Recommendable::Ignore do
    before :each do
      @user = User.create(:username => "dave")
    end
    
    it "should not be created for an object that does not act_as_recommendedable" do
      web2py = PhpFramework.create(:name => "web2py")
      proc { @user.ignore(web2py) }.must_raise Recommendable::UnrecommendableError
    end
    
    it "should be created for an object that does act_as_recommendable" do
     movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
     @user.ignore(movie).must_equal true
    end
    
    it "should not be created twice for the same user-object pair" do
      movie = Movie.create(:title => "Star Wars: Episode I - The Phantom Menace", :year => 1999)
      
      @user.ignore(movie).must_equal true
      @user.ignore(movie).must_be_nil
      Recommendable::Ignore.count.must_equal 1
    end
  end
end
