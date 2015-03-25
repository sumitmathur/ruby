
require 'httparty'
require 'json'
require 'rubygems'

$SUBDOMAIN = 'ics-intuit'
$API_KEY = 'H3Z1yMnnjsr9VTpmNddZ'

def get_maintenance_windows_ids()

endpoint = "https://#{$SUBDOMAIN}.pagerduty.com/api/v1/maintenance_windows/"
token_string = "Token token=#{$API_KEY}"
service_ids = ["P24CZ15","PULL0LC"]
params = {:params=>{:service_ids=>service_ids, 
                    :filter=>'ongoing',   
                    }
                  }


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

def delete_maintenance_windows()
  maintenance_windows_ids = get_maintenance_windows_ids()


  for id in maintenance_windows_ids
    endpoint = "https://#{$SUBDOMAIN}.pagerduty.com/api/v1/maintenance_windows/" \
               "#{id}"
    token_string = "Token token=#{$API_KEY}"

    response = HTTParty.delete(
      endpoint,
      headers: {
        'Content-Type' => 'application/json', 'Authorization' => token_string
      }
    )

    code=response.code

    puts "code :: #{code}"
     
    return code


      




   end

end
 
code = delete_maintenance_windows()

   if code  == 204
       puts "service_ids = are taken out of  maintenance_windows"
         
    else
        puts "Failed to take OOM"
         
    end



