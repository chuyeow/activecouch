require File.dirname(__FILE__) + '/spec_helper.rb'

class Person < ActiveCouch::Base; end

describe "An ActiveCouch::HasManyAssociation object initialized with a name and with class set to Person" do
  before(:each) do
    @a = ActiveCouch::HasManyAssociation.new(:contacts, :class => Person)
  end
  
  it "should set the klass to Person name must be contacts" do
    @a.klass.should == Person
    @a.name.should == "contacts"
    @a.container.should == []
  end
end

describe "An ActiveCouch::HasManyAssociation object initialized with only a name" do
  before(:each) do
    @a = ActiveCouch::HasManyAssociation.new(:people)
  end
  
  it "should set the klass to Person name must be people" do
    @a.klass.should == Person
    @a.name.should == "people"
    @a.container.should == []
  end
end

describe "An ActiveCouch::HasManyAssociation object initialized with only a name (but for which a class is not defined)" do
  it "should raise a NameError" do
    lambda { ass.new(:contacts) }.should raise_error(NameError)
  end
end
