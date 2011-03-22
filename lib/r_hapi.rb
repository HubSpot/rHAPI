require File.expand_path('../r_hapi/lead', __FILE__)
require File.expand_path('../r_hapi/configuration', __FILE__)
require File.expand_path('../r_hapi/r_hapi_exception', __FILE__)

require 'curb'
require 'json'

module RHapi
  extend Configuration
end