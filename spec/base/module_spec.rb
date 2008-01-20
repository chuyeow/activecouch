require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A Cheezburger subclass of ActiveCouch::Base defined in the Burgers module" do
  before(:all) do
    module Burgers
      class Cheezburger < ActiveCouch::Base
      end
    end
  end

  it "should have a base_class of Burgers::Cheezburger" do
    Burgers::Cheezburger.base_class.should == Burgers::Cheezburger
  end

  it "should have a database_name of cheezburgers" do
    Burgers::Cheezburger.database_name.should == 'cheezburgers'
  end
end