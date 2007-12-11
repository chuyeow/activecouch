module ActiveCouch
  class ActiveCouchError < StandardError #:nodoc:
  end

  class ConfigurationError < ActiveCouchError #:nodoc:
  end
  
  class InvalidCouchTypeError < ActiveCouchError #:nodoc:
  end
  
  class AttributeMissingError < ActiveCouchError #:nodoc:
  end
  
end