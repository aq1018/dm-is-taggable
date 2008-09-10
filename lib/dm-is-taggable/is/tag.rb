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
        attr_reader :tagger

        def as(tagger_or_tagger_class, &block)
          self.tagger = tagger_or_tagger_class
          raise Exception("A block must be provided!") unless block_given?
          yield
          self.tagger=nil
        end
        
        def all_by(tagger)
          
        end
        
        def fetch(name)
          first(:name => name) || create(:name => name)
        end
        
        def get(name)
          first(:name => name)
        end
        
        private        
        def tagger=(tagger)
          unless (tagger.respond_to?(:tagger?) && tagger.tagger?) || tagger.nil?
            raise Exception.new("#{tagger} is not a tagger datamapper resource object!")
          end
          @tagger = tagger
        end
      end # ClassMethods

      module TagInstanceMethods
        def related_tags(tag)
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