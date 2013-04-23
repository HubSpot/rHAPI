# RHapi (Ruby HubSpot API Wrapper)

RHapi is a Ruby wrapper for the HubSpot API (HAPI).

## To do:

*   Add method to create new leads.
*   Build out methods for Blogs API.
*   Write documentation.


## Using RHapi 

Install  If you use RVM.
    gem install r_hapi

If not you may need to do this:
    sudo gem install r_hapi

First configure RHapi to work with your Hubspot API Key or oAuth access token.

    RHapi.configure do |config|
      config.api_key = "YOUR_API_KEY"
      config.access_token = "YOUR_ACCESS_TOKEN" # Takes precedence over api_key
    end

### Contacts API Examples

RHapi now supports all Hubspot Contact API methods.

#### Create a Contact

    RHapi::Contact.create('email' => 'user@example.com')

(Returns a new RHapi::Contact instance populated with values from Hubspot)

You may also construct a new Contact and populate it before pushing to
Hubspot.

    contact = RHapi::Contact.new
    contact.properties.email = 'user@example.com'
    contact.save # Can also call contact.update

Note that when a contact is created, it does not reload itself but returns the
new Contact object from Hubspot. Updates to existing contacts do have their
properties updated in the local object.

    contact.properties.email = 'user@example.com' # Defining properties for a new contact
    contact = contact.save # => Will replace the object with the newly created version returned from Hubspot

    contact.properties.firstname = 'John' # Update local property for an existing contact
    contact.save # Local object state is synchronized with hubspot

You can create contacts in a similar fashion by defining the attributes using
the methods below before calling the save method.

#### Update a Contact

    contact.update # instance of RHapi::Contact object with changes made

Make changes to attributes and save them:

With a single attribute:

    contact.update_attribute('firstname', 'John') # Updates and calls save

Multiple attributes:

    contact.update_attributes('firstname' => 'John', 'lastname' => 'Doe') # Updates and calls save

Based on property changes:

    contact.properties.firstname = 'John'
    contact.properties.lastname = 'Doe'
    contact.update # can also call contact.save

#### Delete a Contact

    contact.delete # Given existing Contact object
    # => true

#### Get All Contacts

    all_contacts = RHapi::Contact.all # Returns RHapi::ContactAll object
    all_contacts.contacts # Contains array of Contact objects
    # Access each Contact
    all_contacts.contacts.each do |contact|
      puts contact.properties.firstname
    end

You may page through contacts given a RHapi::ContactAll object

    all = RHapi::Contact.all
    all.next(5) # Reloads ContactAll object with the next 5 contacts
    all.next # Reloads with the last used count (5 here, 20 on a new ContactAll instance)
    all.page(5) # Reloads to the given page number (contacts per page defaults to same rules as next method)
    all.page(5, 100) # Reloads to the 5th page of contacts with 100 per page (the maximum allowed by Hubspot)
    all.previous # Same default rules as next
    all.previous(15) # Page back by 15 contacts
    all.prev # Alias for all.previous
    # You can set the count and vidOffset properties for the object yourself
    all.vidOffset = 100
    all.count = 20
    # Reload based on parameters you have set 
    all.refresh_query # Equivalent here to all.page(5, 20) based on defined properties
    # refresh and reload are aliases to refresh_query 
    all = RHapi::Contact.all(:count => 5) # Define count on initial search in constructor

#### Get Recent Contacts

    recent = RHapi::Contact.recent # Returns RHapi::ContactRecent object
    recent.contacts # Contains array of Contact objects
    # Access each Contact
    recent.contacts.each do |contact|
      puts contact.properties.firstname
    end

You may page through contacts given a RHapi::ContactRecent object

    recent = RHapi::Contact.recent
    recent.next # Pages forward - same rules as ContactAll objects (20 here)
    recent.next(5) # Next 5 contacts
    recent.next # Next 5 contacts

You can set your own paging parameters, but need to supply timeOffset,
vidOffset, and optional count The same refresh methods (and aliases) are
available to you. 

#### Get Contact by ID

    contact = RHapi::Contact.find_by_vid(5) # Finds contact with vid 5

#### Get Contact by Email

    contact = RHapi::Contact.find_by_email('user@example.com') # Finds contact with given email

#### Get Contact by User Token

    contact = RHapi::Contact.find_by_token(utk) # Finds a contact with the given hubspot utk value

#### Search for Contacts

    results = RHapi::Contact.find('John') # Searches common fields for query, defaults to 20 results
    # You can also call with the search method alias
    results = RHapi::Contact.search('John Doe', :count => 100) # Searches with count (max 100)
    results # => RHapi::ContactSearch object
    results.contacts # Array of Contact objects
    results.contacts.each do |contact|
      puts contact.properties.firstname
    end

Similar to other query objects, you can modify your query and reload the
results:

    results # existing ContactSearch object 
    results.refresh_query('Jane Doe') # Reloads with new query
    results.refresh('Jane Doe', :count => 50) # Can supply count and call with refresh or reload alias
    results.query = 'John Doe'
    results.offset = 5 # used for count
    results.reload

#### Get Contact Statistics

    statistics = RHapi::Contact.statistics # Returns RHapi::ContactStatistic object
    statistics.contacts # => Contact count
    statistics.lastNewContactAt # => timestamp
    Time.at(statistics.lastNewContactAt).to_datetime # Return datetime object from lastNewContactAt

### Leads API Examples

Then to get a list of leads.

    leads = RHapi::Lead.find
    leads.each do |lead|
      puts lead.first_name
      puts lead.last_name
      puts lead.city
      puts lead.state
      puts lead.guid
    end

To find leads named Barny.

    leads = RHapi::Lead.find("Barny")

You can also pass additional options to the find method.

    options = {
      :sort       => "lastName",          # Possible sort values include: firstName, lastName, email, address, phone, insertedAt, lastConvertedAt, lastModifiedAt, closedAt
      :dir        => "asc",               # Use desc for descending.
      :max        => 25,                  # Maximum value is 100
      :offset     => 50,                  # Used in combination with max for paging results. 
      :startTime  => 1298721462000,       # Expressed as milliseconds since epoch time. Returned list will have only leads inserted after this time. Default is 0 and returns all leads up to max.
      :stopTime   => 1298721462000,       # Expressed as milliseconds since epoch time. 
      :timePivot  => "insertedAt",        # The field the start and stop times should be applied to in the search. Can be: insertedAt, firstConvertedAt, lastConvertedAt, lastModifiedAt, closedAt.
      :excludeConversionEvents => false,  # Used to exclude all items in the leadConversionEvents collection from the API results.
      :optout                  => false,  # Set to true to include only leads that have unsubscribed from lead nurturing. The default value, false, includes all leads. 
      :eligibleForEmail        => false,  # Set to true to include only leads eligible for email marketing.
      :bounced                 => false,  # Set to true to include only leads that HubSpot has tried to email, and the email bounced. The default value, false, includes all leads.
      :notImported             => false  # Set to true to include only web leads. The default value, false, includes both imported and web leads.
    }
    leads = RHapi::Lead.find("Barny", options)

To update a lead.

    lead = leads.first
    lead.first_name = "Fred"
    lead.last_name  = "Flintsone"
    lead.update

You can also pass a params hash to update a lead.

    params = {:first_name => "Fred", :last_name => "Flintstone", :city => "Bedrock"}
    lead.update(params)

To get a single lead with a guid. Assumes the guid has be saved from a
previous search.

    lead = RHapi::Lead.find_by_guid(lead.guid)

## Contributing to r_hapi

*   Check out the latest master to make sure the feature hasn't been
    implemented or the bug hasn't been fixed yet
*   Check out the issue tracker to make sure someone already hasn't requested
    it and/or contributed it
*   Fork the project
*   Start a feature/bugfix branch
*   Commit and push until you are happy with your contribution
*   Make sure to add tests for it. This is important so I don't break it in a
    future version unintentionally.
*   Please try not to mess with the Rakefile, version, or history. If you want
    to have your own version, or is otherwise necessary, that is fine, but
    please isolate to its own commit so I can cherry-pick around it.


## Changelog

*   Add CRUD instance methods to Contact objects
*   Implement all Contacts API methods
*   Provide access to hyphened properties at higher-tree levels
*   Added methods to fetch contacts by vid, user token, and email
*   Abstracted to allow for multiple api implementations (beyond just leads)
*   Accept oAuth access tokens and prefer them over api keys for non-legacy
    api calls


## License

Copyright (c) 2013 HubSpot Licensed under the MIT license.

## Contributors

Thoughtfully improved and maintained by @clp-jeremy. Based on the original
work of @timstephenson.
