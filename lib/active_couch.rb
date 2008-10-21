$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'

require 'active_couch/support'
require 'active_couch/errors'
require 'active_couch/base'
require 'active_couch/connection'
require 'active_couch/views'
require 'active_couch/callbacks'