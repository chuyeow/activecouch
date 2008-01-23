require 'rubygems'
require 'rake/gempackagetask'

PKG_VERSION = File.read('VERSION').chomp
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*.rb',
  'spec/**/*.rb'
]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Ruby-based wrapper for CouchDB"
  s.name = 'activecouch'
  s.author = 'Arun Thampi & Cheah Chu Yeow'
  s.email = "arun.thampi@gmail.com, chuyeow@gmail.com"
  s.homepage = "http://activecouch.googlecode.com"
  s.version = PKG_VERSION
  s.files = PKG_FILES
  s.has_rdoc = true
  s.require_path = "lib"
  s.extra_rdoc_files = ["README"]
  s.add_dependency 'json', '>=1.1.2'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => [:package]