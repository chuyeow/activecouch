$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_support/core_ext'
require 'active_support/json'
require 'active_couch/extensions'
require 'active_couch/errors'
require 'active_couch/base'
require 'active_couch/connection'