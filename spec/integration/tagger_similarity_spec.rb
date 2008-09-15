require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::Is::Taggable' do
    before(:all) do
      DataMapper.auto_migrate!
      @user1 = User.create(:name => "user1")
      @user2 = User.create(:name => "user2")
      @user3 = User.create(:name => "user3")
      @user4 = User.create(:name => "user4")
      
      @picture1 = Picture.create
      @picture1.tag(:by => @user1, :with => "tag1, tag2, tag3, tag4")
      @picture1.tag(:by => @user2, :with => "tag1, tag2, tag3")
      @picture1.tag(:by => @user4, :with => "weird")
      
      @picture2 = Picture.create
      @user2.tag(:on=>@picture2,  :with => ["tag1", "tag2", "tag4", "tag5", "tag6", "tag7", "tag8"])      
      @user3.tag(:on => @picture2, :with => ["tag4", "tag5", "tag6", "tag7", "tag8"])
    end

    it "should be able to retrieve similar users with same kind of tagging behavior sorted on similarity" do
      # user1 and user2 are sharing tag1, tag2, tag3 and tag4 (4 tags total)
      # user1 and user3 are sharing tag4 (1 tag total)
      @user1.all_similar_by_tags.should == [[4, @user2], [1, @user3]]
      
      # user2 and user3 are sharing tag4, tag5, tag6, tag7 and tag8 (5 tags total)
      # user2 and user1 are sharing tag1, tag2, tag3 and tag4 (4 tags total)
      @user2.all_similar_by_tags.should == [[5, @user3], [4, @user1]]

      # user3 and user2 are sharing tag4, tag5, tag6, tag7 and tag8 (5 tags total)
      # user3 and user1 are sharing tag4 (1 tag total)
      @user3.all_similar_by_tags.should == [[5, @user2], [1, @user1]]
      
      # check if user4 is alone in the dark
      @user4.all_similar_by_tags.should be_empty
    end
  end
end