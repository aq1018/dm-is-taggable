module DataMapper
  module Is
    module Taggable
      
      def is_tag(options=nil)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TagClassMethods
        include DataMapper::Is::Taggable::TagInstanceMethods
        property :id, DataMapper::Types::Serial
        property :name, String, :length => 255, :unique => true, :nullable => false
        has n, :taggings
        @tagger_classes ||= []
        @taggable_classes ||= []
      end
      
      module TagClassMethods
        attr_reader :tagger
        attr_reader :tagger_classes
        attr_reader :taggable_classes
        #TODO: check if there is any concurrency problem here
        # NOT thread safe right now!!
        # need to make it safer!!
        def as(tagger_or_tagger_class, &block)
          self.tagger = tagger_or_tagger_class
          raise Exception("A block must be provided!") unless block_given?
          yield
          self.tagger=nil
        end
        
        def tagged_count(options={})
          tagger, taggable, tag_list, options = extract_options(options)
          tagger_class, tagger_obj = extract_tagger_class_object(tagger)
          taggable_class, taggable_obj = extract_taggable_class_object(taggable)
          
          association = Tagging
          association = association.by(tagger) if tagger
          association = association.on(taggable) if taggable
          
          query = {:unique => true, :fields => [:taggable_type]}
          query.merge!(Tagging.tag.name => tag_list.to_a) unless tag_list.empty?
          query.merge!(options)
          
          association.aggregate(:taggable_id.count, query).inject(0){|count, i| count + i[1]}
        end
        
        def find_taggables(options)
          tagger, taggable, tag_list, options = extract_options(options)
          tagger_class, tagger_obj = extract_tagger_class_object(tagger)
          taggable_class, taggable_obj = extract_taggable_class_object(taggable)
                    
          if taggable_class.nil?
            rv = Tag.taggable_classes.map{|klass| find_taggables(options.merge(:with => tag_list, :on =>klass, :by => tagger) )}.flatten!
            rv.uniq!
            return rv
          end
          
          query = {  taggable_class.tags.tag.name => tag_list.to_a,
            Tagging.properties[:taggable_type] => taggable_class.to_s,
            :unique => true
           }
           query.merge!(Tagging.properties[:tagger_type] => tagger_class) if tagger_class
           query.merge!(Tagging.properties[:tagger_id] => tagger_obj.id) if tagger_obj          
          
          unless options[:match] == :any
            conditions = "SELECT COUNT(DISTINCT(tag_id)) FROM taggings INNER JOIN tags ON taggings.tag_id = tags.id WHERE "
            counter_conditions = [
              "taggings.taggable_type = '#{taggable_class.to_s}'",
              "taggings.taggable_id = #{taggable_class.storage_name}.id",
              "tags.name IN ?"
              ]
            counter_conditions << "taggings.tagger_type = '#{tagger_class.to_s}'" if tagger_class
            counter_conditions << "taggings.tagger_id = #{tagger_obj.id}" if tagger_obj       
            conditions = "(" << conditions << counter_conditions.join(" AND ") << ") = ?"
            conditions = [conditions, tag_list, tag_list.size]          
            query.merge!(:conditions => conditions)
          end
          taggable_class.all(query)
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
        def <=>(other)
          self.name <=>(other.name)
        end
        def to_s
          self.name
        end
        
       # Returns an array of related tags.
       # Related tags are all the other tags that are found  tagged with the provided tags.
        def related
          sql = "SELECT count(*) AS count, tag_id
                 FROM
                  (SELECT DISTINCT t2.tag_id AS tag_id, t2.tagger_id, t2.tagger_type, t2.taggable_id, t2.taggable_type
                  FROM taggings AS t1 
                  INNER JOIN taggings AS t2 
                  ON ( t2.taggable_id = t1.taggable_id AND t2.taggable_type = t1.taggable_type) 
                  WHERE t1.tag_id = #{self.id} AND t2.tag_id != #{self.id})
                 AS a
                 GROUP BY tag_id 
                 HAVING count(*) > 1
                 ORDER BY count(*) DESC;"
                 
           # get a hash with tag_id => tag count
           tags = repository.adapter.query(sql).inject({}){|h, t| h[t[1].to_i] = t[0].to_i; h}
           
           # get all the tag resources
           tag_objects = Tag.all(:id => tags.keys)
           
           # turn it into an array like this [[count, tag], [count, tag] ...]
           # sorted by count in descending order
           tag_objects.collect do |t|
             [tags[t.id], t]
           end.sort{|a, b| a[0] <=> b[0]}.reverse
         end
        
        def popular_by_tags
          sql= "SELECT tagger_type, tagger_id, COUNT( taggable_id ) AS counter
                    FROM taggings
                    INNER JOIN tags ON taggings.tag_id = tags.id
                    WHERE tags.name = '#{self.name}'
                    GROUP BY tagger_type, tagger_id
                    ORDER BY counter DESC"
          tagger_columns = repository.adapter.query(sql)
          tagger_hash = {}
          counter_hash = {}
          # group all keys
          tagger_columns.each do |t|
            t = t.to_a
            tagger_hash[t[0]] ||= []
            tagger_hash[t[0]] << t[1]
            count = t.pop
            counter_hash[t] = count
          end
          taggers = []
          # find all taggers
          tagger_hash.each_pair do |key, value|
            taggers = taggers + Extlib::Inflection.constantize(key).all(:id => value)
          end
          # sort the taggers by count
          taggers.sort! do |a, b|
            counter_hash[[a.class.to_s, a.id]] <=>counter_hash[[b.class.to_s, b.id]]
          end.reverse!

          taggers
        end
        
        def tagged_together_count
        end
        
        def tagged_count(conditions={})
          taggable_class, taggable_obj = extract_taggable_class_object(conditions.delete(:on))
          tagger_class, tagger_obj = extract_tagger_class_object(conditions.delete(:by))
          
          association = if taggable_class && taggable_class.is_a?(Class) && taggable_class.taggable?
            taggable_class.all.taggings
          else
            Tagging.all
          end
          
          association = association.all(:tagger_type => tagger_class.to_s) if tagger_class
          association = association.all(:tagger_id => tagger_obj.id) if tagger_obj

          query = {:unique => true, :tag_id => self.id, :fields => [:taggable_type]}
          query.merge!(conditions)
          
          association.aggregate(:taggable_id.count, query).inject(0){|count, i| count + i[1]}
        end
      end # InstanceMethods
    end
  end
end