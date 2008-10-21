require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #after_delete method" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :delete_status
      # Callback, after the actual save happens
      after_delete :print_message
      
      private
        def print_message
          self.delete_status = "Deleted McLovin"
        end
    end
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should have a class method called after_delete" do
    Person.methods.include?('after_delete').should == true
  end
  
  it "should call the method specified as an argument to after_delete, *after_delete* the object has been deleted from CouchDB" do
    p = Person.new(:name => 'McLovin')
    # First, it must be empty...
    p.delete_status.should == ""
    # then it must be saved...
    p.save
    # Delete should return true...
    p.delete.should == true
    p.delete_status.should == "Deleted McLovin"
  end
end

describe "ActiveCouch::Base #after_delete method with a block as argument" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :delete_status
      # Callback, after the actual save happens
      after_delete { |record| record.delete_status = 'Deleted McLovin' }
    end
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should execute the block as a param to after_delete" do
    p = Person.new(:name => 'McLovin')
    # First, it must be empty...
    p.delete_status.should == ""
    # then it must be saved...
    p.save
    # Delete should return true...
    p.delete.should == true
    # ...and then delete_status must be "Deleted McLovin"
    p.delete_status.should == "Deleted McLovin"
  end
end

describe "ActiveCouch::Base #after_save method with an Object (which implements after_save) as argument" do
  before(:each) do
    class DeleteStatusSetter
      def after_delete(record)
        record.delete_status = 'Deleted McLovin'
      end
    end
    
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :delete_status
      # Callback, after the actual save happens
      after_delete DeleteStatusSetter.new
    end
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should call before_save in the object passed as a param to after_delete" do
    p = Person.new(:name => 'McLovin')
    # First, it must be empty...
    p.delete_status.should == ""
    # then it must be saved...
    p.save
    # Delete should return true...
    p.delete.should == true
    p.delete_status.should == "Deleted McLovin"
  end  
end
