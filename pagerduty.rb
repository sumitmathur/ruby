require 'net/ssh'
require 'net/http'
require 'uri'
require 'csv'
require 'resolv'
require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'json'
require 'open3'
require 'httparty'
require 'mysql'
 
DATE_FORMAT =  "%FT%T:%z"
 
class PagerDutyAgent
 
  def initialize(options = {})
    @options = options
    @connection = Faraday.new(:url => "https://#{options[:subdomain]}.pagerduty.com", 
                              :ssl => {:verify => false}) do |c|
      c.request  :url_encoded
      c.response :logger
      c.adapter  :net_http
    end
  end
 
  # E.g. post("/api/v1/maintenance_windows", )
  def post(url, body = {}, headers = {})
    @connection.post do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Token token=#{@options[:token]}"
      #puts JSON.generate(body)
      req.body = JSON.generate(body)
    end
  end
 
end
 
pd = PagerDutyAgent.new(:subdomain => "ics-intuit", :token => "H3Z1yMnnjsr9VTpmNddZ")
 
# User id (the user that is putting the service in maintenance mode)
requester_id = "PUGSX3D"
# List of services that are part of this maintenance
service_ids = ["P24CZ15","PULL0LC"]
 #Time.zone = "Pacific Time (US & Canada)"
maintenance_start_time = Time.now.utc
maintenance_start_time =  maintenance_start_time + Time.zone_offset("PDT")
#print "maintenance_start_time : " + maintenance_start_time
maintenance_end_time = maintenance_start_time + 15.minute
 
# Recur this maintenance window for the next 20 week 

 
  response = pd.post("/api/v1/maintenance_windows", 
  { "maintenance_window" => {
      "start_time" => maintenance_start_time.strftime(DATE_FORMAT),
      "end_time" => maintenance_end_time.strftime(DATE_FORMAT),
      "description" => "15 minute maintenance",
      "service_ids" => service_ids
    },
        "requester_id" => requester_id
  })

  
  code = response.status

  puts "code:: #{code}" 





