module DataMapper
  module Is
    module Taggable

      def is_taggable(options)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggableClassMethods
        include DataMapper::Is::Taggable::TaggableInstanceMethods
        

        @tagger_classes = options[:by]
        
        tagger_classes.each do |tagger_klass|
          taggable_klass = self
          tagging_association = tagging_association_of(tagger_klass, taggable_klass)
          tag_association = tag_association_of(tagger_klass, taggable_klass)
          tagging_class_name = tagging_class_name_of(tagger_klass, taggable_klass)
          
          # remix in the taggings association for each tagger and taggable
          remix_opts = {
            :as => tagging_association,
            :for => tagger_klass,
            :class_name => tagging_class_name,
          }
          remix n, :taggings, remix_opts
          
          enhance :taggings, tagging_class_name.intern do
            belongs_to :tag
            belongs_to taggable_klass.name.snake_case.intern
            belongs_to tagger_klass.name.snake_case.intern
          end
          
          through_association_name = tagging_association_of(tagger_klass, taggable_klass)
          association_name = tag_association_of(tagger_klass, taggable_klass)
          
          # create a psudo-association for taggable
          taggable_klass.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{tag_association}
              self.send(:'#{tagging_association}').tag
            end
          EOS
          
          # create a psudo-association for tagger
          tagger_klass.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{tag_association}
              self.send(:'#{tagging_association}').tag
            end
          EOS
          
          # add the taggable class into tagger
          tagger_klass.taggable_classes << taggable_klass

          # create a has many association for tag
          Tag.has n, tagging_association.intern, :class_name => tagging_class_name          
        end
      end
      
      module TaggableClassMethods
        attr_reader :tagger_classes
        
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
          tagger_class, tags, options = extract_params_for_taggables(params)
          tagger_class = tagger_class.class unless tagger_class.nil? || tagger_class.is_a?(Class)
          
          tag_table_name = Tag.storage_name
          
          if tagger_class
            tagging_table_name = tagging_class_of(tagger_class, taggable_class).storage_name

            conditions = ["
              (SELECT COUNT(*) FROM #{tagging_table_name}
               INNER JOIN #{tag_table_name} ON #{tagging_table_name}.tag_id = #{tag_table_name}.id
               WHERE #{tagging_table_name}.#{Extlib::Inflection.foreign_key(taggable_class.name)} = #{storage_name}.id AND
               #{tag_table_name}.name IN (#{tags.map{|t| '"' << t << '"'}.join(', ')})) = ?
            ", tags.size ]
            
            all(self.send(tagging_association_of(tagger_class, taggable_class)).tag.name => tags.to_a, :conditions => conditions, :unique => true)
          else
            rv = tagger_classes.map{|tc| with_all_tags(tc, tags, options)}.flatten!
            rv.uniq!
            rv.nil? ? [] : rv
          end
        end
        
        def with_any_tags(*params)
          tagger_class, tags, options = extract_params_for_taggables(params)
          tagger_class = tagger_class.class unless tagger_class.nil? || tagger_class.is_a?(Class)
          
          if tagger_class
            all(self.send(tagging_association_of(tagger_class, taggable_class)).tag.name => tags.to_a, :unique => true)
          else
            rv = tagger_classes.map{|tc| with_any_tags(tc, tags, options)}.flatten!
            rv.uniq!
            rv.nil? ? [] : rv
          end
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
      end # InstanceMethods

    end # Taggable
  end # Is
end # DataMapper
