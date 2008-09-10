require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

require "dm-types"
require "dm-aggregates"

require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'tag'
require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'tagging'
require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'bot'
require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'user'
require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'picture'
require Pathname(__FILE__).dirname.expand_path.parent / 'data' / 'article'

DataMapper.auto_migrate!

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::Is::Taggable' do
    before(:all) do
      @user1 = User.create(:name => "user1")
      @user2 = User.create(:name => "user2")
      
      @bot1 = Bot.create(:name => "bot1")
      @bot2 = Bot.create(:name => "bot2")
      
      @picture1 = Picture.create
      @picture1.tag_with(@user1, "tag1, tag2, tag3")

      @picture2 = Picture.create
      @user2.tag_with(@picture2, "tag1", "tag4", "tag5")
      
      @picture1.tag_with(@bot1, "tag1, tag3, tag_by_bot")

      @article = Article.create
      @article.tag_with(@user1, "tag1", "tag4", "tag5")
    end
    
    it "should setup to tagger_classes and taggable_classes accessors for taggables and taggers" do
      Picture.respond_to?(:tagger_classes).should be_true
      User.respond_to?(:taggable_classes).should be_true
    end

    it "should be able to tag" do
      picture = Picture.new
      user = User.new(:name => "me")
      user.save.should == true
      picture.save.should == true
      
      picture.tag_with(user, "tagme", "tagtag", "tagtagtag")
      user.tag_with(picture, "tag3", "tag4", "tag5")
      
      user.destroy
      picture.destroy
    end
    
    it "should handle scoped tag creation" do
      picture = Picture.new
      user = User.new(:name => "me")
      user.save.should == true
      picture.save.should == true
  
      Tag.as(user) do
        picture.tag_with("scoped_tag")
      end
      Picture.with_all_tags("scoped_tag").size.should == 1
      Picture.with_all_tags("scoped_tag").include?(picture).should be_true
      
      user.destroy
      picture.destroy      
    end
    
   it "should be able to retrieve all tags" do
      all_tags = @picture1.picture_user_tags 
      all_tags.size.should == 3
      all_tags.include?(Tag.get("tag1")).should be_true
      all_tags.include?(Tag.get("tag2")).should be_true
      all_tags.include?(Tag.get("tag3")).should be_true
      
      all_tags = @picture1.picture_bot_tags
      all_tags.size.should == 3
      all_tags.include?(Tag.get("tag1")).should be_true
      all_tags.include?(Tag.get("tag3")).should be_true
      all_tags.include?(Tag.get("tag_by_bot")).should be_true
    end

    
    it "should be able to retrieve Pciture by with_all_tags" do
      Picture.with_all_tags("tag1").size.should == 2
      Picture.with_all_tags("tag1").include?(@picture1).should be_true
      Picture.with_all_tags("tag1").include?(@picture2).should be_true
      
      Picture.with_all_tags(User, "tag1").size.should == 2
      Picture.with_all_tags(User, "tag1").include?(@picture1).should be_true
      Picture.with_all_tags(User, "tag1").include?(@picture2).should be_true

      Picture.with_all_tags(Bot, "tag1").size.should == 1
      Picture.with_all_tags(Bot, "tag1").include?(@picture1).should be_true
      
      Picture.with_all_tags("tag2").should == [@picture1]
      
      Picture.with_all_tags("tag1", "tag2").should == [@picture1]
      Picture.with_all_tags("non existing tag").should == []
    end
    
    it "should be able to retrieve Pciture by with_any_tags" do
      Picture.with_any_tags("tag2", "tag5").size.should == 2
      Picture.with_any_tags("tag2", "tag5").include?(@picture1).should be_true
      Picture.with_any_tags("tag2", "tag5").include?(@picture2).should be_true
      
      Picture.with_any_tags(User, "tag2", "tag5").size.should == 2
      Picture.with_any_tags(User, "tag2", "tag5").include?(@picture1).should be_true
      Picture.with_any_tags(User, "tag2", "tag5").include?(@picture2).should be_true
      
      Picture.with_any_tags(Bot, "tag_by_bot", "tag5").size.should == 1
      Picture.with_any_tags(Bot, "tag_by_bot", "tag5").include?(@picture1).should be_true
    end
    
    it "should handle scoped tag retrieval" do
      Tag.as(Bot) do
        Picture.with_any_tags("tag_by_bot").size.should == 1
        Picture.with_any_tags("tag_by_bot").include?(@picture1).should be_true
      end

      Tag.as(User) do
        Picture.with_any_tags("tag_by_bot").should be_empty
        
        puts "=====================#{Picture.with_all_tags("tag1, tag2, tag3").inspect}"
        Picture.with_all_tags("tag1, tag2, tag3").size.should == 1
        Picture.with_all_tags("tag1, tag2, tag3").include?(@picture1).should be_true
        
        Picture.with_any_tags("tag1").size.should == 2
        Picture.with_all_tags("tag1").include?(@picture1).should be_true
        Picture.with_all_tags("tag1").include?(@picture2).should be_true
      end
      
    end
    

    
    it "should be able to retrieve picture tags count" do
      #this requires a dm-aggration
      @picture1.picture_user_tags.count.should == 3
    end
    
    # it "should be able to retrieve amount of times tag has been used" do
    #   Tag.get("tag1").tagged_count.should == 2
    # end
    
    # it "should be able to retrieve related tags that where used in the same set" do
    #   related_tags = Tag.get("tag3").related_tags
    #   related_tags.size.should == 2
    #   related_tags.include?(Tag.get("tag1")).should be_true
    #   related_tags.include?(Tag.get("tag2")).should be_true
    #   
    #   related_tags = Tag.get("tag1").related_tags
    #   related_tags.size.should == 4
    #   related_tags.include?(Tag.get("tag2")).should be_true
    #   related_tags.include?(Tag.get("tag3")).should be_true
    #   related_tags.include?(Tag.get("tag4")).should be_true
    #   related_tags.include?(Tag.get("tag5")).should be_true
    # end
    # 
    # it "should be able to retrieve the times that tags where used in the same set" do
    #   pending
    #   # Not sure what this means...
    #   # Tag.get("tag3").related_tags.first.tagged_together_count = 1 # first would return tag1
    # end
    # 
    # it "should be able to retrieve the most association (in this case user) popular by tags for a certain tag" do
    #   pending
    #   # Need more details on the calculation
    #   # Tag.get("tag1").popular_by_tags.should == [@aaron] # should return array and calculate this based upon the usage of the tag
    # end
    # 
    # it "should be able to retrieve tags by the specified relation object" do
    #   Tag.all_by(@aaron).should == [Tag.get("tag1"), Tag.get("tag2"), Tag.get("tag3"), Tag.get("tag4"), Tag.get("tag5")]
    # end
    # 
    # it "should be able to retrieve specified tags by the specified relation object" do
    #   TaggableObject.with_all_tags_and_by("tag1", @aaron).should == [TaggableObject.get(1), TaggableObject.get(2)]
    #   TaggableObject.with_all_tags_and_by("tag2", @maxime).should == []
    #   TaggableObject.with_any_tags_and_by("tag1", "tag2", @maxime).should == []
    # end
    # 
    # it "should be able to retrieve taggable_objects of user with specified tags" do
    #   pending
    #   # shouldn't this one also include the SuperTaggableObject?
    #   # @aaron.taggable_objects.with_all_tags("tag1").should == [TaggableObject.get(1), TaggableObject.get(2)]
    # end
    # 
    # it "should be able to retrieve all tags by the user" do
    #   @aaron.tags.all.size.should == 5
    #   @aaron.tags.include?(Tag.get("tag1")).should be_true
    #   @aaron.tags.include?(Tag.get("tag2")).should be_true
    #   @aaron.tags.include?(Tag.get("tag3")).should be_true
    #   @aaron.tags.include?(Tag.get("tag4")).should be_true
    #   @aaron.tags.include?(Tag.get("tag5")).should be_true
    # end
    # 
    # it "should be able to retrieve how many times the user used the tag" do
    #   pending
    #   # shouldn't this return 3 (including the SuperTaggableObject)?
    #   # @aaron.tags.first.tagged_by_count.should == 2 # tags.first returns Tag.get("tag1")
    # end
    # 
    # it "should be able to retrieve all objects tagged with certain tag" do
    #   Tag.all_tagged_with("tag1", "tag4").should == [TaggableObject.get(2), SuperTaggableObject.get(1)]
    # end
    # 
    # it "should be able to retrieve all objects tagged by the user" do
    #   @aaron.all_tagged_with("tag1", "tag4").should == [TaggableObject.get(2), SuperTaggableObject.get(1)]
    # end
    # 
    # it "should be able to retrieve similar users with same kind of tagging behavior sorted on similarity" do
    #   User.all_similar_by_tags.should == [@maxime]
    # end

  end
end
