require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

#DataObjects::Sqlite3.logger = DataObjects::Logger.new(STDOUT, 0)
DataMapper.auto_migrate!

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::Is::Taggable' do
    before(:all) do
      @user1 = User.create(:name => "user1")
      @user2 = User.create(:name => "user2")\
      
      @bot1 = Bot.create(:name => "bot1")
      @bot2 = Bot.create(:name => "bot2")
      
      @picture1 = Picture.create
      @picture1.tag(:by => @user1, :with => "tag1, tag2, tag3")
      @picture1.tag(:by => @user2, :with => "tag10, tag2, tag3")

      @picture2 = Picture.create
      @user2.tag(:on=>@picture2,  :with => ["tag1", "tag4", "tag5"])
      
      @picture1.tag(:by => @bot1, :with => ["tag1, tag3, tag_by_bot"])

      @article = Article.create
      @article.tag(:by =>@user1, :with => ["tag1", "tag4", "tag5"])
    end
    
    it "should be able to tag with taglist" do
      picture = Picture.new
      picture.taglist = "tag1, tag2, tag3"
      picture.save.should == true
      picture.tags.count.should == 3
      picture.taglist.should == "tag1, tag2, tag3"
      picture.destroy      
    end
    
    it "should be able to tag with taglist with user scope" do
      picture = Picture.new
      user = User.create(:name => "me")
      
      Tag.as(user) do
        picture.taglist = "tag1, tag2, tag3"
        picture.save.should == true
      end      
      picture.tags.count.should == 3
      Tag.by(user).on(picture).sort.should == [Tag.get("tag1"), Tag.get("tag2"), Tag.get("tag3")].sort
      picture.destroy
    end

    it "should be able to update tags with taglist" do
      picture = Picture.new
      picture.taglist = "tag1, tag2, tag3"
      picture.save
      
      picture.taglist = "tag1, tag3, tag4, tagme"  
      picture.tags.count.should == 4
      picture.taglist.should == "tag1, tag3, tag4, tagme"
      
      picture.destroy      
    end
    
    it "should setup to tagger_classes and taggable_classes accessors for taggables and taggers" do
      Picture.respond_to?(:tagger_classes).should be_true
      User.respond_to?(:taggable_classes).should be_true
    end

    it "should be able to tag by taggers" do
      picture = Picture.new
      user = User.new(:name => "me")
      user.save.should == true
      picture.save.should == true
      
      picture.tag(:by => user, :with =>["tagme", "tagtag", "tagtagtag"])
      user.tag(:on =>picture, :with => ["tag3", "tag4", "tag5"])
      
      picture.taggings.count.should == 6
      picture.tags.count.should == 6
      
      user.destroy
      picture.destroy
    end
    
    it "should be able to tag anonymously" do
      picture = Picture.new
      picture.save.should == true
      
      picture.tag(:with => ["tagme", "tagtag", "tagtagtag"])
      picture.tags.count.should == 3
      
      picture.tags.include?(Tag.get("tagme")).should be_true
      picture.tags.include?(Tag.get("tagtag")).should be_true
      picture.tags.include?(Tag.get("tagtagtag")).should be_true
      
      picture.taggings.each do |tag|
        tag.tagger_type.should be_nil
        tag.tagger_id.should be_nil
      end
      
      picture.destroy
    end
    
    it "should be able to retrieve Picture by with_any_tags" do
      Picture.find( :match => :any ,:with => ["tag2", "tag5"]).size.should == 2
      Picture.find( :match => :any ,:with => ["tag2", "tag5"]).include?(@picture1).should be_true
      Picture.find( :match => :any ,:with => ["tag2", "tag5"]).include?(@picture2).should be_true

      Picture.find( :match => :any ,:by => User, :with => ["tag2", "tag5"]).size.should == 2
      Picture.find( :match => :any ,:by => User, :with => ["tag2", "tag5"]).include?(@picture1).should be_true
      Picture.find( :match => :any ,:by => User, :with => [ "tag2", "tag5"]).include?(@picture2).should be_true
      
      Picture.find( :match => :any ,:by => Bot, :with => ["tag_by_bot", "tag5"]).size.should == 1
      Picture.find( :match => :any ,:by => Bot, :with => ["tag_by_bot", "tag5"]).include?(@picture1).should be_true
    end
    
    it "should be able to retrieve Picture by find" do
      Picture.find(:with =>"tag1").size.should == 2
      Picture.find(:with =>"tag1").include?(@picture1).should be_true
      Picture.find(:with =>"tag1").include?(@picture2).should be_true
      
      Picture.find(:by =>User, :with =>"tag1").size.should == 2
      Picture.find(:by =>User,:with => "tag1").include?(@picture1).should be_true
      Picture.find(:by =>User, :with =>"tag1").include?(@picture2).should be_true
      
      Picture.find(:by =>Bot,:with => "tag1").size.should == 1
      Picture.find(:by =>Bot, :with =>"tag1").include?(@picture1).should be_true

      Picture.find(:with =>"tag2").should == [@picture1]
      
      Picture.find(:with =>["tag1", "tag2"]).should == [@picture1]
      Picture.find(:with =>"non existing tag").should == []
    end
    
    
    it "should be able to retrieve all tags" do
      # ALL taggers
      all_tags = @picture1.tags
      all_tags.size.should == 5
      all_tags.include?(Tag.get("tag1")).should be_true
      all_tags.include?(Tag.get("tag2")).should be_true
      all_tags.include?(Tag.get("tag3")).should be_true
      all_tags.include?(Tag.get("tag_by_bot")).should be_true
      all_tags.include?(Tag.get("tag10")).should be_true
      # Users
      all_tags = @picture1.tags_by_users
      all_tags.size.should == 4
      all_tags.include?(Tag.get("tag1")).should be_true
      all_tags.include?(Tag.get("tag2")).should be_true
      all_tags.include?(Tag.get("tag3")).should be_true
      all_tags.include?(Tag.get("tag10")).should be_true
      
      # Bots
      all_tags = @picture1.tags_by_bots
      all_tags.size.should == 3
      all_tags.include?(Tag.get("tag1")).should be_true
      all_tags.include?(Tag.get("tag3")).should be_true
      all_tags.include?(Tag.get("tag_by_bot")).should be_true
     end
    
    it "should handle scoped tag creation" do
      picture = Picture.new
      user = User.new(:name => "me")
      user.save.should == true
      picture.save.should == true
  
      Tag.as(user) do
        picture.tag(:with => "scoped_tag")
      end
      Picture.find(:with => "scoped_tag").size.should == 1
      Picture.find("scoped_tag").include?(picture).should be_true
      
      user.destroy
      picture.destroy      
    end
    
    it "should handle scoped tag retrieval" do
      Tag.as(Bot) do
        Picture.find( :match => :any , :with => "tag_by_bot").size.should == 1
        Picture.find( :match => :any ,:with => "tag_by_bot").include?(@picture1).should be_true
      end

      Tag.as(User) do
        Picture.find( :match => :any , :with => "tag_by_bot").should be_empty
        Picture.find("tag1, tag2, tag3").size.should == 1
        Picture.find("tag1, tag2, tag3").include?(@picture1).should be_true
        
        Picture.find( :match => :any ,:with => "tag1").size.should == 2
        Picture.find("tag1").include?(@picture1).should be_true
        Picture.find("tag1").include?(@picture2).should be_true
      end
    end
    
    it "should be able to retrieve picture tags count" do
      # This requires a dm-aggration and the patch that enables unique count
      # Note: @picture1.tags_by_users.size also works, but less optimized. this uses COUNT in sql
      @picture1.count_tags_by_users.should == 4
      @picture1.count_tags_by_bots.should == 3
      @picture1.count_tags.should == 5
    end
    
     it "should be able to retrieve amount of times tag has been used" do
       # picture1 picture2 article1
       Tag.get("tag1").tagged_count.should == 3
       # picture1 picture2 article1
       Tag.get("tag1").tagged_count(:by => "User").should == 3
       # picture1
       Tag.get("tag1").tagged_count(:by => Bot).should == 1
       # article1 and picture1
       Tag.get("tag1").tagged_count(:by => @user1).should == 2
       
      Tag.get("tag1").tagged_count(:by =>@user1, :on => Picture) == 1
     end
     
     it "should be able to retrieve tags by the specified relation object" do
       Tag.by(@user1).sort.should == [Tag.get("tag1"), Tag.get("tag2"), Tag.get("tag3"), Tag.get("tag4"), Tag.get("tag5")].sort
       Tag.by(User).sort.should == [Tag.get("tag1"), Tag.get("tag2"), Tag.get("tag3"), Tag.get("tag4"), Tag.get("tag5"), Tag.get("tag10")].sort
       Tag.on(@article).sort.should == [Tag.get("tag1"), Tag.get("tag4"), Tag.get("tag5")].sort
       Tag.on(@picture1).by(@user2).sort.should == [Tag.get("tag2"), Tag.get("tag3"), Tag.get("tag10")].sort
     end
          
     it "should be able to retrieve specified tags by the specified relation object" do
       Picture.find(:with =>"tag1", :by => @user1).should == [@picture1]
       Picture.find(:with =>"tag2", :by => @user2).should == [@picture1]
       Picture.find(:with => ["tag1", "tag2"], :by => @bot1, :match => :any).should == [@picture1]
     end

    it "should be able to retrieve all tags by the user" do
       @user1.tags.size.should == 5
       @user1.tags.include?(Tag.get("tag1")).should be_true
       @user1.tags.include?(Tag.get("tag2")).should be_true
       @user1.tags.include?(Tag.get("tag3")).should be_true
       @user1.tags.include?(Tag.get("tag4")).should be_true
       @user1.tags.include?(Tag.get("tag5")).should be_true
     end

    it "should be able to retrieve all objects tagged by the user" do
       @user1.find_taggables(:with =>["tag1", "tag4"], :match => :any).should == [@article, @picture1]
       @user1.find_taggables(:with =>["tag1", "tag4"], :match => :all).should == [@article]
     end
          
     it "should be able to retrieve all objects tagged with certain tag" do
       Tag.find_taggables(:with => ["tag1", "tag4"]).should == [@article, @picture2]
       Tag.find_taggables(:with => ["tag1", "tag4"], :match => :any).should == [@article, @picture1, @picture2]
     end
     
     it "should be able to retrieve taggable_objects of user with specified tags" do
       @user2.find_taggables(:with => "tag1").should == [@picture2]
     end
     
     it "should be able to retrieve how many times the user used the tag" do
       Tag.tagged_count(:by => @user1, :on => @article, :with => "tag1").should == 1
       Tag.tagged_count(:by => Bot,  :with => "tag1").should == 1
       Tag.tagged_count(:by => @user1,  :with => "tag1").should == 2
       Tag.tagged_count(:by => @user1).should == 2
       Tag.tagged_count(:by => User).should == 3
       Tag.tagged_count.should == 3
     end
     
     it "should be able to retrieve the most association (in this case user) popular by tags for a certain tag" do
       # This returns a list of taggers with descending order of tag count
       Tag.get("tag1").popular_by_tags.should == [@user1, @user2, @bot1] # should return array and calculate this based upon the usage of the tag
     end
         
    it "should be able to retrieve related tags that where used in the same set" do
      related_tags = Tag.get("tag3").related
      related_tags.size.should == 2
      related_tags.include?([2,Tag.get("tag1")]).should be_true
      related_tags.include?([2,Tag.get("tag2")]).should be_true
      
      related_tags = Tag.get("tag1").related
      related_tags.size.should == 4
      related_tags.include?([2,Tag.get("tag2")]).should be_true
      related_tags.include?([3,Tag.get("tag3")]).should be_true
      related_tags.include?([2,Tag.get("tag4")]).should be_true
      related_tags.include?([2,Tag.get("tag5")]).should be_true
    end

    it "should be able to retrieve the times that tags where used in the same set" do
      # tag1 and tag3 are tagged together 2 times by user1 and bot1
      
      # I think you just want to find the counts on related tags...
      # So what I did was to include the number of counts on Tags#related
      related_tags = Tag.get("tag3").related
      related_tags.size.should == 2
      related_tags.include?([2,Tag.get("tag1")]).should be_true
      related_tags.include?([2,Tag.get("tag2")]).should be_true
    end

    it "should be able to total tags" do
      total = Picture.total(:limit => 10)
      total.should be_a(Array)
      total.should_not be_empty
      total.each do |item|
        item.should be_a(Array)
        item.size.should == 2
        item[0].should be_a(Tag)
        item[1].should be_a(Integer)
      end
    end
  end
end
