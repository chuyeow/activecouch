# TODO
# - might consider moving create_database and delete_database to an adapter type class to encapsulate CouchDB semantics
#   and responses.
module ActiveCouch
  class Exporter
    class << self # Class methods
      def export(site, view)
        if view.name.nil? || view.database.nil?
          raise ActiveCouch::ViewError, "Both the name and the database need to be defined in your view"
        end

        conn = Connection.new(site)
        # view for a view with name 'by_name' and database 'activecouch_test' should be PUT to
        # http://#{host}:#{port}/activecouch_test/_design/by_name.
        response = conn.put("/#{view.database}/_design/#{view.name}", view.to_json)
        case response.code
        when '201'
          true # 201 = success
        else
          raise ActiveCouch::ViewError, "Error exporting view - got HTTP response #{response.code}"
        end
      end

      def create_database(site, name)
        conn = Connection.new(site)
        response = conn.put("/#{name}", "{}")

        case response.code
        when '201' # 201 = success
          true
        when '409' # 409 = database already exists
          raise ActiveCouch::ViewError, 'Database exists'
        else
          raise ActiveCouch::ViewError, "Error creating database - got HTTP response #{response.code}"
        end
      end

      def delete_database(site, name)
        conn = Connection.new(site)
        response = conn.delete("/#{name}")

        case response.code
        when '200'
        when '201'
        when '202'
          true # 201 = success
        when '404'
          raise ActiveCouch::ViewError, "Database '#{name}' does not exist" # 404 = database doesn't exist
        else
          raise ActiveCouch::ViewError, "Error creating database - got HTTP response #{response.code}"
        end
      end
    end
  end
end