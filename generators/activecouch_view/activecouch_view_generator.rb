class ActivecouchViewGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.template 'view.rb', File.join('app', 'models', "#{class_name.underscore}.rb")
    end
  end
  
end