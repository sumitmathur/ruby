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
 
  def post(url, body = {}, headers = {})
    @connection.post do |req|
      req.url(url)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Token token=#{@options[:token]}"
      puts JSON.generate(body)
      req.body = JSON.generate(body)
    end
  end
 
end

def get_maintenance_windows_ids(service_ids,subdomain,token)

endpoint = "https://#{subdomain}.pagerduty.com/api/v1/maintenance_windows/"
token_string = "Token token=#{token}"
lservice_ids = service_ids

response = HTTParty.get(
  endpoint,
  headers: {
    'Content-Type' => 'application/json', 'Authorization' => token_string
  },
  query: {
        :service_ids=>service_ids, 
         :filter=>'ongoing',      
  }  

)

parsed = JSON.parse(response.body)
maintenance_windows_ids=[]


  for i in 0..(parsed["maintenance_windows"].length - 1)
  maintenance_windows_ids.push(parsed["maintenance_windows"][i]["id"])
  puts parsed["maintenance_windows"][i]["id"]
  end

  return maintenance_windows_ids

end

def delete_maintenance_windows(service_ids,subdomain,token)
  maintenance_windows_ids = get_maintenance_windows_ids(service_ids,subdomain,token)


  for id in maintenance_windows_ids
    endpoint = "https://#{subdomain}.pagerduty.com/api/v1/maintenance_windows/" \
               "#{id}"
    token_string = "Token token=#{token}"

    response = HTTParty.delete(
      endpoint,
      headers: {
        'Content-Type' => 'application/json', 'Authorization' => token_string
      }
    )

    puts "code :: #{response.code}"
   end
end


def actionPagerDuty (app_name,mode,dc,time,services,token,subdomain)

puts "You are in pagerduty with app name as #{app_name}"
# User id (the user that is putting the service in maintenance mode)
requester_id = "PUGSX3D"
# Create an array of services
service_ids=[]
service=services.split(",")
service.each do |id|
  service_ids.push(id)
end


#service_ids = ["P24CZ15","PULL0LC"]
# This is will be different for different services and will get this from DB
lsubdomain=subdomain
#Token will be different for each url
ltoken=token
maintenance_start_time = Time.now.utc
maintenance_start_time =  maintenance_start_time + Time.zone_offset("PDT")
maintenance_end_time = maintenance_start_time + time.to_i.minute

if mode == "disable"
  pd = PagerDutyAgent.new(:subdomain => lsubdomain, :token => ltoken)
    pd.post("/api/v1/maintenance_windows", 
  { "maintenance_window" => {
      "start_time" => maintenance_start_time.strftime(DATE_FORMAT),
      "end_time" => maintenance_end_time.strftime(DATE_FORMAT),
      "service_ids" => service_ids
    },
        "requester_id" => requester_id
  })

 elsif mode == "enable"
   puts "Pagerduty in disable" ##Need to check on remove maintenance mode.
   delete_maintenance_windows(service_ids,subdomain,token)   
 end

end

def actionSpectrum (app_name,mode,hostname)

if mode == "disable"
 action = "ON"
 puts "Spectrum is disable"
elsif mode == "enable"
  puts "Spectrum is enable"
 action = "OFF"
else
  abort("No action performed")
end

puts "You are in spectrum with app name as #{app_name}"
puts "Hostnames are #{hostname}"

array=hostname.split(",")
array.size.times do |i|
   ip=Resolv.getaddress(array[i].rstrip.lstrip)
   puts "hostname :: #{array[i]}, ip :: #{ip}"
   stdout, stderr, exit_status = Open3.capture3("java -jar /Users/smathur1/Documents/chef/silencer/MaintenanceMode.jar #{action} #{ip} smathur1-admin")
   puts "STDOUT: " + stdout
   puts "STDERR: " + stderr
   stat = (exit_status.success? ? 'succeeded' : 'failed')
   puts "EXIT STATUS: " + (exit_status.success? ? 'succeeded' : 'failed')
   puts"#################### Completed ####################"
end
end

def disableSiteScope(server,group,time)



end

def enableSiteScope(server,group)

end




def actionSiteScope(server,group,time,mode)

 ltime = time.to_i * 60 

the_classpath=""
 Dir["/tmp/sitescope/api/lib/*"].each do  |lib|
   the_classpath = lib + ":" + the_classpath
   #puts lib
end

 if mode == "disable"
 
    disableSiteScope(server,group,ltime)     
  elsif mode == "enable"
    
    enableSiteScope(server,group)

  end

end
    



##Main

application_name = ARGV[0];
mode = ARGV[1];
dc= ARGV[2];
time=ARGV[3];

if ARGV.length != 4 
 abort("USAGE :: input.rb application_name mode dc time") 
end




#Mysql Connection

begin
    
    con = Mysql.new 'localhost', 'root', '', 'silencer'
    puts con.get_server_info
    rs = con.query("select * from lookup where app_name = '#{application_name}' and datacenter = '#{dc}'")
    puts rs
    n_rows = rs.num_rows
    
    puts "There are #{n_rows} rows in the result set"
    
    if n_rows != 1
       abort("Row numbers is not 1")
    else
       puts "Row is 1"
    end

   rs.each_hash do |row|
         if row['spectrum'] == "Yes"
            hostname = row['hostnames']
            actionSpectrum(application_name,mode,hostname)
         end
         if row['pagerduty'] == "Yes"
            services = row['p_services']
            token = row['p_token']
            subdomain = row['p_subdomain']
            puts "services= #{services}"
            puts "toke = #{token}"
            puts "subdomain = #{subdomain}"
            actionPagerDuty(application_name,mode,dc,time,services,token,subdomain)
         end
         if row['sitescope'] == "Yes"
               server = row['s_server']
               group = row['s_group']
               actionSiteScope(server,group,time,mode)
         end
          
    end
          

rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end




#guests = CSV.foreach('/Users/smathur1/Documents/chef/silencer/application_host.csv',headers:true) do |row|
#  application_name_csv = row['Application_Name']
#  data_center=row['Datacenter']
#  if application_name_csv == application_name  and data_center == dc
#     spectrum = row ["Spectrum"]
#     sitescope = row["Sitescope"]
#     wily = row["Wily"]
#     newRelic = row["NewRelic"]
#     pd = row["PagerDuty"]
#     
#     if spectrum == "Yes"
#        hostname= row["HostNames"]
#        actionSpectrum(application_name,mode,hostname)
#     end
#     if pd == "Yes"
#        services = row["P_Services"]
#        token = row["P_Token"]
#        subdomain = row["P_SubDomain"]
#        actionPagerDuty(application_name,mode,dc,time)
#     end
#  end
#end


