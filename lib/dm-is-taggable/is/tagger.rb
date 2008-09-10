module DataMapper
  module Is
    module Taggable
      
      def is_tagger(options=nil)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggerClassMethods
        include DataMapper::Is::Taggable::TaggerInstanceMethods
      end
      
      module TaggerClassMethods 
        def all_similar_by_tags
        end
      end # ClassMethods

      module TaggerInstanceMethods
        def all_tagged_with
        end
        
        def tag_on(*params)
          # get the first paramater as the taggable object
          tagger = self
          taggable = params.delete_at(0)
          self.class.create_taggings(tagger, taggable, params)
        end
      end # InstanceMethods
    end
  end
end