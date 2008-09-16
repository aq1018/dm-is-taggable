module DataMapper
  module Is
    module Taggable
      module SharedClassMethods
        
        def extract_class_object(obj)
          return [] if obj.nil?
          if obj.is_a?(Class)
            [obj, nil]            
          else
            [obj.class, obj]
          end
        end
        
        def by(tagger_class_or_obj)
          tagger_class, tagger_obj = extract_tagger_class_object(tagger_class_or_obj)
          query = {:unique => true}
          query.merge!(Tag.taggings.tagger_type => tagger_class.to_s) if tagger_class
          query.merge!(Tag.taggings.tagger_id => tagger_obj.id) if tagger_obj
          all(query)
        end

        def on(taggable_class_or_obj)
          taggable_class, taggable_obj = extract_taggable_class_object(taggable_class_or_obj)
          query = {:unique => true}
          query.merge!(Tag.taggings.taggable_type => taggable_class.to_s) if taggable_class
          query.merge!(Tag.taggings.taggable_id => taggable_obj.id) if taggable_obj
          all(query)
        end
        
       def extract_options(options)
         if options.is_a?(Array) || options.is_a?(String)
           options = {:with => TagList.from(options)}
         end
         options = options.dup
         
         tagger = options.delete(:by)
         tagger ||= Tag.tagger
         taggable = options.delete(:on)
         tags = TagList.from(options.delete(:with))
         return [tagger, taggable, tags, options]
       end
        
       def extract_tagger_class_object(obj)
         obj = Extlib::Inflection.constantize(obj.to_s.camel_case.singular) if  obj && (obj.is_a?(String) || obj.is_a?(Symbol))
         return [] if obj.nil?
         
         if obj.tagger?
           extract_class_object(obj)
         else
            raise Exception.new("#{obj} is not a Tagger class or object!")
         end
       end
        
       def extract_taggable_class_object(obj)
         obj = Extlib::Inflection.constantize(obj.to_s.camel_case.singular) if  obj && (obj.is_a?(String) || obj.is_a?(Symbol))
         return [] if obj.nil?
         
         if obj.taggable?
           extract_class_object(obj)
         else
           raise Exception.new("#{obj} is not a Taggable class or object!")
         end
       end
                
        def create_taggings(tagger, taggable, tags=nil)
          return if tags.nil? || tags.empty?
          
          unless tagger.nil? || (tagger.respond_to?(:tagger?) && tagger.tagger? && !tagger.is_a?(Class))
            raise Exception.new("#{tagger} is not a tagger datamapper resource object!")
          end
          
          unless taggable.respond_to?(:taggable?) && taggable.taggable? && !taggable.is_a?(Class)
            raise Exception.new("#{taggable} is not a taggable datamapper resource object!")
          end
          
          raise Exception.new("#{tagger.class} cannot Tag #{taggable.class}") unless tagger.nil? || tagger.can_tag_on?(taggable)
                          
          TagList.from(tags).each do |tag|
            tag_obj = Tag.fetch(tag)
            
            # build tagging (tagger could be anonymous)
            tagging_hash = {:tag_id => tag_obj.id, :taggable_id => taggable.id, :taggable_type => taggable.class.to_s}
            tagging_hash.merge!(:tagger_id => tagger.id, :tagger_type => tagger.class.to_s) if tagger

            # see if we already have this tagging
            tagging_obj = Tagging.first(tagging_hash)
            
            # if we have the tagging already, just skip this one...
            next if tagging_obj
            
            # tagging is not in db, let's create one            
            Tagging.create(tagging_hash)
          end # end of each
        end
      end
      
      module SharedInstanceMethods
        def  extract_tagger_class_object(tagger_class_or_object)
          self.class.extract_tagger_class_object(tagger_class_or_object)
        end
        def  extract_taggable_class_object(taggable_class_or_object)
          self.class.extract_taggable_class_object(taggable_class_or_object)
        end
        def extract_options(options)
          self.class.extract_options(options)
        end
      end
    end
  end
end