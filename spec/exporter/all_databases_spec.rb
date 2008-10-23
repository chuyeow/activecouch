require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'net/http'
require 'uri'

describe ActiveCouch::Exporter, "#all_databases (that actually connects to a CouchDB server)" do  
  before(:each) do
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'ac_test_1')
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'ac_test_2')    
  end
  
  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'ac_test_1')
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'ac_test_2')    
  end
  
  it "should list all databases currently in CouchDB" do
    databases = ActiveCouch::Exporter.all_databases('http://localhost:5984')
    databases.size.should == 2
    databases.include?('ac_test_1').should == true
    databases.include?('ac_test_2').should == true    
  end
end