require File.dirname(__FILE__) + '/spec_helper.rb'

require 'net/http'
require 'uri'

class ByFace < ActiveCouch::Migration
  define :for_db => 'people' do
    with_key 'face'
  end
end

describe "An ActiveCouch::Migrator class" do
  after(:each) do
    # TODO: Do not have dependency on delete_database to test create_database
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'ac_test')
  end
  
  it "should create a database when sent the create_database method" do
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test').should == true
  end
end

describe "An ActiveCouch::Migrator class" do
  before(:each) do
    # TODO: Do not have dependency on create_database to test delete_database
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test')
  end
  
  it "should delete a database successfully when sent the delete_database method" do
    ActiveCouch::Migrator.delete_database('http://localhost:5984', 'ac_test').should == true
  end
end

describe "An ActiveCouch::Migrator class" do
  before(:each) do
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'people')
  end
  
  it "should be able to create a permanent view when sent the migrate method" do
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/people/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/people/_design/by_face")
    response.code.should == '200'
  end  
end