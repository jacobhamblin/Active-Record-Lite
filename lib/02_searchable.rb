require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where = params.map { |attr, value| "#{attr} = ?" }.join(' AND ')

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where}
    SQL

    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
