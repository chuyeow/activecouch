require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "A Cheezburger subclass of ActiveCouch::Base nested in a Lolcat subclass of ActiveCouch::Base" do
  before(:all) do
    class Lolcat < ActiveCouch::Base
      class Cheezburger < ActiveCouch::Base
      end
    end
  end

  it "should have a base_class of Lolcat::Cheezburger" do
    Lolcat.base_class.should == Lolcat
    Lolcat::Cheezburger.base_class.should == Lolcat::Cheezburger
  end

  it "should have a database_name of lolcat_cheezburger" do
    Lolcat::Cheezburger.database_name.should == 'lolcat_cheezburgers'
  end
end