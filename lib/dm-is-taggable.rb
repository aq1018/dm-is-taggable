# Needed to import datamapper and other gems
require 'rubygems'
require 'pathname'

# Add all external dependencies for the plugin here
gem 'dm-core', '>=0.9.6'
gem 'dm-aggregates', '>=0.9.6'
require 'dm-core'
require 'dm-aggregates'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'tag_list.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'aggregate_patch.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'is' / 'shared.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'is' / 'taggable.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'is' / 'tag.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'is' / 'tagging.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'is' / 'tagger.rb'

# Include the plugin in Resource
module DataMapper
  module Resource
    module ClassMethods
      include DataMapper::Is::Taggable
    end # module ClassMethods
  end # module Resource
end # module DataMapper

# Require the Tag and Tagging Resources
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'tag.rb'
require Pathname(__FILE__).dirname.expand_path / 'dm-is-taggable' / 'tagging.rb'
