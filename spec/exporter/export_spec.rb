require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'net/http'
require 'uri'

# Needed to pass specs successfully
IS_ALPHA = ENV['COUCHDB_IS_ALPHA'] == 'true'

describe ActiveCouch::Exporter, "#export (that actually connects to a CouchDB server)" do
  before(:each) do
    class ByFace < ActiveCouch::View
      define :for_db => 'ac_test_3', :is_alpha => IS_ALPHA do
        with_key 'face'
      end
    end

    ActiveCouch::Exporter.create_database('http://localhost:5984/', 'ac_test_3')
  end

  after(:each) do
    ActiveCouch::Exporter.delete_database('http://localhost:5984/', 'ac_test_3')
  end

  it "should be able to create a permanent view when sent the migrate method" do
    ActiveCouch::Exporter.export('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
  end
end

describe ActiveCouch::Exporter, "#migrate with site and migration" do
  before(:all) do
    class ByFace < ActiveCouch::View
      define :for_db => 'test_db', :is_alpha => IS_ALPHA do
        with_key 'face'
      end
    end
  end

  before(:each) do
    @conn = mock(ActiveCouch::Connection)
    @response = mock(Object, :code => '201')
  end

  after(:all) do
    Object.send :remove_const, :ByFace
  end

  def mock_connection_and_response(options = {})
    ByFace.should_receive(:view).any_number_of_times.and_return('by_face')
    ByFace.should_receive(:to_json).any_number_of_times.and_return('{ "some" => "view json" }')

    ActiveCouch::Connection.should_receive(:new).with(options[:site]).and_return(@conn)
    @conn.should_receive(:put).with('/test_db/_design/by_face', '{ "some" => "view json" }').and_return(@response)
  end

  it "should create a new Connection to the given site and send a PUT to the view URL" do
    ByFace.should_receive(:view).any_number_of_times.and_return('by_face')
    ByFace.should_receive(:to_json).any_number_of_times.and_return('{ "some" => "view json" }')

    ActiveCouch::Connection.should_receive(:new).with('http://test.host:5984/').and_return(@conn)
    @conn.should_receive(:put).with('/test_db/_design/by_face', '{ "some" => "view json" }').and_return(@response)

    ActiveCouch::Exporter.export('http://test.host:5984/', ByFace)
  end

  it "should return true if the response code is HTTP status 201" do
    mock_connection_and_response(:site => 'http://test.host:5984/')
    @response.should_receive(:code).any_number_of_times.and_return('201')

    ActiveCouch::Exporter.export('http://test.host:5984/', ByFace).should == true
  end

  it "should raise an ActiveCouch::ViewError if the response code is not HTTP status 201" do
    mock_connection_and_response(:site => 'http://test.host:5984/')
    @response.should_receive(:code).any_number_of_times.and_return('500')

    lambda {
      ActiveCouch::Exporter.export('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::ViewError)
  end

  it "should raise an ActiveCouch::ViewError if the migration has no view" do
    ByFace.should_receive(:name).and_return(nil)

    lambda {
      ActiveCouch::Exporter.export('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::ViewError)
  end

  it "should raise an ActiveCouch::ViewError if the migration has no database" do
    ByFace.should_receive(:database).and_return(nil)

    lambda {
      ActiveCouch::Exporter.export('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::ViewError)
  end
end