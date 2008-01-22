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

describe "ActiveCouch::Base #find method with multiple documents in the CouchDB database" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984'
      
      has :first_name
      has :last_name
    end
    
    # Define the migration
    class ByLastName < ActiveCouch::Migration
      define :for_db => 'people' do
        with_key 'last_name'
      end
    end
    # Create the database first
    ActiveCouch::Migrator.create_database('http://localhost:5984', 'people')
    # Create a view
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByLastName)
    # Save two objects
    Person.create(:last_name => 'McLovin', :first_name => 'Seth')
    Person.create(:last_name => 'McLovin', :first_name => 'Bob')
  end
  
  after(:each) do
    # Delete the database last
    ActiveCouch::Migrator.delete_database('http://localhost:5984', 'people')    
  end
  
  it "should find all objects in the database when find method is sent the param :all" do
    people = Person.find(:all, :params => {:last_name => 'McLovin'})
    # Check if it is an array and if the size is 2
    people.class.should == Array
    people.size.should == 2
    # The id's and rev's for all the objects must not be nil
    people.each do |p|
      p.id.should_not == nil
      p.rev.should_not == nil
    end
  end

  it "should find only the first object in the database when find method is sent with the param :first" do
    people = Person.find(:first, :params => {:last_name => 'McLovin'})
    # Check if this is a Person and if the size is 1
    people.class.should == Person
  end
end

describe "ActiveCouch::Base #find method with an object which has associations" do
  before(:each) do
    class Comment < ActiveCouch::Base
      site 'http://localhost:5984'
      has :body
    end

    class Blog < ActiveCouch::Base
      site 'http://localhost:5984'
      has :title
      has_many :comments
    end
      
    # Define the migration
    class ByTitle < ActiveCouch::Migration
      define :for_db => 'blogs' do
        with_key 'title'
      end
    end
    
    # Create the database first
    ActiveCouch::Migrator.create_database('http://localhost:5984', 'blogs')
    # Create a view
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByTitle)
    blog = Blog.new(:title => 'iPhone in Singapore')
    # Associations
    blog.add_comment(Comment.new(:body => 'soon plz'))
    blog.add_comment(Comment.new(:body => 'ya rly!'))
    # Save the blog
    blog.save
  end
  
  after(:each) do
    # Create the database first
    ActiveCouch::Migrator.delete_database('http://localhost:5984', 'blogs')
  end
  
  it "should be able to retrieve the simple attributes" do
    blog = Blog.find(:first, :params => {:title => 'iPhone in Singapore'})
    blog.title.should == 'iPhone in Singapore'
  end
  
  it "should be able to retrieve associations" do
    blog = Blog.find(:first, :params => {:title => 'iPhone in Singapore'})
    blog.comments.size.should == 2
    # Check whether the bodies of the comments exist
    (blog.comments.inspect =~ /soon plz/).should_not == nil
    (blog.comments.inspect =~ /ya rly!/).should_not == nil
  end
  
end