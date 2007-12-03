module ActiveCouch
  class ActiveCouchError < StandardError
  end
  
  class IllegalArgumentError < ActiveCouchError
  end
  
  class ConfigurationError < ActiveCouchError
  end
end