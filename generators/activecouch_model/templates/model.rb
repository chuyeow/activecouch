class <%= class_name %> < ActiveCouch::Base
  site YAML::load(File.open(File.join(Rails.root,
                  'config', 'activecouch.yml')))[Rails.env]['site']
  
end