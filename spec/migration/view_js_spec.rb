require File.dirname(__FILE__) + '/../spec_helper.rb'

# Needed to pass specs successfully
IS_ALPHA = ENV['COUCHDB_IS_ALPHA'] == 'true'

describe "ActiveCouch::Migration #view_js method" do
  before(:each) do
    class ByName < ActiveCouch::Migration
      define :by_name, :for_db => 'people', :is_alpha => IS_ALPHA do
        with_key 'name'
      end
    end
  end
  
  it "should generate the correct javascript to be used in the view" do
    if IS_ALPHA
      (ByName.view_js =~ /map\(doc\.name, doc\);/).should_not == nil
    else
      (ByName.view_js =~ /emit\(doc\.name, doc\);/).should_not == nil
    end
  end
end

describe "ActiveCouch::Migration #view_js method while calling the with_key and with_filter methods" do
  before(:each) do
    class ByLatitude < ActiveCouch::Migration
      define :for_db => 'hotels', :is_alpha => IS_ALPHA do
        with_key 'latitude'
        with_filter 'doc.name == "Hilton"'
      end
    end
  end
  
  it "should generate the correct javascript to be used in the view" do
    if IS_ALPHA
      (ByLatitude.view_js =~ /map\(doc\.latitude, doc\);/).should_not == nil
    else
      (ByLatitude.view_js =~ /emit\(doc\.latitude, doc\);/).should_not == nil
    end
    
    (ByLatitude.view_js =~ /if\(doc\.name == \\"Hilton\\"\)/).should_not == nil
  end
end

describe "A subclass of ActiveCouch::Migration while calling with_key and include_attributes method" do
  before(:each) do
    class ByLongitude < ActiveCouch::Migration
      define :for_db => 'hotels', :is_alpha => IS_ALPHA do
        with_key 'latitude'
        include_attributes :name, :rating, :latitude, :longitude, :address
      end
    end
  end

  it "should generate the correct javascript which will be used in the permanent view" do
    if IS_ALPHA
      (ByLongitude.view_js =~ /map\(doc\.latitude, \{name: doc\.name , rating: doc\.rating , latitude: doc\.latitude , longitude: doc\.longitude , address: doc\.address\}\);/).should_not == nil
    else
      (ByLongitude.view_js =~ /emit\(doc\.latitude, \{name: doc\.name , rating: doc\.rating , latitude: doc\.latitude , longitude: doc\.longitude , address: doc\.address\}\);/).should_not == nil      
    end
  end
end