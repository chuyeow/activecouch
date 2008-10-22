require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #count_all method with multiple documents in the CouchDB database" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984'
      
      has :first_name
      has :last_name
    end
    
    # Create the database first
    ActiveCouch::Exporter.create_database('http://localhost:5984', 'people')
    # Save two objects
    Person.create(:last_name => 'McLovin', :first_name => 'Seth')
    Person.create(:last_name => 'McLovin', :first_name => 'Bob')
  end
  
  after(:each) do
    # Delete the database last
    ActiveCouch::Exporter.delete_database('http://localhost:5984', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should find all objects in the database when find method is sent the param :all" do
    count = Person.count_all
    count.should == 2
  end
end
