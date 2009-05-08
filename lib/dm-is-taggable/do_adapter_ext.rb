module DataMapper
  module Adapters
    class DataObjectsAdapter < AbstractAdapter
      module SQL
      private
        alias :property_to_column_name_org :property_to_column_name
        def property_to_column_name(repository, property, *args)
          result = property_to_column_name_org(repository, property, *args)
          if property.respond_to?(:name) && property.name == :"count(*)"
            result.gsub!(/^"|"$/, '')
          end
          result
        end
      end
    end
  end
end

