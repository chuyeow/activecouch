require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "An object instantiated from the subclass of ActiveCouch::Base" do
  before(:each) do
    class Person < ActiveCouch::Base
      has :name, :which_is => :text
    end
    
    @person = Person.new
  end

  it "should have a reader for the rev attribute" do
    @person.should respond_to(:rev)
  end
end