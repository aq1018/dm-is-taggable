module DataMapper
  module Is
    module Taggable

      def is_taggable(options)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggableClassMethods
        include DataMapper::Is::Taggable::TaggableInstanceMethods
        
        @tagger_classes = options[:by]
        has n, :taggings, :class_name => "Tagging", :child_key => [:taggable_id], :taggable_type => self.to_s
        # real ugly syntax... wait until dm make better conditional has n :through association better, than update code
        has n, :tags, :through => :taggings, :class_name => "Tag", :child_key => [:taggable_id], Tagging.properties[:taggable_type] => self.to_s, :unique => true
        
        tagger_classes.each do |class_name|
          has n, "taggings_by_#{class_name.snake_case.plural}".intern, 
                  :class_name => "Tagging", :child_key => [:taggable_id], 
                  :taggable_type => self.to_s, :tagger_type => class_name
                  
          has n, "tags_by_#{class_name.snake_case.plural}".intern, :through => :taggings, 
                  :class_name => "Tag", :child_key => [:taggable_id], 
                  Tagging.properties[:taggable_type] => self.to_s,
                  Tagging.properties[:tagger_type] => class_name,
                  :remote_name => "tag"
        end
        
        before :destroy, :destroy_all_taggings
      end
      
      module TaggableClassMethods
        def tagger_classes
          @tagger_classes.map{|klass| klass.to_s.singular.camel_case}
        end
        
        def tagger?;false;end
        def taggable?;true;end
        def taggable_class;self;end
        
        def with_all_tags_and_by(*params)
        end
        
        # Returns an array of related tags.
        # Related tags are all the other tags that are found on the models tagged with the provided tags.
        # 
        # Pass either a tag, string, or an array of strings or tags.
        # 
        # Options:
        #   :order - SQL Order how to order the tags. Defaults to "count DESC, tags.name".
        def find_related_tags(*params)
          default_options = {:conditions => ["count DESC, tags.name"]}
          tagger_class, tags, options = extract_params_for_taggables(params, default_options)
          tagger_class = tagger_class.class unless tagger_class.is_a?(Class)
        
          if tagger_class
            with_all_tags(tagger_class, tags).all
          else

          end
        
          # return [] if related_models.blank?
          #         
          # related_ids = related_models.map{|m|m.id}.join(", ")
          #         
          # taggable_class = self
          # if tagger_class
          #   Tag.all(Tag.send(tagging_association_of(tagger_class, taggable_class).send(taggable_key) => )
          # else
          # 
          # end
          #         
          # Tag.find(:all, options.merge({
          #   :select => "#{Tag.table_name}.*, COUNT(#{Tag.table_name}.id) AS count",
          #   :joins  => "JOIN #{Tagging.table_name} ON #{Tagging.table_name}.taggable_type = '#{base_class.name}'
          #     AND  #{Tagging.table_name}.taggable_id IN (#{related_ids})
          #     AND  #{Tagging.table_name}.tag_id = #{Tag.table_name}.id",
          #   :order => options[:order] || "count DESC, #{Tag.table_name}.name",
          #   :group => "#{Tag.table_name}.id, #{Tag.table_name}.name HAVING #{Tag.table_name}.name NOT IN (#{tags.map { |n| quote_value(n) }.join(",")})"
          # }))
        end
        
        def with_all_tags(*params)
          tagger_obj_or_class, tag_list, options = extract_params_for_taggables(params)

          tagger_class, tagger_obj = if tagger_obj_or_class && tagger_obj_or_class.is_a?(Class)
           [tagger_obj_or_class, nil]            
          elsif tagger_obj_or_class && !tagger_obj_or_class.is_a?(Class)
           [tagger_obj_or_class.class, tagger_obj_or_class]
          end
          
          conditions = "SELECT COUNT(DISTINCT(tag_id)) FROM taggings INNER JOIN tags ON taggings.tag_id = tags.id WHERE "
          counter_conditions = [ 
            "taggings.taggable_type = '#{self.to_s}'",
            "taggings.taggable_id = #{storage_name}.id",
            "tags.name IN (#{tag_list.map{|t| '"' << t << '"'}.join(', ')})"
            ]
          counter_conditions << "taggings.tagger_type = '#{tagger_class.to_s}'" if tagger_class
          counter_conditions << "taggings.tagger_id = #{tagger_obj.id}" if tagger_obj       
          conditions = "(" << conditions << counter_conditions.join(" AND ") << ") = ?"
          conditions = [conditions, tag_list.size]          
          with_any_tags(params).all(:conditions => conditions)
        end
        
        def with_any_tags(*params)
          tagger_obj_or_class, tag_list, options = extract_params_for_taggables(params)
          
          tagger_class, tagger_obj = if tagger_obj_or_class && tagger_obj_or_class.is_a?(Class)
            [tagger_obj_or_class, nil]            
          elsif tagger_obj_or_class && !tagger_obj_or_class.is_a?(Class)
            [tagger_obj_or_class.class, tagger_obj_or_class]
          end
          
          query = {  self.tags.tag.name => tag_list.to_a,
            Tagging.properties[:taggable_type] => self,
            :unique => true
          }
          query.merge!(Tagging.properties[:tagger_type] => tagger_class) if tagger_class
          query.merge!(Tagging.properties[:tagger_id] => tagger_obj.id) if tagger_obj
            
          all(query)            
        end
        
        def extract_params_for_taggables(params, options = {})
          tagger_class_or_object = params.delete_at(0) if params.first.respond_to?(:tagger?) && params.first.tagger?
          tagger_class_or_object ||= Tag.tagger
          _options = params.pop if params.last.is_a?(Hash)
          _options ||= {}
          _options = options.merge(_options)
          params.flatten!
          tags = TagList.from(params)
          return [tagger_class_or_object, tags, _options]
        end
        
        
      end # ClassMethods

      module TaggableInstanceMethods
        def tagger?;false;end
        def taggable?;true;end
        def taggable_class;self.class;end
        def taggable;self;end
        
        def can_tag_by?(tagger)
          if tagger.is_a?(Class)
            return self.class.tagger_classes.include?(tagger)
          end
          return self.class.tagger_classes.include?(tagger.class)
        end
        
        def tag_with(*params)
          tagger, tags, options = self.class.extract_params_for_taggables(params)
          self.class.create_taggings(tagger, taggable, params)
        end
        
        protected

        def destroy_all_taggings
          self.taggings.destroy!
        end
      end # InstanceMethods
    end # Taggable
  end # Is
end # DataMapper
