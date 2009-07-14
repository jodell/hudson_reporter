require 'open-uri'
require 'net/http'
require 'rexml/document'

# Example XML from http://wiki.hudson-ci.org/display/HUDSON/Monitoring+external+jobs
#
# <run>
#   <log encoding='hexBinary'>...hex binary encoded console output...</log>
#   <result>... integer indicating the error code. 0 is success and everything else is failure</result>
#   <duration>... milliseconds it took to execute this run ...</duration>
# </run>
#
# The duration element is optional. Console output is hexBinary encoded so that you can pass in any control characters that are otherwise disallowed in XML. Elements must be in this order.
# 
#   The above XML needs to be sent to http://myhost/hudson/job/_jobName_/postBuildResult.
##

##
# This class represents objects that can connect to the hudson external API 
# for job result passing.
# SEE http://hudson.dev.java.net
# WIKI:  https://wiki.cashnetusa.com/mediawiki/index.php/tech:Hudson
# -jodell 20090623
#
class HudsonConnObj
  attr_accessor :host, :port, :job
  attr_reader :resource, :url
  REQ_INIT_ARGS = [:host].freeze unless defined?(REQ_POST_ARGS)
  REQ_POST_ARGS = [:job, :result].freeze unless defined?(REQ_INIT_ARGS)

  ##
  # Host is the only required parameter to start a Hudson connection object.  Will default
  # port to 8080 unless specified.
  #
  def initialize(*args)
    arg_err(REQ_INIT_ARGS) unless args
    args[0].each { |k, v| instance_eval("@#{k} = '#{v}'") }
    arg_err(REQ_POST_ARGS) unless @host
    @port = '8080'
    @url = URI.parse("http://#{@host}:#{@port}")
  end

  def arg_err(args)
    raise ArgumentError, "Expected #{args * ', '} to be defined"
  end

  ##
  # Requires a job name and result (zero or non-zero).
  # Optional args are:
  # - duration, in milliseconds
  # - log, STDOUT for most things, verbose output
  # - encoding, Hudson appears to only support hexBinary (default)
  #
  def post(*args)
    arg_err(REQ_POST_ARGS) unless args
    args[0].each { |k, v| instance_eval("@#{k} = '#{v}'") }
    arg_err(REQ_POST_ARGS) unless @job && @result
    @log ||= '1'
    @encoding ||= 'hexBinary'
    @resource = "/job/#{@job}/postBuildResult"
    @url = URI.parse("http://#{@host}:#{@port}/job/#{@job}/postBuildResult")
    http = Net::HTTP.new(@url.host, @url.port)
    begin
      hudr = HudsonResult.new(@result, @duration, @log, @encoding).to_s
      http.post @url.path, hudr
    rescue Exception => e
      puts "Tried to post to http://#{@url.host}:#{@url.port}#{@url.path}, values #{hudr}"
      puts e.message; puts e.backtrace
    end
  end

  ##
  # Wraps Hudson Results
  #
  class HudsonResult
    attr_accessor :doc, :encoding
    # Probably needs validation
    def initialize(result, duration, log = '', encoding = 'hexBinary')
      @encoding = encoding
      @doc = REXML::Document.new <<-EOF
<run>
  <log encoding='#{encoding}'>#{encode(log)}</log>
  <result>#{result.to_s}</result>
  <duration>#{duration.to_s}</duration>
</run>
EOF
    end
    
    def encode(str)
      case @encoding
      when /hexBinary/i # Hudson wants hex binary-encoded XML
        return str.split(//).collect { |x| x.unpack('H*') }.join # Fantastic string meme
      else
        return str
      end
    end
    
    def to_s() @doc.to_s end
  end # HudsonResult

end # HudsonConnObj

## Example
#hud = HudsonConnObj.new(:host => 'hudson.ci.cashnetusa.com')
#hud.post :job => 'test_external_api', :result => '0', :duration => 1000, :log => "This test passed!\nYay!\n"



