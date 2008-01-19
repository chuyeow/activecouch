require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Migration #include_attributes method" do
  it "should set the attrs instance variable to an array, if passed a multi-element array" do
    class ByLongitude < ActiveCouch::Migration
      define :for_db => 'hotels' do
        include_attributes :name, :rating, :latitude, :longitude, :address
      end
    end
    ByLongitude.instance_variable_get("@attrs").should == [:name, :rating, :latitude, :longitude, :address]
  end

  it "should set the attrs instance variable correctly, if passed a single-element array" do
    class ByLongitude < ActiveCouch::Migration
      define :for_db => 'hotels' do
        include_attributes :name
      end
    end
    ByLongitude.instance_variable_get("@attrs").should == [:name]
  end
  
  it "should set the attrs instance variable to an empty array, if not passed an array" do
    class ByLongitude < ActiveCouch::Migration
      define :for_db => 'hotels' do
        include_attributes {}
      end
    end
    ByLongitude.instance_variable_get("@attrs").should == []
  end
end