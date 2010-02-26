require 'rake'
require 'open-uri'
require 'socket'

pwd = File.expand_path(File.dirname(__FILE__))
HUDSON_URL = 'http://localhost' unless defined?(HUDSON_URL)
JAVA_CMD   = `which java`.chomp unless defined?(JAVA_CMD)
JAVA_OPTS  = '-Xmx512M' unless defined?(JAVA_OPTS)
HUDSON_WAR =  pwd + '/hudson.war'
HUDSON_IPTABLES_SCRIPT = pwd + '/hudson_ports.sh'

task :default do
  sh "rake #{__FILE__} -T"
end

##
# verbose? and listening? are lifted from cnu_rake_util.rb 
# Need to not copy/paste!
# --jodell 200912015
## 

def verbose?
  ENV['verbose'] || ENV['VERBOSE']
end

##  
# Checks if <b>host</b> is listening on <b>port</b>
#
def listening?(host = 'localhost', port = '4444')
  begin 
    TCPSocket.new(host, port)
  rescue Errno::ECONNREFUSED
    puts "No connection on #{host}:#{port} yet!" if verbose?
    return false
  end 
  return true
end 

def hudson_stopped?
  !listening?('localhost', '80')
end

def start_hudson
  if hudson_stopped?
    sh "#{JAVA_CMD} #{JAVA_OPTS} -jar #{HUDSON_WAR} &> /dev/null &"
  end
end
 
def stop_hudson(force = false)
  puts "Running `open #{HUDSON_URL}/exit`, force=#{force ? 'true' : 'false'}" if verbose?
  open "#{HUDSON_URL}/exit" unless hudson_stopped? && !force
  sleep 1
end

namespace 'hudson' do
  desc 'Start the local hudson server'
  task :start => :ports do
    start_hudson
  end

  desc 'Stop the local hudson server'
  task :stop do
    stop_hudson(ENV['force'] && ENV['force'] =~ /true/i)
  end

  desc 'Restart the local hudson server'
  task :restart => [:stop, :start]

  desc "Runs the iptables script, #{HUDSON_IPTABLES_SCRIPT}"
  task :ports do
    sh "sudo #{HUDSON_IPTABLES_SCRIPT}"
  end

  desc 'TODO:  Automate hudson upgrades'
  task :upgrade do
    raise 'TODO'
  end

end # hudson
