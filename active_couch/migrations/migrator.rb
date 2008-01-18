# TODO
# - might consider moving create_database and delete_database to an adapter type class to encapsulate CouchDB semantics
#   and responses.
module ActiveCouch
  class Migrator
    class << self # Class methods
      def migrate(site, migration)
        if migration.view.nil? || migration.database.nil?
          raise ActiveCouch::MigrationError, "Both the view and the database need to be defined in your migration"
        end

        conn = Connection.new(site)
        # Migration for a view with name 'by_name' and database 'activecouch_test' should be PUT to
        # http://#{host}:#{port}/activecouch_test/_design/by_name.
        response = conn.put("/#{migration.database}/_design/#{migration.view}", migration.view_js)
        case response.code
        when '201'
          true # 201 = success
        else
          raise ActiveCouch::MigrationError, "Error migrating view - got HTTP response #{response.code}"
        end
      end

      def create_database(site, name)
        conn = Connection.new(site)
        response = conn.put("/#{name}", "{}")

        case response.code
        when '201' # 201 = success
          true
        when '409' # 409 = database already exists
          raise ActiveCouch::MigrationError, 'Database exists'
        else
          raise ActiveCouch::MigrationError, "Error creating database - got HTTP response #{response.code}"
        end
      end

      def delete_database(site, name)
        conn = Connection.new(site)
        response = conn.delete("/#{name}")

        case response.code
        when '202'
          true # 202 = success
        when '404'
          raise ActiveCouch::MigrationError, "Database '#{name}' does not exist" # 404 = database doesn't exist
        else
          raise ActiveCouch::MigrationError, "Error creating database - got HTTP response #{response.code}"
        end
      end
    end
  end
end