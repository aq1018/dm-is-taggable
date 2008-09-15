module DataMapper
  module TagCreationFunctions
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
end