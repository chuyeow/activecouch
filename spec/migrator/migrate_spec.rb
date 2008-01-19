require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'net/http'
require 'uri'

describe ActiveCouch::Migrator, "#migrate (that actually connects to a CouchDB server)" do
  before(:each) do
    class ByFace < ActiveCouch::Migration
      define :for_db => 'ac_test_3' do
        with_key 'face'
      end
    end

    ActiveCouch::Migrator.create_database('http://localhost:5984/', 'ac_test_3')
  end

  after(:each) do
    ActiveCouch::Migrator.delete_database('http://localhost:5984/', 'ac_test_3')
  end

  it "should be able to create a permanent view when sent the migrate method" do
    ActiveCouch::Migrator.migrate('http://localhost:5984', ByFace).should == true
    # This is the view document. To actually query this particular view, the URL to be used
    # is http://#{host}:#{port}/ac_test_1/_view/by_face/by_face 
    # A little unwieldy I know, but the point of ActiveCouch is to abstract this unwieldiness
    response = Net::HTTP.get_response URI.parse("http://localhost:5984/ac_test_3/_design/by_face")
    response.code.should == '200'
  end
end

describe ActiveCouch::Migrator, "#migrate with site and migration" do
  before(:all) do
    class ByFace < ActiveCouch::Migration
      define :for_db => 'test_db' do
        with_key 'face'
      end
    end
  end

  before(:each) do
    @conn = mock(ActiveCouch::Connection)
  end

  after(:all) do
    Object.send :remove_const, :ByFace
  end

  def mock_connection_and_response(options = {})
    ByFace.should_receive(:view).any_number_of_times.and_return('by_face')
    ByFace.should_receive(:view_js).any_number_of_times.and_return('{ "some" => "view json" }')

    ActiveCouch::Connection.should_receive(:new).with(options[:site]).and_return(@conn)
    @conn.should_receive(:put).with('/test_db/_design/by_face', '{ "some" => "view json" }').and_return(@response)
  end

  it "should create a new Connection to the given site and send a PUT to the view URL" do
    @response = mock(Object, :code => '201')

    ByFace.should_receive(:view).any_number_of_times.and_return('by_face')
    ByFace.should_receive(:view_js).any_number_of_times.and_return('{ "some" => "view json" }')

    ActiveCouch::Connection.should_receive(:new).with('http://test.host:5984/').and_return(@conn)
    @conn.should_receive(:put).with('/test_db/_design/by_face', '{ "some" => "view json" }').and_return(@response)

    ActiveCouch::Migrator.migrate('http://test.host:5984/', ByFace)
  end

  it "should return true if the response code is HTTP status 201" do
    mock_connection_and_response(:site => 'http://test.host:5984/')
    @response.should_receive(:code).any_number_of_times.and_return('201')

    ActiveCouch::Migrator.migrate('http://test.host:5984/', ByFace).should == true
  end

  it "should raise an ActiveCouch::MigrationError if the response code is not HTTP status 201" do
    mock_connection_and_response(:site => 'http://test.host:5984/')
    @response.should_receive(:code).any_number_of_times.and_return('500')

    lambda {
      ActiveCouch::Migrator.migrate('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::MigrationError)
  end

  it "should raise an ActiveCouch::MigrationError if the migration has no view" do
    ByFace.should_receive(:view).and_return(nil)

    lambda {
      ActiveCouch::Migrator.migrate('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::MigrationError)
  end

  it "should raise an ActiveCouch::MigrationError if the migration has no database" do
    ByFace.should_receive(:database).and_return(nil)

    lambda {
      ActiveCouch::Migrator.migrate('http://test.host:5984/', ByFace)
    }.should raise_error(ActiveCouch::MigrationError)
  end
end