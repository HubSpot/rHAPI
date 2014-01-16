require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Configuration" do
  before do
    RHapi.configure do |config|
      config.api_key = "123"
      config.end_point = "https://mysite.com"
      config.hub_spot_site = "http://mysite.hubspot.com"
      config.version = "v2"
    end
  end
  
  it "sets the api key" do
    RHapi.options[:api_key].should == "123"
  end
  
  it "sets the endpoint" do
    RHapi.options[:end_point].should == "https://mysite.com"
  end
  
  it "sets the hub_spot_site" do
    RHapi.options[:hub_spot_site].should == "http://mysite.hubspot.com"
  end
  
  it "sets the version" do
    RHapi.options[:version].should == "v2"
  end
  
  it "resets to the default values" do
    RHapi.reset
    RHapi.options[:api_key].should == nil
    RHapi.options[:end_point].should == "https://api.hubapi.com"
    RHapi.options[:hub_spot_site].should == nil
    RHapi.options[:version].should == "v1"
    RHapi.options[:api_timeout].should == 0.4
  end
end
