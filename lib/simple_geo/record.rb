module SimpleGeo
  class Record
    attr_accessor :layer, :id, :lat, :lon, :type, :created, :properties
  
    def initialize(options={})
      options = { 
        :created => Time.now,
        :type => 'object',
        :properties => {}
      }.merge(options)

      @id = options[:id]
      @layer = options[:layer]
      @type = options[:type]
      @lat = options[:lat]
      @lon = options[:lon]
      @created = options[:created]
      @properties = options[:properties]
    end
    
    def to_hash
      {
        :type => 'Feature',
        :id => id,
        :created => created.to_i,
        :geometry => { 
          :type => 'Point',
          :coordinates => [ lon, lat ]
        },
        :properties => properties.merge({
          :type => type,
          :layer => layer
        })
      }
    end
    
    def to_json
      self.to_hash.to_json
    end
    
    def ==(other)
      other.class == self.class && self.to_hash == other.to_hash
    end
    
    def self.parse_geojson_hash(json_hash)
      Record.new(
        :id => json_hash['id'],
        :type => json_hash['properties'].delete('type'),
        :lat => json_hash['geometry']['coordinates'][1],
        :lon => json_hash['geometry']['coordinates'][0],
        :created => Time.at(json_hash['created']),
        :properties => Record.recursively_symbolize_keys(json_hash['properties'])
      )
    end
    
    def self.parse_features_hash(layer, features_hash)
      records = []
      features_hash['features'].each do |feature_hash|
        record = Record.parse_geojson_hash(feature_hash)
        record.layer = layer
        records << record
      end
      records
    end
    
    def self.recursively_symbolize_keys(object)
      if object.is_a? Hash
        symbolized_hash = object.symbolize_keys
        symbolized_hash.each do |key, value|
          symbolized_hash[key] = recursively_symbolize_keys(value)
        end
        symbolized_hash
      elsif object.is_a? Array
        object.map { |value| recursively_symbolize_keys(value) }
      else
        object
      end
    end
  
  end
end
