require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "An object instantiated from the subclass of ActiveCouch::Base" do
  before(:all) do
    class Person < ActiveCouch::Base
      has :name, :which_is => :text
    end
    @person = Person.new
  end

  after(:all) do
    Object.send(:remove_const, :Person)
  end  

  it "should have accessors for the id attribute" do
    @person.should respond_to(:id)
    @person.should respond_to(:id=)
  end

  it "should be able to set and retrieve the id variable" do
    @person.id = 'abc-def'
    @person.id.should == 'abc-def'
  end

end