module DataMapper
  module Is
    module Taggable
      
      def is_tagging(options=nil)
        extend  DataMapper::Is::Taggable::SharedClassMethods
        include DataMapper::Is::Taggable::SharedInstanceMethods
        extend  DataMapper::Is::Taggable::TaggingClassMethods
        include DataMapper::Is::Taggable::TaggingInstanceMethods

        property :id, DataMapper::Types::Serial
        property :tag_id, Integer,        :index => :true,      :nullable => false

        property :tagger_id, Integer,     :index => :tagger,    :nullable => true
        property :tagger_type, String,    :index => :tagger,    :nullable => true,  :size => 255

        property :taggable_id, Integer,   :index => :taggable,  :nullable => false
        property :taggable_type, String,  :index => :taggable,  :nullable => false, :size => 255
        
        belongs_to :tag
      end
      
      module TaggingClassMethods
        def total(options = {})
          property = DataMapper::Property.new(Tagging, :"count(*)",
            Integer, :auto_validation => false)
          order = options[:order] || :desc
          dir = DataMapper::Query::Direction.new(property, order)
          tag_id_to_count = Tagging.aggregate(:all.count,
            options.merge(:fields => [:tag_id], :order => [dir]))
          return [] if tag_id_to_count.empty?
          tag_ids, counts = tag_id_to_count.transpose
          Tag.all(:id => tag_ids).zip counts
        end
      end

      module TaggingInstanceMethods
      end
    end
  end
end
