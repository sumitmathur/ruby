#build string

the_classpath=""
 Dir["/tmp/sitescope/api/lib/*"].each do  |lib| 
   the_classpath = the_classpath + ":" + lib
   the_classpath = lib + ":" + the_classpath 
   #puts lib
end

puts the_classpath
