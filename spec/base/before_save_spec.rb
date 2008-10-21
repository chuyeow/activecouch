require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Base #before_save method with a Symbol as argument" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :first_name
      has :last_name
      # Callback, before the actual save happens
      before_save :set_first_name
      
      private
        def set_first_name
          self.first_name = 'Seth'
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
  
  it "should have a class method called before_save" do
    Person.methods.include?('before_save').should == true
  end
  
  it "should call the method specified as an argument to before_save, *before* the object has been persisted in CouchDB" do
    p = Person.new(:last_name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and the first_name must be set to 'Seth'
    p.first_name.should == 'Seth'
  end
end

describe "ActiveCouch::Base #before_save method with a block as argument" do
  before(:each) do
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :first_name; has :last_name
      # Callback, before the actual save happens
      before_save { |record| record.first_name = 'Seth' }
    end
    
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should execute the block as a param to before_save" do
    p = Person.new(:last_name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and the first_name must be set to 'Seth'
    p.first_name.should == 'Seth'
  end
end

describe "ActiveCouch::Base #before_save method with an Object (which implements before_save) as argument" do
  before(:each) do
    class NameSetter
      def before_save(record)
        record.first_name = 'Seth'
      end
    end
    
    class Person < ActiveCouch::Base
      site 'http://localhost:5984/'
      has :first_name; has :last_name
      # Callback, before the actual save happens
      before_save NameSetter.new
    end
    
    # Migration needed for this spec
    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'people')
  end
  
  after(:each) do
    # Migration needed for this spec    
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'people')
    Object.send(:remove_const, :Person)
  end
  
  it "should call before_save in the object passed as a param to before_save" do
    p = Person.new(:last_name => 'McLovin')
    # Save should return true...
    p.save.should == true
    # ...and the first_name must be set to 'Seth'
    p.first_name.should == 'Seth'
  end
      
end