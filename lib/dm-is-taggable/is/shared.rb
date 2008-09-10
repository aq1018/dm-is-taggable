module DataMapper
  module Is
    module Taggable
      module SharedClassMethods
        def tagging_association_of(tagger_klass, taggable_klass)
          Extlib::Inflection.tableize(tagging_class_name_of(tagger_klass, taggable_klass))
        end
        
        def tag_association_of(tagger_klass, taggable_klass)
          tagging_association_of(tagger_klass, taggable_klass).gsub(/taggings$/, "tags")
        end
        
        def tagging_class_name_of(tagger_klass, taggable_klass)
          Extlib::Inflection.demodulize(taggable_klass.to_s) << Extlib::Inflection.demodulize(tagger_klass.to_s) << "Tagging"
        end

        def tagging_class_of(tagger_klass, taggable_klass)
          Extlib::Inflection.constantize(tagging_class_name_of(tagger_klass, taggable_klass))
        end
        
        def create_taggings(tagger, taggable, tags=nil)
          return if tags.nil? || tags.empty?

          unless tagger.respond_to?(:tagger?) && tagger.tagger? && !tagger.is_a?(Class)
            raise Exception.new("#{tagger} is not a tagger datamapper resource object!")
          end
          
          unless taggable.respond_to?(:taggable?) && taggable.taggable? && !taggable.is_a?(Class)
            raise Exception.new("#{taggable} is not a taggable datamapper resource object!")
          end
                    
          tags = TagList.from(tags)
          
          # TODO: add checks to see if tags can be added
          #raise Exception("Cannot Tag #{taggable.class}!") if !taggable.is_a?(Article) && !taggable.is_a?(Picture)
          tagger_klass = tagger.class
          taggable_klass = taggable.class
          tagging_klass = tagging_class_of(tagger_klass, taggable_klass)
          tags.each do |tag|
            tag_obj = Tag.fetch(tag)
            tagging = tagging_klass.new(:tag => tag_obj)
            
            [tagger, taggable].each{|obj| obj.tagging_association_of(tagger_klass, taggable_klass) << tagging}
            success = tagging.save
          end # end of each
        end
      end
      
      module SharedInstanceMethods
        def tagging_association_of(tagger_klass, taggable_klass)
          self.send(self.class.tagging_association_of(tagger_klass, taggable_klass))
        end
        
        def tag_association_of(tagger_klass, taggable_klass)
          self.send(self.class.tag_association_of(tagger_klass, taggable_klass))
        end
      end
    end
  end
end