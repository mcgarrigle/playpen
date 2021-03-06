
require 'nokogiri'
require 'record_stream'

class Vbox

  attr_reader :name

  def initialize(name = nil)
    @name = name
  end

  def self.config_file
    home = ENV["HOME"]
    if ENV["OS"] == "Darwin"
      return File.join(home, "Library", "VirtualBox", "Virtualbox.xml")
    else
      return File.join(home, ".VirtualBox", "Virtualbox.xml")
    end
  end

  def self.machine_folder
    doc = Nokogiri::XML(File.read(config_file))
    return doc.at_xpath("//xmlns:SystemProperties/@defaultMachineFolder").to_s
  end

  def self.vms(type = :vms)
    vms = list(type).map {|s| /"(.+)" (.*)/.match(s); [$2,$1] }
    Hash[vms]
  end

  def self.networks
    #stream = RecordStream.new(list(:natnets))
    #nats = stream.records.map {|n| Network.new(n["NetworkName"], :natnetwork => n["Network"]) }
    #p nats
    #stream = RecordStream.new(list(:hostonlyifs))
    #hoifs = stream.records.map {|n| Network.new(n["Name"], :hostonly => "#{n['IPAddress']} #{n['NetworkMask']}") }
    #p hoifs
  end

  def self.list(type)
    array = %x[vboxmanage list #{type}]
    array.lines.map(&:chomp)
  end

  def createvm(args = {})
    command("createvm", "--register", "--name", @name, *argv(args))
  end

  def createhd(args = {})
    command("createhd", *argv(args))
  end

  def modifyvm(args = {})
    command("modifyvm", @name, *argv(args))
  end

  def storagectl(args = {})
    command("storagectl", @name, *argv(args))
  end

  def storageattach(args = {})
    command("storageattach", @name, *argv(args))
  end

  def startvm(type = :headless)
    command("startvm", @name, '--type', type.to_s)
  end

  def stopvm(type = :acpipowerbutton)
    ok = [:poweroff, :acpipowerbutton]
    raise "shutdown type '#{type}' not known" unless ok.include? type
    command("controlvm", @name, type.to_s)
  end

  def unregistervm
    command("unregistervm", @name, "--delete")
  end

  def command(*args)
    # puts "vboxmanage #{args.join(' ')}"; return
    ok = system("vboxmanage", *args)
    raise "error calling: #{args}" unless ok
  end

  def argv(args = {})
    args.map {|k,v| ["--#{k.to_s}", v.to_s] }.flatten
  end

end
