Please go to http://github.com/aq1018/dm-is-taggable/tree/master/README.textile for a pretty readme

h1. dm-is-taggable

dm-is-taggable is a tagging system built for datamapper. It has supports for multiple tagger types and taggable types.
Each tagger can tag different taggable objects.


h2. Installation

h3. Download the plugin

In your console:
<pre><code>
git clone git://github.com/aq1018/dm-is-taggable.git
</code></pre>

h3. Install the gem

In your console:
<pre><code>
cd dm-is-taggable
sudo rake install
</code></pre>

h3. Include it Merb

In merb init.rb:

<pre><code>
dependency "dm-is-taggable"
</code></pre>


h2. Using dm-is-taggable in your code

h3. Define taggers

<pre><code>
  class User
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    is :tagger, :on => ["Article", "Picture"]
  end

  class Bot
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    is :tagger, :on => ["Article", "Picture"]
  end
</code></pre>

h3. Define taggables

<pre><code>
  class Article
    include DataMapper::Resource
    property :id, Serial
    is :taggable, :by => ["User", "Bot"]
  end

  class Picture
    include DataMapper::Resource
    property :id, Serial
    is :taggable, :by => ["User", "Bot"]
  end
</code></pre>

h3. Create tags

<pre><code>
  
  @picture = Picture.first
  @scott = User.first
  
  # You can tag like this
  @picture.tag(:with => "shanghai, bar, beer", :by => @scott)
  
  # or like this
  # Note: this doesn't remove the previous tags
  Tag.as(@scott) do
    @picture.tag(:with => "cool, tag1, tag2")
  end
  
  # or like this
  # Note, this removes all previous tags
  Tag.as(@scott) do
    @picture.taglist("cool, tag1, tag2")
  end
</code></pre>

h3. Retrieve objects with tags

<pre><code>
  
  # find pictures tagged with tag1 and tag2
  Picture.find(:with => "tag1, tag2")
  
  # find pictures tagged with tag1 or tag2
  Picture.find(:with => "tag1, tag2", :match => :any)
  
  # find pictures tagged with tag1 or tag2, tagged by @user1
  Picture.find(:with => "tag1, tag2", :match => :any, :by => @user1)
  
  # find pictures tagged with tag1 or tag2, tagged by all users
  Picture.find(:with => "tag1, tag2", :match => :any, :by => User)
  
  # or you can do scoped way
  
  # find pictures tagged with tag1 or tag2, tagged by all users
  Tag.as(User) do
    Picture.find(:with => "tag1, tag2", :match => :any)
  end
  
  # find pictures tagged with tag1 or tag2, tagged by @user1
  Tag.as(@user1) do
    Picture.find(:with => "tag1, tag2", :match => :any)
  end
  
    
  # You can tag like this
  @picture.tag(:with => "shanghai, bar, beer", :by => @scott)
  
  # or like this
  # Note: this doesn't remove the previous tags
  Tag.as(@scott) do
    @picture.tag(:with => "cool, tag1, tag2")
  end
  
  # or like this
  # Note, this removes all previous tags
  Tag.as(@scott) do
    @picture.taglist("cool, tag1, tag2")
  end
</code></pre>

h3. Retrieve tags with objects

<pre><code>
  
  @picture1 = Picture.first
  
  # get all tags associated with @picture2 as a string
  @picture1.taglist
  
  # or as tag objects
  @picture1.tags
  
  # tags tagged by users
  @picture1.tags_by_users
  
  # find tags by all users
  Tag.by(User)

  # find tags by a user
  Tag.by(@user)

  # find tags on all pictures
  Tag.on(Picture)
  
  # find tags on a picture
  Tag.on(@picture1)
  
  # find tags by a user, on all pictures
  Tag.by(@user).on(Pictures)
  
  # find tags by all users on a picture
  Tag.by(User).on(@picture)
  
  # find tags by a user on a picture
  Tag.by(@user).on(@picture)
  
</code></pre>

h3. Counting tags

<pre><code>
  
  # Count how many articles are tagged by @user1
  Tag.tagged_count(:by => @user1, :on => Article)
  
  # Count how many articles are tagged by @user1 with "tag1"
  Tag.tagged_count(:by => @user1, :on => Article, :with => "tag1")
    
</code></pre>
