require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  attr_accessor :primary_key, :other_table, :foreign_key, :other_class
  def initialize(name, params)

    if params[:class_name]
      @other_class = params[:class_name].camelize.constantize
    else
      @other_class = name.to_s.camelize.constantize
    end

    @other_table = other_class.table_name

    if params[:primary_key]
      @primary_key = params[:primary_key]
    else
      @primary_key = :id
    end

    if params[:foreign_key]
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = (name.to_s + '_id').to_sym
    end
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :primary_key, :other_table, :foreign_key, :other_class
  def initialize(name, params, self_class)

    if params[:class_name]
      @other_class = params[:class_name].constantize
    else
      @other_class = name.to_s.singularize.camelize.constantize
    end

    @other_table = other_class.table_name

    if params[:primary_key]
      @primary_key = params[:primary_key]
    else
      @primary_key = :id
    end

    if params[:foreign_key]
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = (self_class.to_s.underscore + '_id').to_sym
    end


  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params = {} if @assoc_params.nil?
    @assoc_params
  end

  def belongs_to(name, params = {})
    define_method(name) do

      @aasoc_params[name] = BelongsToAssocParams.new(name, params)
      aps = aasoc_params[name]
      #p self.send(foreign_key)
      #p other_class.send(:find, 1)


      query = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{aps.other_table}
      WHERE #{self.send(aps.foreign_key)} = #{aps.other_table}.#{aps.primary_key}

      SQL

      aps.other_class.parse_all(query)
    end

  end

  def has_many(name, params = {})
    define_method(name) do

      aps = HasManyAssocParams.new(name, params, self.class)

      query = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{aps.other_table}
      -- WHERE #{aps.primary_key} = #{aps.other_table}.#{aps.foreign_key}

      SQL

      aps.other_class.parse_all(query)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    #has_one house, :through human, :source house
    define_method(name) do

      p @aasoc_params
      p [aps1.primary_key, aps1.other_table, aps1.foreign_key, aps1.other_class]


    end

  end
end
