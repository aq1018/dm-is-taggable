module DataMapper
  module Is
    module Taggable

      ##
      # fired when your plugin gets included into Resource
      #
      def self.included(base)

      end

      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :taggable
      ##

      def is_taggable(options)
        extend  DataMapper::Is::Taggable::Shared::ClassMethods
        include DataMapper::Is::Taggable::Shared::InstanceMethods
        extend  DataMapper::Is::Taggable::Tagged::ClassMethods
        include DataMapper::Is::Taggable::Tagged::InstanceMethods
        
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
            :remixable_key => tagging_association
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
          ::Tag.has n, tagging_association.intern, :class_name => tagging_class_name  
          
        end
        puts "________________#{self.name} remixables: #{remixables.inspect}"
      end
      
      def is_tagger(options=nil)
        extend  DataMapper::Is::Taggable::Shared::ClassMethods
        include DataMapper::Is::Taggable::Shared::InstanceMethods
        extend  DataMapper::Is::Taggable::Tagger::ClassMethods
        include DataMapper::Is::Taggable::Tagger::InstanceMethods
      end
      
      def is_tag(options=nil)
        extend  DataMapper::Is::Taggable::Tag::ClassMethods
        include DataMapper::Is::Taggable::Tag::InstanceMethods
        property :id, DataMapper::Types::Serial
        property :name, String, :length => 255, :unique => true, :nullable => false
        has n, :taggings
      end
      
      def is_tagging(options=nil)
        extend  DataMapper::Is::Taggable::Tagging::ClassMethods
        include DataMapper::Is::Taggable::Tagging::InstanceMethods
        is :remixable
        property :id, DataMapper::Types::Serial
        property :tag_id, Integer
      end

      module Tagged
        module ClassMethods
          
          def with_all_tags_and_by(*params)
            
          end
          
          def with_all_tags(*tags)
            tags = TagList.from(tags)
            taggable_class = self

            rv = @tagger_classes.map do |tagger_class|
              tagging_table_name = tagging_class_of(tagger_class, taggable_class).storage_name
              tag_table_name = ::Tag.storage_name
              
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

        module InstanceMethods
          
          def tag_by(*params)
            # get the first paramater as the taggable object
            tagger = params.delete_at(0)
            taggable = self
            self.class.create_taggings(tagger, taggable, params)
          end
          
        end # InstanceMethods
      end # Tagged
            
      module Tagger
        module ClassMethods
          
          def all_similar_by_tags
            
          end
          
          
        end # ClassMethods

        module InstanceMethods
          
          def all_tagged_with
            
          end
          
          def tag_on(*params)
            # get the first paramater as the taggable object
            tagger = self
            taggable = params.delete_at(0)
            self.class.create_taggings(tagger, taggable, params)
          end

        end # InstanceMethods
      end # Tagger
      
      module Tag
        module ClassMethods
          
          def all_by
            
          end
          
          def fetch(name)
            first(:name => name) || create(:name => name)
          end
          
          def get(name)
            first(:name => name)
          end
          
          
        end # ClassMethods

        module InstanceMethods
          
          def related_tags
            
          end
          
          def popular_by_tags
            
          end
          
          def tagged_together_count
            
          end
          
          def tagged_count
            
          end

        end # InstanceMethods
      end # Tag
      
      module Tagging
        module ClassMethods
        end
        
        module InstanceMethods
        end
      end
      
      module Shared
        module ClassMethods
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
            tags = TagList.from(tags)
            
            # TODO: add checks to see if tags can be added
            #raise Exception("Cannot Tag #{taggable.class}!") if !taggable.is_a?(Article) && !taggable.is_a?(Picture)
            tagger_klass = tagger.class
            taggable_klass = taggable.class
            tagging_klass = tagging_class_of(tagger_klass, taggable_klass)
            tags.each do |tag|
              tag_obj = ::Tag.fetch(tag)
              tagging = tagging_klass.new(:tag => tag_obj)
              
              [tagger, taggable].each{|obj| obj.tagging_association_of(tagger_klass, taggable_klass) << tagging}
              success = tagging.save
            end # end of each
          end
        end
        
        module InstanceMethods
          def tagging_association_of(tagger_klass, taggable_klass)
            self.send(self.class.tagging_association_of(tagger_klass, taggable_klass))
          end
          
          def tag_association_of(tagger_klass, taggable_klass)
            self.send(self.class.tag_association_of(tagger_klass, taggable_klass))
          end
        end
      end

    end # Taggable
  end # Is
end # DataMapper
