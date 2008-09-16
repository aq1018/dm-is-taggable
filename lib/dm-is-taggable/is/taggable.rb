module DataMapper
  module Is
    module Taggable

      def is_taggable(options)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggableClassMethods
        include DataMapper::Is::Taggable::TaggableInstanceMethods
        
        @tagger_classes = options[:by]
        Tag.instance_variable_set('@tagger_classes', (Tag.instance_variable_get('@tagger_classes') | @tagger_classes))
        
        has n, :taggings, :class_name => "Tagging", :child_key => [:taggable_id], :taggable_type => self.to_s
        # real ugly syntax... wait until dm make better conditional has n :through association better, than update code
        has n,  :tags, :through => :taggings, :class_name => "Tag", 
                    :child_key => [:taggable_id], 
                    Tagging.properties[:taggable_type] => self.to_s, 
                    :unique => true
        
        tagger_classes.each do |class_name|
          has n, "taggings_by_#{class_name.snake_case.plural}".intern, 
                  :class_name => "Tagging", :child_key => [:taggable_id], 
                  :taggable_type => self.to_s, :tagger_type => class_name
                  
          has n, "tags_by_#{class_name.snake_case.plural}".intern, :through => :taggings, 
                  :class_name => "Tag", :child_key => [:taggable_id], 
                  Tagging.properties[:taggable_type] => self.to_s,
                  Tagging.properties[:tagger_type] => class_name,
                  :remote_name => "tag"
                
          class_eval <<-TAGS
            def count_tags_by_#{class_name.snake_case.plural}(conditions={})
              conditions = {:unique => true}.merge(conditions)
              tags_by_#{class_name.snake_case.plural}.count(:id, conditions)
            end
          TAGS
        end
        
        after :save, :tag_now_with_taglist
        before :destroy, :destroy_all_taggings
      end
      
      module TaggableClassMethods
        def tagger_classes
          @tagger_classes.map{|klass| klass.to_s.singular.camel_case}
        end
        
        def tagger?;false;end
        def taggable?;true;end
        def taggable_class;self;end
        
        def find(options)
           tagger, taggable, tags, options = extract_options(options)
           options.merge!(:on => self, :by =>tagger, :with => tags)
          Tag.find_taggables(options)
        end
      end # ClassMethods

      module TaggableInstanceMethods
        def tagger?;false;end
        def taggable?;true;end
        def taggable_class;self.class;end
        def taggable;self;end
        
        def taglist
          @taglist || TagList.new(self.tags.collect{|t| t.name}).to_s
        end
        
        def taglist=(ataglist)
          # if the object is a new record, we will tag the object after save
          # if the object isn't a new record, we tag the object now
          @taglist = ataglist
          tag_now_with_taglist unless new_record?
          true
        end
        
        def can_tag_by?(tagger)
          if tagger.is_a?(Class)
            return self.class.tagger_classes.include?(tagger)
          end
          return self.class.tagger_classes.include?(tagger.class)
        end
        
        def tag(options)
          tagger, taggable, tags = extract_options(options)
          taggable = self
          # TODO: verify tagger and taggable
          self.class.create_taggings(tagger, taggable, tags)
        end
        
        def count_tags(conditions={})
          conditions = {:unique => true}.merge(conditions)
          tags.count(:id, conditions)
        end
        
        protected
        def tag_now_with_taglist
          return unless @taglist 
          # Destroy all the taggings
          destroy_all_taggings unless self.new_record?

          # Tag with the tag list
          self.tag(:with => TagList.from(@taglist))
          @taglist = nil   
        end

        def destroy_all_taggings
          self.taggings.destroy!
        end
      end # InstanceMethods
    end # Taggable
  end # Is
end # DataMapper
