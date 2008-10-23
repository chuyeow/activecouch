require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #find method with multiple documents in the CouchDB database" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984'
      
      has :first_name
      has :last_name
    end
    
    # Define the migration
    class ByLastName < ActiveCouch::View
      define :for_db => 'people' do
        with_key 'last_name'
      end
    end
    # Create the database first
    ActiveCouch::Exporter.create_database('http://localhost:5984', 'people')
    # Create a view
    ActiveCouch::Exporter.export('http://localhost:5984', ByLastName)
    # Save two objects
    Person.create(:last_name => 'McLovin', :first_name => 'Seth')
    Person.create(:last_name => 'McLovin', :first_name => 'Bob')
    Person.create(:id => '123', :last_name => 'McLovin', :first_name => 'Portnoy')
  end
  
  after(:each) do
    # Delete the database last
    ActiveCouch::Exporter.delete_database('http://localhost:5984', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should find all objects in the database when find_from_url method is used" do
    people = Person.find_from_url("/people/_view/by_last_name/by_last_name?key=%22McLovin%22")
    # Check if it is an array and if the size is 2
    people.class.should == Array
    people.size.should == 3
    # The id's and rev's for all the objects must not be nil
    people.each do |p|
      p.id.should_not == nil
      p.rev.should_not == nil
    end
  end

  it "should fetch a single object from a URL if the URL specified is not accessing a view" do
    person = Person.find_from_url("/people/123")
    person.class.should == Person
    person.last_name.should == 'McLovin'
    person.first_name.should == 'Portnoy'
    
    Person.find_from_url("/people/345").should == nil
  end

end
