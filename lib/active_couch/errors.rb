module ActiveCouch
  # Base exception class for all ActiveCouch errors.
  class ActiveCouchError < StandardError
  end

  # Raised when there is a configuration error (duh).
  class ConfigurationError < ActiveCouchError
  end

  # Raised when trying to get or set a non-existent attribute.
  class AttributeMissingError < ActiveCouchError
  end
end