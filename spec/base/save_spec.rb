require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A Person subclass of ActiveCouch::Base" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
    end
    # Create a database called people
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Delete after we're done
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
   
  it "should have an instance method called save" do
    Person.new.methods.include?('save').should == true
  end
    
  it "should be able to persist itself in the CouchDB database" do
    person = Person.new(:name => 'McLovin')
    person.save.should == true
  end
end

describe "A new ActiveCouch::Base instance" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name, :which_is => :text
    end
    
    @person = Person.new(:name => 'Seth')
    # Create a database called people
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end

  after(:each) do
    # Delete after we're done
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end

  it "should be new" do
    @person.should be_new
  end

  it "should set the id and rev attributes after being saved" do
    @person.save
    
    @person.id.should_not == nil
    @person.rev.should_not == nil
    @person.should_not be_new
  end

  it "should allow you to set the id attribute, and the id must be reflected in the object after saving" do
    @person.id = 'abc_def'
    @person.save
    
    @person.id.should == 'abc_def'
  end
  
  it "should be allowed to save to a database with a name which does not correspond to the name of the class" do
    
  end
  
end

describe "A new ActiveCouch::Base instance" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name, :which_is => :text
    end
    
    @person = Person.new(:name => 'Seth')
    # Create a database called people
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'good_people')
  end

  after(:each) do
    # Delete after we're done
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'good_people')
    Object.send(:remove_const, :Person)
  end

  it "should be new" do
    @person.should be_new
  end

  it "should be allowed to save to a database with a name which does not correspond to the name of the class" do
    @person.save(:to_database => 'good_people')
    
    @person.id.should_not == nil
    @person.rev.should_not == nil
    @person.should_not be_new
  end
  
end

describe "A new ActiveCouch::Base instance" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name, :which_is => :text
    end

    @person = Person.new(:name => 'Seth')
    # Create a database called people
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
    # Save the document
    @person.save
  end

  after(:each) do
    # Delete after we're done
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end

  it "should be allowed to update a field and save again" do
    @person.name = "McLovin"
    @person.save.should == true
    
    @person.name.should == "McLovin"
  end
end