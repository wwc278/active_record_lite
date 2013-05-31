require_relative './db_connection'

module Searchable
  def where(params)
    values = params.values
    key_line = params.keys.map{|key| "#{key} = ?"}

    DBConnection.execute(<<-SQL, *values)
    SELECT *
    FROM #{@current_table}
    WHERE #{key_line.join(' AND ')}

    SQL

  end
end