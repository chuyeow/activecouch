require 'rubygems'
require 'rake/gempackagetask'

PKG_NAME = 'activecouch'
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

task :lines do
  lines, codelines, total_lines, total_codelines = 0, 0, 0, 0

  for file_name in FileList["lib/active_couch/**/*.rb"]
    next if file_name =~ /vendor/
    f = File.open(file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
    puts "L: #{sprintf("%4d", lines)}, LOC #{sprintf("%4d", codelines)} | #{file_name}"
    
    total_lines     += lines
    total_codelines += codelines
    
    lines, codelines = 0, 0
  end

  puts "Total: Lines #{total_lines}, LOC #{total_codelines}"
end

task :default => [:package]