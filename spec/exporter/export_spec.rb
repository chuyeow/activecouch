require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'net/http'
require 'uri'

describe ActiveCouch::Exporter, "#export (that actually connects to a CouchDB server)" do
  before(:each) do
    class ByFace < ActiveCouch::View
      define :for_db => 'ac_test_3' do
        with_key 'face'
      end
    end

    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'ac_test_3')
  end

  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'ac_test_3')
  end

  it "should be able to create a permanent view when sent the export method" do
    ActiveCouch::Exporter.export('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
  end
end

describe ActiveCouch::Exporter, "#export twice (that actually connects to a CouchDB server)" do
  before(:each) do
    class ByFace < ActiveCouch::View
      define :for_db => 'ac_test_3' do
        with_key 'face'
      end
    end

    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'ac_test_3')
  end

  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'ac_test_3')
  end

  it "should be able to create a permanent view when sent the export method, after the view has already been saved" do
    ActiveCouch::Exporter.export('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
    

    ActiveCouch::Exporter.export('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
  end
end