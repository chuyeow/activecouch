module ActiveCouch
  class MigrationError < StandardError; end
  class InvalidFilter < MigrationError; end
end