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

  it "should have reader/writer for the rev attribute" do
    @person.should respond_to(:rev)
    @person.should respond_to(:rev=)
  end
end