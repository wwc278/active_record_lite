class MassObject

  def self.set_attrs(*attributes)
    @attributes = []
    attributes.each do |attr_name|
      @attributes << attr_name
      attr_accessor attr_name

    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
  end

  def initialize(params = {})
    #p "attributes are #{self.class.attributes}"
    params.each do |attr_name, value|
      #p "attr_name is #{attr_name}"
      if self.class.attributes.include?(attr_name.to_sym)

        self.send(attr_name.to_s + '=', value)
      else
        raise "mass assignment to unregistered attribute \"#{attr_name}\""
      end
    end
  end
end

