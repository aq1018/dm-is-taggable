class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  is :tagger
end