require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "ActiveCouch::Migration #view_js method" do
  before(:each) do
    class ByName < ActiveCouch::Migration
      define :by_name, :for_db => 'people' do
        with_key 'name'
      end
    end
  end
  
  it "should generate the correct javascript to be used in the view" do
    (ByName.view_js =~ /map\(doc\.name, doc\);/).should_not == nil
  end
end

describe "ActiveCouch::Migration #view_js method while calling the with_key and with_filter methods" do
  before(:each) do
    class ByLatitude < ActiveCouch::Migration
      define :for_db => 'hotels' do
        with_key 'latitude'
        with_filter 'doc.name == "Hilton"'
      end
    end
  end
  
  it "should generate the correct javascript to be used in the view" do
    (ByLatitude.view_js =~ /map\(doc\.latitude, doc\);/).should_not == nil
    (ByLatitude.view_js =~ /if\(doc\.name == \\"Hilton\\"\)/).should_not == nil
  end
end

describe "A subclass of ActiveCouch::Migration while calling with_key and include_attributes method" do
  before(:each) do
    class ByLongitude < ActiveCouch::Migration
      define :for_db => 'hotels' do
        with_key 'latitude'
        include_attributes :name, :rating, :latitude, :longitude, :address
      end
    end
  end

  it "should generate the correct javascript which will be used in the permanent view" do
    (ByLongitude.view_js =~ /map\(doc\.latitude, \{name: doc\.name , rating: doc\.rating , latitude: doc\.latitude , longitude: doc\.longitude , address: doc\.address\}\);/).should_not == nil
  end
end