module ActiveCouch
  class Migrator
    class << self # Class methods
      def migrate(site, migration)
        conn = Connection.new(site)
        # Migration for a view with name 'by_name' and database 'activecouch_test' should be PUT to
        # http://#{host}:#{port}/activecouch_test/_design/by_name
        if migration.view.nil? || migration.database.nil?
          raise ActiveCouchMigrationError, "Both the view and the database need to be defined in your migration"
        end
        # Put to the database. 201 is returned if the migration is succesful
        puts "/#{migration.database}/_design/#{migration.view}"
        response = conn.put("/#{migration.database}/_design/#{migration.view}", migration.view_js)
        return response.code == '201'
      end
      
      def create_database(site, name)
        conn = Connection.new(site)
        response = conn.put("/#{name}", "{}")
        # 201 is retuned when a database has been created
        return response.code == '201'
      end
      
      def delete_database(site, name)
        conn = Connection.new(site)
        response = conn.delete("/#{name}")
        # 202 is returned when a database has been deleted
        return response.code == '202'
      end
    end
  end
end