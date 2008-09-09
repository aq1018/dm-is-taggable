class Picture
  include DataMapper::Resource
  property :id, Serial
  is :taggable, :by => [User, Bot]
end