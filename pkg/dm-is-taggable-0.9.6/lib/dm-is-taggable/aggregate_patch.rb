# we need this unless someone adds the "count(distinct id)" support in dm-aggegrates
module DataMapper
  module Adapters
    class DataObjectsAdapter
      module SQL
        private
         def fields_statement(query)
          qualify = query.links.any?
          query.fields.map { |p| property_to_column_name(query.repository, p, qualify, query.unique?) } * ', '
        end
 
         def property_to_column_name(repository, property, qualify, unique=false)
          case property
            when Query::Operator
              aggregate_field_statement(repository, property.operator, property.target, qualify, unique)
            when Property
              original_property_to_column_name(repository, property, qualify)
            when Query::Path
             original_property_to_column_name(repository, property, qualify)
            else
              raise ArgumentError, "+property+ must be a DataMapper::Query::Operator or a DataMapper::Property, but was a #{property.class} (#{property.inspect})"
          end
        end
 
        def aggregate_field_statement(repository, aggregate_function, property, qualify, unique=false)
          column_name = if aggregate_function == :count && property == :all
            '*'
          else
            unique ? "distinct #{property_to_column_name(repository, property, qualify)}" :
              property_to_column_name(repository, property, qualify)
          end
 
          function_name = case aggregate_function
            when :count then 'COUNT'
            when :min then 'MIN'
            when :max then 'MAX'
            when :avg then 'AVG'
            when :sum then 'SUM'
            else raise "Invalid aggregate function: #{aggregate_function.inspect}"
          end
 
          "#{function_name}(#{column_name})"
        end
      end # module SQL
    end # class DataObjectsAdapter
  end # module Adapters
end # module DataMapper