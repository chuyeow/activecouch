require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #find method with just simple attributes" do
  before(:each) do
    # Define the model
    class Person < ActiveCouch::Base
      site 'http://localhost:5984'
      has :name
    end
    # Define the migration
    class ByName < ActiveCouch::Migration
      define :for_db => 'people' do
        with_key 'name'
      end
    end
    # Create the database first
    ActiveCouch::Migrator.create_database('http://localhost:5984', 'people')
    # Create a view
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByName)
    # Save an object
    Person.new(:name => 'McLovin').save
  end

  after(:each) do
    # Delete the database last
    ActiveCouch::Migrator.delete_database('http://localhost:5984', 'people')
  end

  it "should respond to the find method" do
    Person.should respond_to(:find)
  end

  it "should return an array with one Person object in it, when sent method find with parameter :all" do
    people = Person.find(:all, :params => {:name => 'McLovin'})
    people.class.should == Array
    # Size of people
    people.size.should == 1
    
    people.first.class.should == Person
    people.first.name.should == 'McLovin'
    # Check if id and rev are set
    people.first.id.should_not == nil
    people.first.rev.should_not == nil
  end

  it "should return one Person object when sent method find with parameter :one" do
    person = Person.find(:first, :params => {:name => 'McLovin'})
    person.class.should == Person
    person.name.should == 'McLovin'
    # Check if id and rev are set
    person.id.should_not == nil
    person.rev.should_not == nil
  end

  it "should return an empty array when sent method find with parameter :all and is not able to find any" do
    people = Person.find(:all, :params => {:name => 'Seth'})
    people.class.should == Array
    people.size.should == 0
  end

  it "should return a nil object when sent method find with parameter :first and is not able to find any" do
    person = Person.find(:first, :params => {:name => 'Seth'})
    person.should == nil
  end
end