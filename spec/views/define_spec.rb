require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::View #define method" do
  it "should set @name and @database correctly if the first param is a String/Symbol" do
    class ByName < ActiveCouch::View
      define :by_name, :for_db => 'people', :is_alpha => true
    end

    ByName.instance_variable_get("@name").should == 'by_name'
    ByName.instance_variable_get("@database").should == 'people'
    ByName.instance_variable_get("@is_alpha").should == true
  end

  it "should set @is_alpha to false if nothing is specified" do
    class ByAge < ActiveCouch::View
      define :by_age, :for_db => 'people'
    end

    ByAge.instance_variable_get("@name").should == 'by_age'
    ByAge.instance_variable_get("@database").should == 'people'
    ByAge.instance_variable_get("@is_alpha").should == false
  end

  it "should set @name correctly if the first param passed is not a String/Symbol" do
    class ByFace < ActiveCouch::View
      define :for_db => 'people'
    end

    ByFace.instance_variable_get("@name").should == 'by_face'
    ByFace.instance_variable_get("@database").should == 'people'
    ByFace.instance_variable_get("@is_alpha").should == false
  end
  
  it "should raise an exception if neither the view nor the database is given as parameters" do
    lambda {
      class Test < ActiveCouch::View; define; end
    }.should raise_error(ArgumentError, 'Wrong arguments used to define the view')
  end
end

  