class ActivecouchModelGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.template 'model.rb', File.join('app', 'models', "#{class_name.underscore}.rb")
    end
  end
end