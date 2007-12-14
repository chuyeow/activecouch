module ActiveCouch
  class ActiveCouchMigrationError < StandardError; end
  class InvalidFilter < ActiveCouchMigrationError; end
end