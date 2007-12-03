require File.dirname(__FILE__) + '/spec_helper.rb'

class SimpleActiveCouch < ActiveCouch::Base; end
class Person < ActiveCouch::Base
  has :name
end
class PersonWithName < ActiveCouch::Base
  has :name, :with_default_value => "John Doe"
end
class PersonWithTelephones < ActiveCouch::Base
  has_many :telephones
end

describe "A subclass of ActiveCouch::Base" do
  before(:each) do
    @subclass = SimpleActiveCouch
  end

  it "should raise an ArgumentError when sent #has with an argument that is not a Symbol or String" do
    lambda { @subclass.has(:foo, []) }.should raise_error(ArgumentError)
  end

  it "should define attribute accessors when sent #has with a symbol as parameter" do
    @subclass.has(:name)

    @subclass.instance_methods.should include('name', 'name=')
  end

  it "should set the empty string as the attribute value by default when sent #has with no :with_default_value option" do
    @subclass.has(:name)

    @subclass.new.name.should == ''
  end
end

describe "An object created as a subclass of ActiveCouch::Base with one text attribute" do
  before(:each) do
    @person = Person.new
  end

  it "should be able to assign a value to the instance variable defined using the has class method" do
    @person.name.should == ""
    @person.name = "John Doe"
    @person.name.should == "John Doe"
  end
end

describe "An object created as a subclass of ActiveCouch::Base with one text attribute (with default value set)" do
  before(:each) do
    @person_with_name = PersonWithName.new
  end
  
  it "should create an instance variable with the correct default value set when sent #has with a symbol as parameter" do
    @person_with_name.name.should == "John Doe"
  end
end

describe "An object created as a subclass of ActiveCouch::Base with one array attribute" do
  before(:each) do
    @person_with_tels = PersonWithTelephones.new
  end
  
  it "should create an instance variable which is an empty array" do
    @person_with_tels.telephones.class.should == Array
    @person_with_tels.telephones.size.should == 0
  end
  
  it "should be able to add a value to the array" do
    @person_with_tels.telephones.size.should == 0
    @person_with_tels.telephones << "123-456-789"
    @person_with_tels.telephones.first.should == "123-456-789"
    @person_with_tels.telephones.size.should == 1
  end
end