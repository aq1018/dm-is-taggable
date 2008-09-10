module DataMapper
  module Is
    module Taggable
      
      def is_tagging(options=nil)
        extend  DataMapper::Is::Taggable::TaggingClassMethods
        include DataMapper::Is::Taggable::TaggingInstanceMethods
        is :remixable
        property :id, DataMapper::Types::Serial
        property :tag_id, Integer
      end
      
      module TaggingClassMethods
      end

      module TaggingInstanceMethods
      end
    end
  end
end
