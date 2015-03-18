require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    return[0].map(&:to_sym)
  end

  def self.finalize!

    self.columns.each do |col|
      define_method(col) { self.attributes[col] }
      define_method("#{col}=") { |val| self.attributes[col] = val }
    end

  end

  def self.table_name=(table_name)
    # ...
  end

  def self.table_name
    name = "#{self}s"
    name = name.downcase
    @@table = name
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT * FROM #{self.table_name}
    SQL
    parse_all(all)
  end

  def self.parse_all(results)
    output = []
    results.each do |hash|
      output << self.new(hash)
    end
    output
  end

  def self.find(id)
    p obj = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL

    parse_all(obj).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name)


      send("#{attr_name}=", value )
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
     cols = self.class.columns[1..-1]
     col_names = cols.join(',')
     question_marks = (['?'] * cols.length).join(',')
     args = attribute_values[1..-1]

     DBConnection.execute(<<-SQL, *args)
       INSERT INTO
         #{self.class.table_name} (#{col_names})
       VALUES
         (#{question_marks});
     SQL

     self.id = DBConnection.last_insert_row_id
   end

  def update
    set_line = self.class.columns.map {|attr_name| "#{attr_name} = ?" }.join(',')

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
