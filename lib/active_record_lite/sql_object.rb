require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject

  def self.set_table_name(table_name)
    @current_table = table_name.underscore
  end

  def self.table_name
    @current_table
  end

  def self.all

    all_hashes = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{@current_table}
    SQL

    # different way to execute this query without heredocs
    #all_hashes = DBConnection.execute("SELECT * FROM #{@current_table}")


    return_array = []
    #p attributes
    all_hashes.each do |hash|

      attr_names = []

      return_array << self.new(hash)

    end

    return_array

  end

  def self.find(id)

    query = DBConnection.execute(<<-SQL, id)
    SELECT *
    FROM #{@current_table}
    WHERE id = ?
    SQL

    query
  end

  def create
    attr_values, attrs = attribute_values

    DBConnection.execute(<<-SQL, *attr_values)
    INSERT INTO #{self.class.table_name} (#{attrs.join(',')})
    VALUES ( #{ ([ '?' ] * attr_values.length).join(',') } )

    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    p 'in update'
    attr_values, attrs = attribute_values

    set_line = attrs.map{|el| "#{el} = ?"}.join(',')

    p set_line
    DBConnection.execute(<<-SQL, *attr_values)
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = #{id}

    SQL

  end

  def save
    if self.id.nil?
      create
    else
      update
    end

  end

  def attribute_values
    attr_values = []
    attrs = []

    self.class.attributes.each do |attr_name|
      next if attr_name == :id
      attrs << attr_name
      attr_values << self.send(attr_name)

    end

    [attr_values, attrs]

  end
end

