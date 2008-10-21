require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #after_save method" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :saved_revision
      # Callback, after the actual save happens
      after_save :print_message
      
      private
        def print_message
          # This can only be set if the object has been saved.
          # Otherwise it will be nil
          self.saved_revision = self.rev
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
  
  it "should have a class method called after_save" do
    Person.methods.include?('after_save').should == true
  end
  
  it "should call the method specified as an argument to after_save, *after* the object has been persisted in CouchDB" do
    p = Person.new(:name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and saved_id must not be nil (because it is set to the revision)
    p.saved_revision.should_not == nil
  end
end

describe "ActiveCouch::Base #after_save method with a block as argument" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :saved_revision
      # Callback, after the actual save happens
      after_save { |record| record.saved_revision = record.rev }
    end
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should execute the block as a param to after_save" do
    p = Person.new(:name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and saved_id must not be nil (because it is set to the revision)
    p.saved_revision.should_not == nil
  end
end

describe "ActiveCouch::Base #after_save method with an Object (which implements after_save) as argument" do
  before(:each) do
    class RevisionSetter
      def after_save(record)
        record.saved_revision = record.rev
      end
    end
    
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :name
      has :saved_revision
      # Callback, after the actual save happens
      after_save RevisionSetter.new
    end
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should call before_save in the object passed as a param to after_save" do
    p = Person.new(:name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and saved_id must not be nil (because it is set to the revision)
    p.saved_revision.should_not == nil
  end
end