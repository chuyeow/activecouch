module ActiveCouch
  class Migrator
    def migrate(site, migration)
      conn = Connection.new(site)
      conn.put('_design/', migration.migrate)
    end
  end
end