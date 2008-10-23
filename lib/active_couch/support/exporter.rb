# TODO
# - might consider moving create_database and delete_database to an adapter type class to encapsulate CouchDB semantics
#   and responses.
module ActiveCouch
  class Exporter
    class << self # Class methods

      def all_databases(site)
        conn = Connection.new(site)
        JSON.parse(conn.get("/_all_dbs"))
      end
      
      def export(site, view, opts = {})
        existing_view = {}
        if view.name.nil? || (view.database.nil? && opts[:database].nil?)
          raise ActiveCouch::ViewError, "Both the name and the database need to be defined in your view"
        end
        # If the database is not defined in the view, it can be supported
        # as an option to the export method
        database_name = opts[:database] || view.database
        conn = Connection.new(site)
        # The view function for a view with name 'by_name' and database 'activecouch_test' should be PUT to
        # http://#{host}:#{port}/activecouch_test/_design/by_name.
        if(view_json = exists?(site, "/#{database_name}/_design/#{view.name}"))
          existing_view = JSON.parse(view_json)
        end
        response = conn.put("/#{database_name}/_design/#{view.name}", view.to_json(existing_view))
        case response.code
        when '201'
          true # 201 = success
        else
          raise ActiveCouch::ViewError, "Error exporting view - got HTTP response #{response.code}"
        end
      end

      def delete(site, view, opts = {})
        rev = nil
        if view.name.nil? || (view.database.nil? && opts[:database].nil?)
          raise ActiveCouch::ViewError, "Both the name and the database need to be defined in your view"
        end
        # If the database is not defined in the view, it can be supported
        # as an option to the export method
        database_name = opts[:database] || view.database
        conn = Connection.new(site)
        if(view_json = exists?(site, "/#{database_name}/_design/#{view.name}"))
          rev = JSON.parse(view_json)['_rev']
        end
        # The view function for a view with name 'by_name' and database 'activecouch_test' should be PUT to
        # http://#{host}:#{port}/activecouch_test/_design/by_name.
        response = conn.delete("/#{database_name}/_design/#{view.name}?rev=#{rev}")
        if response.code =~ /20[0,2]/
          true # 20[0,2] = success
        else
          raise ActiveCouch::ViewError, "Error deleting view - got HTTP response #{response.code}"
        end
      end

      def exists?(site, name)
        conn = Connection.new(site)
        response = conn.get("#{name}")
        response
      rescue ActiveCouch::ResourceNotFound
        false
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