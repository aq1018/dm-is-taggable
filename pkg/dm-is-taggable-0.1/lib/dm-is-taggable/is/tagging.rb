module DataMapper
  module Is
    module Taggable
      
      def is_tagging(options=nil)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggingClassMethods
        include DataMapper::Is::Taggable::TaggingInstanceMethods

        property :id, DataMapper::Types::Serial
        property :tag_id, Integer,        :index => :true,      :nullable => false

        property :tagger_id, Integer,     :index => :tagger,    :nullable => true
        property :tagger_type, String,    :index => :tagger,    :nullable => true,  :size => 255

        property :taggable_id, Integer,   :index => :taggable,  :nullable => false
        property :taggable_type, String,  :index => :taggable,  :nullable => false, :size => 255
        
        belongs_to :tag
      end
      
      module TaggingClassMethods
      end

      module TaggingInstanceMethods
      end
    end
  end
end
