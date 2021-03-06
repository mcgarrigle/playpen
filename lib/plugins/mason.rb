
require 'net/http'
require 'json'

module Plugins

  class Mason

    def initialize(laboratory, options = {:api => "http://localhost:9090"})
      @laboratory = laboratory
      @uri = URI(options[:api])
      response = Net::HTTP.start(@uri.hostname, @uri.port, :open_timeout => 2, :read_timeout => 2) { |http|
        http.get("/version")
      }
      result = JSON.parse(response.body)
      puts "mason version #{result['version']}"
    end

    def create(guest)
      puts "mason: create #{guest.name}"
      nameserver = @laboratory.nameservers.first
      interfaces = guest.interfaces.map {|i| { :mac => i.mac, :ip => i.ip4, :netmask => i.netmask4, :gateway => i.gateway4 } }
      hash = {:fqdn => guest.fqdn, :interfaces => interfaces, :nameserver => nameserver }
      p hash
      response = Net::HTTP.start(@uri.hostname, @uri.port) { |http|
        http.post("/node", hash.to_json)
      }
    end

    def start(guest)
    end

    def stop(guest)
    end

    def destroy(guest)
    end

  end

end
