module DataMapper
  module Is
    module Taggable
      
      def is_tagger(options)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggerClassMethods
        include DataMapper::Is::Taggable::TaggerInstanceMethods

        @taggable_classes = options[:on]
        Tag.instance_variable_set('@taggable_classes', (Tag.instance_variable_get('@taggable_classes') | @taggable_classes))
        
        has n, :taggings, :class_name => "Tagging", :child_key => [:tagger_id], :tagger_type => self.to_s
        # real ugly syntax... wait until dm make better conditional has n :through association better, than update code
        has n, :tags, :through => :taggings, :class_name => "Tag", :child_key => [:tagger_id], Tagging.properties[:tagger_type] => self.to_s
      end
      
      module TaggerClassMethods 
        def taggable_classes
          @taggable_classes.map{|klass| Extlib::Inflection.constantize(klass.to_s.singular.camel_case)}
        end
        
        def tagger?;true;end
        def taggable?;false;end
        def tagger_class;self;end
        
      end # ClassMethods

      module TaggerInstanceMethods
        def tagger?;true;end
        def taggable?;false;end
        def tagger_class;self.class;end
        def tagger;self;end
        
        def can_tag_on?(taggable)
          if taggable.is_a?(Class)
            return self.class.taggable_classes.include?(taggable)
          end
          return self.class.taggable_classes.include?(taggable.class)
        end

        def find_taggables(options)
          tagger, taggable, tag_list, options = extract_options(options)
          tagger = self
          Tag.find_taggables(options.merge(:with => tag_list, :on =>taggable, :by => tagger))
        end
        
        def tag(options)
          tagger, taggable, tags = extract_options(options)
          tagger = self
          self.class.create_taggings(tagger, taggable, tags)
        end
        
        def all_similar_by_tags
          # this magic query is basically looking at the taggings table,
          #  searching for taggings having a corresponding tagging from the current taggable object with the same tag_id
          #  grouping by tagger_id and counting how many are they
          sql = "SELECT count(*), tagger_id 
                 FROM (
                   SELECT DISTINCT t1.tag_id, t1.tagger_id AS tagger_id 
                   FROM taggings AS t1 
                   INNER JOIN taggings AS t2 
                   ON ( t2.tag_id = t1.tag_id AND t2.tagger_type = '#{self.class.to_s}' AND t2.tagger_id = #{self.id}) 
                   WHERE t1.tagger_type = '#{self.class.to_s}' AND t1.tagger_id != #{self.id}
                 )
                 AS a 
                 GROUP BY tagger_id;"
        
          
          taggers = repository.adapter.query(sql)
          
          # for each other taggers, we have the number of tags in common and the tagger object
          # we order the result by similarity descending
          taggers.collect{|tagger| [tagger[0], self.class.get(tagger[1])]}.sort {|x,y| y[0]<=>x[0]}
        end
      end # InstanceMethods
    end
  end
end