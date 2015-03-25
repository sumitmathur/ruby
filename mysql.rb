 
require 'mysql'

application_name='Oauth2'
dc='qdc'

def actionSpectrum(hostnames)
	
      puts "In spectrum"
      puts "#{hostnames}"

	end

def actionPagerDuty()
	

		puts "in pagerduty"
	end

def actionWily()
	

		puts "in wily"
	end

begin
    
    con = Mysql.new 'localhost', 'root', '', 'silencer'
    puts con.get_server_info

    rs = con.query("select * from lookup where app_name = '#{application_name}' and datacenter = '#{dc}'")
    n_rows = rs.num_rows
    
    puts "There are #{n_rows} rows in the result set"
    
    #n_rows.times do
     #   puts rs.fetch_row.join("\s")
    #end
    
    

     rs.each_hash do |row|
         if row['spectrum'] == "Yes"
         	actionSpectrum (row['hostnames'])
         end
         if row['pagerduty'] == "Yes"
         	actionPagerDuty()
         end
         	
        end
          

 
rescue Mysql::Error => e
    puts e.errno
    puts e.error
    
ensure
    con.close if con
end
