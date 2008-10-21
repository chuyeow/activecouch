require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #create method" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
    end
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should have a class method called create" do
    Person.methods.include?('create').should == true
  end
  
  it "should be able to persist itself in the CouchDB database" do
    person = Person.create(:name => 'McLovin')
    person.name.should == 'McLovin'
    # Check whether document is persisted correctly in the database
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/people/_all_docs/")
    response.body.index('"total_rows":1').should_not == nil
  end
end