require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.camelcase,
      foreign_key: "#{name.to_s.underscore}_id".to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)
    options.each do |attr, value|
      self.send("#{attr}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: "#{self_class_name.downcase}_id".to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)
    options.each do |attr, value|
      self.send("#{attr}=", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method name do
      primary = options.primary_key
      foreign_value = self.send(options.foreign_key)
      results = options.model_class.where(primary => foreign_value)

      return nil if results.empty?
      results.first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method name do
      primary_value = self.send(options.primary_key)
      foreign = options.foreign_key
      results = options.model_class.where(foreign => primary_value)

      results
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
