class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  is :tagger, :on => ["Article", "Picture"]
end