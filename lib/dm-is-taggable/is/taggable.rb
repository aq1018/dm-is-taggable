module DataMapper
  module Is
    module Taggable

      def is_taggable(options)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggableClassMethods
        include DataMapper::Is::Taggable::TaggableInstanceMethods
        
        attr_reader :tagger_classes
        @tagger_classes = options[:by]
        
        @tagger_classes.each do |tagger_klass|
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
          
          # create a has many association for tag
          Tag.has n, tagging_association.intern, :class_name => tagging_class_name          
        end
      end
      
      module TaggableClassMethods
        def with_all_tags_and_by(*params)
        end
        
        def with_all_tags(*tags)
          tags = TagList.from(tags)
          taggable_class = self

          rv = @tagger_classes.map do |tagger_class|
            tagging_table_name = tagging_class_of(tagger_class, taggable_class).storage_name
            tag_table_name = Tag.storage_name
            
            conditions = ["
              (SELECT COUNT(*) FROM #{tagging_table_name}
               INNER JOIN #{tag_table_name} ON #{tagging_table_name}.tag_id = #{tag_table_name}.id
               WHERE #{tagging_table_name}.#{Extlib::Inflection.foreign_key(taggable_class.name)} = #{storage_name}.id AND
               #{tag_table_name}.name IN (#{tags.map{|t| '"' << t << '"'}.join(', ')})) = ?
            ", tags.size ]
            
            all(
              self.send(tagging_association_of(tagger_class, taggable_class)).tag.name => tags.to_a, 
              :conditions => conditions
            )
            
          end.flatten!
          rv.uniq!
          rv.nil? ? [] : rv
        end
        
        def with_any_tags(*tags)
          tags = TagList.from(tags)
          taggable_class = self

          rv = @tagger_classes.map do |tagger_class|
            all(self.send(tagging_association_of(tagger_class, taggable_class)).tag.name => tags.to_a)
          end.flatten!
          rv.uniq!
          rv.nil? ? [] : rv
        end
      end # ClassMethods

      module TaggableInstanceMethods
        def tag_by(*params)
          # get the first paramater as the taggable object
          tagger = params.delete_at(0)
          taggable = self
          self.class.create_taggings(tagger, taggable, params)
        end
      end # InstanceMethods

    end # Taggable
  end # Is
end # DataMapper
