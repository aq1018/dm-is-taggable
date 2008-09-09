class Bot
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  is :tagger
end