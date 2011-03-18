require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RHapi::Lead" do
  
  context "when searching for leads" do
    before do
      RHapi.configure do |config|
        config.api_key = test_config["api_key"]
        config.hub_spot_site = "http://mysite.hubspot.com"
      end
      stub_leads_search
    end
    
    # Most of the actual connections are mocked to spped tests.
    it "should return all leads with no search params" do
      leads = RHapi::Lead.find
      leads.length.should >= 1
    end
    
    it "should have a first_name attribute" do
      leads = RHapi::Lead.find
      leads.first.first_name.should == "Fred"
    end
    
    it "should set the value for a first name" do
      leads = RHapi::Lead.find
      lead = leads.first
      lead.first_name = "Barny"
      lead.first_name.should == "Barny" 
    end
    
    it "should have analytics details" do
      # Not sure yet how these will be used. I may want to make
      # attributes that are hashes or arrays seem more like lead attributes.
      leads = RHapi::Lead.find
      lead = leads.first
      lead.analytics_details.length.should == 12
      lead.analytics_details["allViewsImported"].should == true
    end
    
  end
  
  context "accessing leads with incorrect API key" do
    before do
     RHapi.configure do |config|
        config.api_key = "badapikey"
        config.hub_spot_site = "http://mysite.hubspot.com"
      end
    end
    
    it "should raise an exception" do
      stub_leads_error
      lambda {RHapi::Lead.find}.should raise_error(RHapi::RHapiException)
    end
  end
  
  
end
