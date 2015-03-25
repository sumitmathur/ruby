
require 'httparty'
require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'json'

subdomain='ics-intuit'
api_token='H3Z1yMnnjsr9VTpmNddZ'
window_id='PUGSX3D'
DATE_FORMAT =  "%FT%T:%z"
endpoint="https://#{subdomain}.pagerduty.com/api/v1/maintenance_windows/#{window_id}"
token_string="Token token=#{api_token}"
maintenance_start_time = Time.now.utc
maintenance_start_time =  maintenance_start_time + Time.zone_offset("PDT")
maintenance_end_time = maintenance_start_time + 15.minute
# List of services that are part of this maintenance
service_ids = ["P24CZ15"]

data = {
      "start_time" => maintenance_start_time.strftime(DATE_FORMAT),
      "end_time" => maintenance_end_time.strftime(DATE_FORMAT),
      "description" => "15 minute maintenance",
      "service_ids" => service_ids
       }

response = HTTParty.put(endpoint, 
                         :body => data.to_json,
                         :headers => { "Content-Type" => 'application/json', "Authorization" => token_string})
text= response.body
puts text