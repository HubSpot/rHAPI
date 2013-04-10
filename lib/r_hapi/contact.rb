require 'rubygems'
require 'active_support'
require 'active_support/inflector/inflections'
require File.expand_path('../connection', __FILE__)

module RHapi
  class PortalStatistic
    include Connection
    extend Connection::ClassMethods

    attr_reader :attributes

    def initialize(data)
      @attributes = data
    end

    # Instance methods -------------------------------------------------------
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
  
      return super unless self.attributes.include?(attribute)
      self.attributes[attribute]
            
    end
  end

  class ContactQuery
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data)

      contacts = []
      data['contacts'].each do |data|
        contact = Contact.new(data)
        contacts << contact
      end
      data['contacts'] = contacts      
      self.attributes = data
      self.changed_attributes = {}
    end

    # Instance methods -------------------------------------------------------
    # Refresh the query
    def refresh_query(results)
      raise 'Must provide resultset to refresh query' if results.nil?
      results.attributes.each_pair do |key, value|
        self.attributes[key] = value
      end
      self.changed_attributes = {}
      true
    end

    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
      dashed_attribute = ActiveSupport::Inflector.dasherize(ActiveSupport::Inflector.underscore(attribute))
  
      if dashed_attribute =~ /=$/
        dashed_attribute = dashed_attribute.chop
        return super unless self.attributes.include?("#{dashed_attribute}")
        self.changed_attributes["#{dashed_attribute}"] = args[0]
        self.attributes["#{dashed_attribute}"] = args[0]
      else
        return super unless self.attributes.include?("#{dashed_attribute}")
        self.attributes["#{dashed_attribute}"]
      end 
            
    end

  end

  class ContactSearch < ContactQuery
    def refresh_query(search=nil, options={})
      options[:q] = @attributes['query'] unless @attributes['query'].nil? # Default to existing search
      options[:q] = search unless search.nil? # Override with called search
      options[:q] = @changed_attributes['query'] unless @changed_attributes['query'].nil? # Override with updated query
      if options[:count].nil?
        options[:count] = @attributes['offset'] unless @attributes['offset'].nil? or !options[:count].nil? # Override count if not in called options
        options[:count] = @changed_attributes['offset'] unless @changed_attributes['offset'].nil? # Override count if updated
      end
      results = Contact.find(search, options)
      super(results) 
    end

    alias_method :refresh, :refresh_query
    alias_method :reload, :refresh_query

  end

  class ContactAll < ContactQuery

    def refresh_query(options={})
      if options[:vidOffset].nil?
        unless @attributes['vid-offset'].nil?
          options[:vidOffset] = @attributes['vid-offset']
        end
        unless @changed_attributes['vid-offset'].nil?
          options[:vidOffset] = @changed_attributes['vid-offset']
        end
      end
      results = Contact.all(options)
      super(results) 
    end

    alias_method :refresh, :refresh_query
    alias_method :reload, :refresh_query

    # Constrain count to <= 100
    # Paginate with vidOffset and send param as vidOffset
    def next(count=nil)
      count = self.contacts.size if count.nil?
      refresh_query(count: count, vidOffset: self.vidOffset)
    end

    def page(number=1, count_per_page=nil)
      count_per_page = self.contacts.size if count_per_page.nil?
      refresh_query(count: count_per_page, vidOffset: count_per_page * (number -1 ))
    end

    def previous(count=nil)
      count = self.contacts.size if count.nil?
      refresh_query(count: count, vidOffset: self.vidOffset - (count * 2))
    end

    alias_method :prev, :previous

  end

  class ContactRecent < ContactQuery
    # TODO: allow refresh to get the latest (once again) rather than paging
    # consider reload! refresh! refresh_query!
    def refresh_query(options={})
      if options[:timeOffset].nil?
        unless @attributes['time-offset'].nil?
          options[:timeOffset] = @attributes['time-offset']
        end
        unless @changed_attributes['time-offset'].nil?
          options[:timeOffset] = @changed_attributes['time-offset']
        end
      end
      if options[:vidOffset].nil?
        unless @attributes['vid-offset'].nil?
          options[:vidOffset] = @attributes['vid-offset']
        end
        unless @changed_attributes['vid-offset'].nil?
          options[:vidOffset] = @changed_attributes['vid-offset']
        end
      end
      results = Contact.recent(options)
      super(results) 
    end

    alias_method :refresh, :refresh_query
    alias_method :reload, :refresh_query

    # Constrain count to <= 100
    # Paginate with vidOffset and send param as vidOffset
    def next(count=nil)
      count = self.contacts.size if count.nil?
      refresh_query(count: count, timeOffset: self.timeOffset, vidOffset: self.vidOffset)
    end

    # TODO: add since and from {DATE} with support for 5.days.ago, etc

  end

  class ContactProperty
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes
    
    def initialize(data=nil)
      unless data.nil?
        data.each do |property, hash|
          data[property] = hash["value"]
        end
      
        self.attributes = data
      else
        self.attributes = {}
      end
      self.changed_attributes = {}
    end

    # Instance methods -------------------------------------------------------
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
  
      if attribute =~ /=$/ # Define property -- does not have to exist
        attribute = attribute.chop
        self.changed_attributes[attribute] = args[0]
        self.attributes[attribute] = args[0]
      else
        return super unless self.attributes.include?(attribute)
        self.attributes[attribute]
      end 
            
    end

  end

  class Contact
    include Connection
    extend Connection::ClassMethods
    
    attr_accessor :attributes, :changed_attributes # reference changes from nested object
    attr_reader :read_only_members
    
    def initialize(data=nil)
      unless data.nil?
        @read_only_members = data.slice!('properties') # Construct read-only attributes (e.g.: portal id)
        data['properties'] = ContactProperty.new(data['properties'])
        self.attributes = data # Read-writable properties (e.g.: first & last name)
      else
        self.attributes = { 'properties' => ContactProperty.new }
        @read_only_members = {}
      end
      self.changed_attributes = {}
    end
    
    # Class methods ----------------------------------------------------------

    def self.create(params)
      contact = Contact.new
      contact.update_attributes(params)
      # returns new contact object # TODO: ensure returns contact object
    end
    
    # TODO: implement reload

    # Finds contacts and returns an array of contacts. 
    # An optional string value that is used to search several basic contact fields: first name, last name, email address, 
    # and company name. According to HubSpot docs, a more advanced search is coming in the future. 
    # The default value for is nil, meaning return all contact.
    def self.find(search=nil, options={})  
      options[:q] = search unless search.nil?
      response = get(url_for({
        :api => 'contacts',
        :resource => 'search',
        :method => 'query'
      }, options))
 
      contact_data = JSON.parse(response.body_str)
      ContactSearch.new(contact_data)
    end
    
    # Finds specified contact by its unique id (vid).
    def self.find_by_vid(vid)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'vid',
        :identifier => vid,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Finds specified contact by its email address.
    def self.find_by_email(email)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'email',
        :identifier => email,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Finds specified contact by its user token.
    def self.find_by_token(token)
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'utk',
        :identifier => token,
        :method => 'profile'
      ))
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    # Finds all contacts
    def self.all(options={})
      response = get(url_for({
        :api => 'contacts',
        :resource => 'lists',
        :filter => 'all',
        :member => 'contacts',
        :context => 'all'
      }, options))
 
      contact_data = JSON.parse(response.body_str)
      ContactAll.new(contact_data)
    end

    # Finds most contacts
    def self.recent(options={})
      response = get(url_for({
        :api => 'contacts',
        :resource => 'lists',
        :filter => 'recently_updated',
        :member => 'contacts',
        :context => 'recent'
      }, options))
 
      contact_data = JSON.parse(response.body_str)
      ContactRecent.new(contact_data)
    end

    # Gets portal statistics.
    def self.statistics
      response = get(url_for(
        :api => 'contacts',
        :resource => 'contacts',
        :method => 'statistics'
      ))
      statistics_data = JSON.parse(response.body_str)
      PortalStatistic.new(statistics_data)
    end
    
    class << self
      alias_method :search, :find
      alias_method :find_all, :all
      alias_method :newest, :recent
      alias_method :most_recent, :recent
    end

    # Instance methods -------------------------------------------------------
    def save
      params = []
      self.properties.changed_attributes.each_pair do |key, value|
        params << { :property => key, :value => value }
      end
      params = { 'properties' => params }
      # call create or update API method accordingly
      if self.read_only_members.empty?
        unless self.properties.attributes.include?("email")
          raise(RHapi::AttributeError, "Newly created contacts must include an email address.")
        end
        response = create_new(params)
      else
        response = update_existing(params)
      end
      self.changed_attributes = {}
      response
    end
    def update(params={})
      unless params.empty?
        update_attributes(params) # changes values and sets changed_attributes for ContactProperty object
        # at self.properties[.{changed_}attributes], then runs save
      else 
        save
      end
    end

    # Note: Takes the exact string name of the property to be changed
    # TODO: only allow existing properties
    def update_attribute(name, value) # to be deprecated in rails 4 by update_column
      self.properties.send(name.to_s + '=', value)
      save
    end

    # Note: Takes the exact string name of the property to be changed
    # TODO: only allow existing properties
    def update_attributes(params)
      raise(RHapi::AttributeError, "The params must be a hash.") unless params.is_a?(Hash)
      params.each do |name, value|
        self.properties.send(name.to_s + '=', value)
      end
      save # only call API once rather than repeatedly saving with update_attribute calls
    end

    def create_new(params)
      response = post(Contact.url_for(
        :api => 'contacts',
        :resource => 'contact'
      ), params)
      contact_data = JSON.parse(response.body_str)
      Contact.new(contact_data)
    end

    def update_existing(params)
      response = post(Contact.url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'vid',
        :identifier => self.vid,
        :method => 'profile'
      ), params)
    end

    def delete
      response = http_delete(Contact.url_for(
        :api => 'contacts',
        :resource => 'contact',
        :filter => 'vid',
        :identifier => self.vid
      ))
      true
    end

    alias_method :destroy, :delete
    
    # Work with data in the data hash
    def method_missing(method, *args, &block)
      
      attribute = ActiveSupport::Inflector.camelize(method.to_s, false)
      dashed_attribute = ActiveSupport::Inflector.dasherize(ActiveSupport::Inflector.underscore(attribute))
  
      if attribute =~ /=$/ # Handle assignments only for read-writable attributes
        attribute = attribute.chop
        return super unless self.attributes.include?(attribute)
        self.changed_attributes[attribute] = args[0]
        self.attributes[attribute] = args[0]
      elsif self.attributes.include?(attribute) # Accessor for existing attributes
        self.attributes[attribute]
      elsif self.read_only_members.include?("#{dashed_attribute}") # Accessor for existing read-only members
        self.read_only_members["#{dashed_attribute}"]
      else # Not found - use default behavior
        super
      end 
            
    end

    # Private methods
    private :create_new
    private :update_existing
 
  end
  
end
