require File.join(File.dirname(__FILE__), '..', 'lib', 'active_couch')

namespace :activecouch do
  desc "Set of tools for making Ruby On Rails play nice with CouchDB"
  
  task :create_db do
    unless (database = ENV['db']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      exists = ActiveCouch::Exporter.exists_database?(site, ENV['db'])
      unless exists
        ActiveCouch::Exporter.create_database(site, ENV['db'])
        puts "Database #{database} created in #{site}"
      else
        puts "Database #{database} already exists in #{site}"
      end
    else
      puts "You need to specify a database. Usage: rake activecouch:create_db db=<database_name>"
    end
  end

  task :delete_db do
    unless (database = ENV['db']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      exists = ActiveCouch::Exporter.exists_database?(site, ENV['db'])
      if exists
        ActiveCouch::Exporter.delete_database(site, ENV['db'])
        puts "Database #{database} deleted from #{site}"
      else
        puts "Database #{database} does not exist in #{site}"
      end
    else
      puts "You need to specify a database. Usage: rake activecouch:delete_db db=<database_name>"
    end
  end
end