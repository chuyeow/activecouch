if defined? RAILS_ENV
  require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'config', 'environment')
end

namespace :activecouch do
  desc "Creates a database in CouchDB"
  task :create_db do
    unless (database = ENV['db']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      exists = ActiveCouch::Exporter.exists?(site, "/#{ENV['db']}")
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

  desc "Deletes a database from CouchDB"
  task :delete_db do
    unless (database = ENV['db']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      exists = ActiveCouch::Exporter.exists?(site, "/#{ENV['db']}")
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

  desc "Saves a view in CouchDB"
  task :save_view do
    unless (view_name = ENV['view']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      
      unless(view = Object.const_get(view_name)).nil?
        databases = ENV['db'] == '_all_dbs' ? ActiveCouch::Exporter.all_databases(site) : ENV['db']
        databases.each do |db|
          saved = ActiveCouch::Exporter.export(site, view, :database => db)
          if saved
            puts "View exported successfully to #{db} on #{site}"
          else
            puts "There was an error in the export. Please check your CouchDB logs"
          end
        end
      else
        puts "Have you defined your view? Use ./script/generate activecouch_view ViewName from the root of your Rails app"
      end
    end
  end
  
  desc "Deletes a view in CouchDB"
  task :delete_view do
    unless (view_name = ENV['view']).nil?
      site = YAML::load(File.open(File.join(Rails.root, 'config', 'activecouch.yml')))[Rails.env]['site']
      
      
      unless(view = Object.const_get(view_name)).nil?
        databases = ENV['db'] == '_all_dbs' ? ActiveCouch::Exporter.all_databases(site) : ENV['db']
        databases.each do |db|
          deleted = ActiveCouch::Exporter.delete(site, view, :database => db)
          if deleted
            puts "View deleted successfully to #{db} on #{site}"
          else
            puts "There was an error in the deletion of the view. Please check your CouchDB logs"
          end
        end
      else
        puts "Have you defined your view? Use ./script/generate activecouch_view ViewName from the root of your Rails app"
      end
    end
  end  
end