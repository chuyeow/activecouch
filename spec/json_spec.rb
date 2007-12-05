require File.dirname(__FILE__) + '/spec_helper.rb'

class Person < ActiveCouch::Base
  has :name
end
class PersonWithName < ActiveCouch::Base
  has :name, :with_default_value => "McLovin"
end
class PersonWithTelephones < ActiveCouch::Base
  has_many :telephones
end
class PersonWithAttributes < ActiveCouch::Base
  has :first_name, :last_name, :age, :sex
  has_many :contacts
end

describe "An object which is a subclass of ActiveCouch::Base with some attributes instantiated" do
  before(:each) do
    @person_with_attribs = PersonWithAttributes.new
    @contact = PersonWithAttributes.new
    @dummy = PersonWithAttributes.new
    
    @contact.first_name = "Seth"
    
    @person_with_attribs.first_name = "McLovin"
    @person_with_attribs.contacts << @contact
  end
  
  it "should respond to to_json method" do
    @person_with_attribs.to_json.should == "{\"contacts\": [{\"first_name\": \"Seth\"}], \"first_name\": \"McLovin\"}"
  end
end