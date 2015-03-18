require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method name do
      source = through_options.model_class.assoc_options[source_name]

      through = through_options.table_name
      source = source.table_name

      join_clause = <<-SQL
        #{through}.#{source.foreign_key} =
          #{source}.#{source_options.primary_key}
      SQL

      where_clause = <<-SQL
        #{through}.#{through_options.primary_key} =
          #{self.send(through_options.foreign_key)}
      SQL

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{source}.*
        FROM
          #{through}
        JOIN
          #{source} ON #{join_clause}
        WHERE
          #{where_clause}
      SQL

      source_options.model_class.new(results.first)
    end
  end
end
