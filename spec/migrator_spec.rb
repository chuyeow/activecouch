require File.dirname(__FILE__) + '/spec_helper.rb'

require 'net/http'
require 'uri'

describe "An ActiveCouch::Migrator class" do
  after(:each) do
    # TODO: Do not have dependency on delete_database to test create_database
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'ac_test_1')
  end
  
  it "should create a database when sent the create_database method" do
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test_1').should == true
  end
end

describe "An ActiveCouch::Migrator class" do
  before(:each) do
    # TODO: Do not have dependency on create_database to test delete_database
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test_2')
  end
  
  it "should delete a database successfully when sent the delete_database method" do
    ActiveCouch::Migrator.delete_database('http://localhost:5984', 'ac_test_2').should == true
  end
end

describe "An ActiveCouch::Migrator class" do
  before(:each) do
    class ByFace < ActiveCouch::Migration
      define :for_db => 'ac_test_3' do
        with_key 'face'
      end
    end

    
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test_3')
  end
  
  after(:each) do
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'ac_test_3')
  end
  
  it "should be able to create a permanent view when sent the migrate method" do
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
  end  
end