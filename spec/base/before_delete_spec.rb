require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #before_delete method with a Symbol as argument" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :age, :which_is => :number
      # Callback, before the actual save happens
      before_delete :zero_age
      
      private
        def zero_age
          self.age = 0
        end
    end
    # Migration needed for this spec
    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'people')
  end
  
  it "should have a class method called before_save" do
    Person.methods.include?('before_delete').should == true
  end
  
  it "should call the method specified as an argument to before_delete, *before* deleting the object from CouchDB" do
    # First save the object
    p = Person.create(:name => 'McLovin')
    p.age = 10
    # Before deleting, age must be 10
    p.age.should == 10
    # Delete the object, and...
    p.delete.should == true
    # ...age must equal 0
    p.age.should == 0
  end
end

describe "ActiveCouch::Base #before_save method with a block as argument" do
  it "should execute the block as a param to before_save"
end

describe "ActiveCouch::Base #before_save method with an Object (which implements before_save) as argument" do
  it "should call before_save in the object passed as a param to before_save" 
end