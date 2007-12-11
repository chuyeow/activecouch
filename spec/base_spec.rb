require File.dirname(__FILE__) + '/spec_helper.rb'

class Person < ActiveCouch::Base
  has :name, :which_is => :text
end

class NamedPerson < ActiveCouch::Base
  has :name, :which_is => :text, :with_default_value => "McLovin"
end

class AgedPerson < ActiveCouch::Base
  has :name
  has :age, :which_is => :number, :with_default_value => 10
end

class Contact < ActiveCouch::Base
  has_many :people
end

describe "A class which is a subclass of ActiveCouch::Base" do
  before(:each) do
    @p = Person.new
  end
  
  it "should have an instance variable called attributes which is a Hash with the key being :name" do
    Person.attributes.class.should == Hash
    Person.attributes.keys.should == [:name]
  end
  
  it "should have a method called name which returns the value of the variable name" do
    @p.methods.index('name').should_not == nil
    @p.name.should == ""
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @p.methods.index('name=').should_not == nil
    @p.name = "McLovin"
    @p.name.should == "McLovin"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default value specified" do
  before(:each) do
    @n = NamedPerson.new
  end
  
  it "should have an instance variable called attributes which is a Hash with the key being :name" do
    NamedPerson.attributes.class.should == Hash
    NamedPerson.attributes.keys.should == [:name]
  end
  
  it "should have a method called name which returns the value of the variable name" do
    @n.methods.index('name').should_not == nil
    @n.name.should == "McLovin"
  end
  
  it "should have a method called name= which should let you set the instance variable name" do
    @n.methods.index('name=').should_not == nil
    @n.name = "Seth"
    @n.name.should == "Seth"
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a default numerical value specified" do
  before(:each) do
    @a = AgedPerson.new
  end

  it "should have an instance variable called attributes which is a Hash with the keys being :name, :age" do
    AgedPerson.attributes.class.should == Hash
    AgedPerson.attributes.keys.index(:name).should_not == nil
    AgedPerson.attributes.keys.index(:age).should_not == nil
  end

  it "should have methods called name and age which return the values of the variables name and age respectively" do
    @a.methods.index('name').should_not == nil
    @a.methods.index('age').should_not == nil
    
    @a.name.should == ""
    @a.age.should == 10
  end

  it "should have a method called name= which should let you set the instance variable name" do
    @a.methods.index('name=').should_not == nil
    @a.methods.index('age=').should_not == nil
    
    @a.age = 15
    @a.age.should == 15
  end
end

describe "A class which is a subclass of ActiveCouch::Base with a has_many association" do
  before(:each) do
    @c = Contact.new
    @p1 = Person.new
    @a1 = AgedPerson.new
  end
  
  it "should have an instance variable called associations which is a Hash with the key being :people" do
    Contact.associations.class.should == Hash
    Contact.associations.keys.should == [:people]
  end
  
  it "should have methods called people and add_person" do
    @c.methods.index('people').should_not == nil
    @c.methods.index('add_person').should_not == nil
  end
  
  it "should have a method called people which returns an empty array" do
    @c.people.should == []
  end
  
  it "should be able to add a Person object to the association" do
    @c.add_person(@p1)
    @c.people.should == [@p1]
  end
  
  it "should raise an error when trying to add an object which is not of the association's type" do
    lambda{ @c.add_person(@a1) }.should raise_error(ActiveCouch::InvalidCouchTypeError)
  end
end