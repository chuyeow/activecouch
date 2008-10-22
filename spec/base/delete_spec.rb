require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #delete instance-level method" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
    end
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'good_people')
    
    @person = Person.create(:name => 'McLovin')
  end
  
  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'good_people')
    
    Object.send(:remove_const, :Person)
  end
  
  it "should have an instance method called delete" do
    @person.methods.include?('delete').should == true
  end
  
  it "should be able to delete itself from the CouchDB database and return true" do
    @person.delete.should == true
    @person.id.should == nil
    @person.rev.should == nil
    # Check whether document has actually been deleted
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/people/_all_docs/")
    response.body.index('"total_rows":0').should_not == nil
  end
  
  it "should raise an error if the revision for the object is not set and is attempted to be deleted" do
    p = Person.new(:name => 'McLovin')
    lambda { p.delete }.should raise_error(ArgumentError, "You must specify a revision for the document to be deleted")
  end
  
  it "should raise an error if the id for the object is not set, but the revision is set and is attempted to be deleted" do
    p = Person.new(:name => 'McLovin')
    p.rev = '123'
    lambda { p.delete }.should raise_error(ArgumentError, "You must specify an ID for the document to be deleted")
  end
  
  it "should be able to accept a from_database option which will delete it from the right database" do
    p = Person.new(:name => 'McLovin')
    p.save(:to_database => 'good_people')
    p.delete(:from_database => 'good_people').should == true
    
    p.id.should == nil
    p.rev.should == nil
    
    # Check whether document has actually been deleted
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/good_people/_all_docs/")
    response.body.index('"total_rows":0').should_not == nil
  end
end

describe "ActiveCouch::Base #delete class-level method" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
    end
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
    @person = Person.create(:name => 'McLovin')
  end

  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should have a class method called delete" do
    Person.methods.include?('delete').should == true
  end
  
  it "should be able to delete a CouchDB document and return true after successful deletion" do
    Person.delete(:id => @person.id, :rev => @person.rev).should == true
    # Check whether document has actually been deleted
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/people/_all_docs/")
    response.body.index('"total_rows":0').should_not == nil
  end
  
  it "should raise an error if the id is not specified in the options hash" do
    lambda { Person.delete(:rev => 'abc') }.should raise_error(ArgumentError, "You must specify both an id and a rev for the document to be deleted")
  end

  it "should raise an error if the rev is not specified in the options hash" do
    lambda { Person.delete(:id => 'abc') }.should raise_error(ArgumentError, "You must specify both an id and a rev for the document to be deleted")
  end
  
  it "should raise an error if a nil object is passed as a param to delete" do
    lambda { Person.delete(nil) }.should raise_error(ArgumentError, "You must specify both an id and a rev for the document to be deleted")
  end
end