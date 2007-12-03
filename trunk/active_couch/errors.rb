module ActiveCouch
  class ActiveCouchError < StandardError
  end
  
  class IllegalArgumentError < ActiveCouchError
  end
  
  class ConfigurationMissingError < ActiveCouchError
  end
end