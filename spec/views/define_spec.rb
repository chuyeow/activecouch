require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::View #define method" do
  it "should set @name and @database correctly if the first param is a String/Symbol" do
    class ByName < ActiveCouch::View
      define :by_name, :for_db => 'people'
    end

    ByName.instance_variable_get("@name").should == 'by_name'
    ByName.instance_variable_get("@database").should == 'people'
  end

  it "should set @name correctly if the first param passed is not a String/Symbol" do
    class ByFace < ActiveCouch::View
      define :for_db => 'people'
    end

    ByFace.instance_variable_get("@name").should == 'by_face'
    ByFace.instance_variable_get("@database").should == 'people'
  end
  
  it "should raise an exception if neither the view nor the database is given as parameters" do
    lambda {
      class Test < ActiveCouch::View; define; end
    }.should raise_error(ArgumentError, 'Wrong arguments used to define the view')
  end
end