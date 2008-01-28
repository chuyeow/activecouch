require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A class which is a subclass of ActiveCouch::Base" do
  before(:each) do
    class Person < ActiveCouch::Base
      has :name, :which_is => :text
    end
    # Initialize a new Person object
    @p = Person.new
  end
  
  after(:each) do
    Object.send(:remove_const, :Person)
  end  
  
  it "should have a method called name which returns the value of the variable name" do
    @p.should respond_to(:name)
    @p.name.should == ""
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @p.should respond_to(:name=)
    @p.name = "McLovin"
    @p.name.should == "McLovin"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default value specified" do
  before(:each) do
    class NamedPerson < ActiveCouch::Base
      has :name, :which_is => :text, :with_default_value => "McLovin"
    end
    
    @n = NamedPerson.new
  end
  
  after(:each) do
    Object.send(:remove_const, :NamedPerson)
  end  
  
  it "should have a method called name which returns the value of the variable name" do
    @n.should respond_to(:name)
    @n.name.should == "McLovin"
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @n.should respond_to(:name=)
    @n.name = "Seth"
    @n.name.should == "Seth"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default numerical value specified" do
  before(:each) do
    class AgedPerson < ActiveCouch::Base
      has :name
      has :age, :which_is => :number, :with_default_value => 10
    end
    
    @a = AgedPerson.new
  end
  
  after(:each) do
    Object.send(:remove_const, :AgedPerson)
  end  

  it "should have an instance variable called attributes which is a Hash with the keys being :name, :age" do
    AgedPerson.attributes.class.should == Hash
    AgedPerson.attributes.keys.index(:name).should_not == nil
    AgedPerson.attributes.keys.index(:age).should_not == nil
  end

  it "should have methods called name and age which return the values of the variables name and age respectively" do
    @a.should respond_to(:name)
    @a.should respond_to(:age)

    @a.name.should == ""
    @a.age.should == 10
  end

  it "should have a method called name= which should let you set the instance variable name" do
    @a.should respond_to(:name=)
    @a.should respond_to(:age=)
    
    @a.age = 15
    @a.age.should == 15
  end
end