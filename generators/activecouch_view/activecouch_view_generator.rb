class ActivecouchViewGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory File.join('app', 'couchdb_views')
      m.template 'view.rb', File.join('app', 'couchdb_views', "#{class_name.underscore}.rb")
    end
  end
  
end