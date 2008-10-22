# This is needed if ActiveCouch is used as a Rails plugin
activecouch_config = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'config', 'activecouch.yml')

unless File.exists?(activecouch_config)
  config = <<EOF
development:
  site: 'http://localhost:5984'
production:
  site: 'http://localhost:5984'
test:
  site: 'http://localhost:5984'
EOF
  File.open(activecouch_config, 'w') { |out| out.puts(config) }
end