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
      
      aps = BelongsToAssocParams.new(name, params)
      
      SQLObject.assoc_params[name] = aps

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
    WHERE #{self.send(aps.primary_key)} = #{aps.other_table}.#{aps.foreign_key}

      SQL

      aps.other_class.parse_all(query)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    #has_one house, :through human, :source house
    define_method(name) do
      
      assoc1_class = assoc1.to_s.camelize.constantize # Human
      assoc2_class = assoc2.to_s.camelize.constantize # House
      
      assoc1_object = self.send(assoc1).first #cat.human
      assoc2_object = assoc1_object.send(assoc2) #human.house
      
      aps = SQLObject.assoc_params
      assoc2_table = aps[assoc2].other_table # houses
      assoc1_table = aps[assoc1].other_table # humans
      
      assoc2_foreign_key = aps[assoc2].foreign_key # :house_id
      assoc2_primary_key = aps[assoc2].primary_key # :id
      
      assoc1_foreign_key = aps[assoc1].foreign_key # :owner_id
      assoc1_primary_key = aps[assoc1].primary_key # :id
      
      query = DBConnection.execute(<<-SQL)
      SELECT #{assoc2_table}.*
      FROM #{assoc2_table}
      JOIN #{assoc1_table}
      ON #{assoc1_table}.#{assoc2_foreign_key} = #{assoc2_table}.#{assoc2_primary_key}
    WHERE #{assoc1_table}.#{assoc1_primary_key} = #{self.send(assoc1_foreign_key)}

      SQL

      assoc2_class.parse_all(query)
    end

  end
end
