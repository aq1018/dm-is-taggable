module DataMapper
  module Is
    module Taggable
      
      def is_tag(options=nil)
        extend  DataMapper::Is::Taggable::TagClassMethods
        include DataMapper::Is::Taggable::TagInstanceMethods
        property :id, DataMapper::Types::Serial
        property :name, String, :length => 255, :unique => true, :nullable => false
        has n, :taggings
      end
      
      module TagClassMethods
        def all_by
        end
        
        def fetch(name)
          first(:name => name) || create(:name => name)
        end
        
        def get(name)
          first(:name => name)
        end
      end # ClassMethods

      module TagInstanceMethods
        def related_tags
        end
        
        def popular_by_tags
        end
        
        def tagged_together_count
        end
        
        def tagged_count
        end
      end # InstanceMethods
    end
  end
end