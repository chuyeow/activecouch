require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Migration #define method" do
  it "should set @view and @database correctly if the first param is a String/Symbol" do
    class ByName < ActiveCouch::Migration
      define :by_name, :for_db => 'people'
    end

    ByName.instance_variable_get("@view").should == 'by_name'
    ByName.instance_variable_get("@database").should == 'people'
  end

  it "should set @view correctly if the first param passed is not a String/Symbol" do
    class ByFace < ActiveCouch::Migration
      define :for_db => 'people'
    end

    ByFace.instance_variable_get("@view").should == 'by_face'
    ByFace.instance_variable_get("@database").should == 'people'
  end
  
  it "should raise an exception if neither the view nor the database is given as parameters" do
    lambda {
      class Test < ActiveCouch::Migration; define; end
    }.should raise_error(ArgumentError, 'Wrong arguments used to define the view')
  end
end

  