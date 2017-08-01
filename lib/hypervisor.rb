
require "vbox"
require "vm"

class Hypervisor

  def initialize
    @machine_folder = Vbox.machine_folder
  end

  def self.list
    all     = Vbox.list(:vms)
    running = Vbox.list(:runningvms)
    vms = all.map do |id, name|
      vm = VM.new(id, name)
      vm.state = running[id] ? :running : :stopped
      vm
    end
    return vms
  end

  def self.status
    vms = list.map {|g| [g.name, g.state] }
    Hash[vms]
  end

  def create(guest)
    vbox = Vbox.new(guest.name)
    vbox.createvm(:ostype => guest.ostype)
    vbox.modifyvm(:ioapic => :on)
    vbox.modifyvm(:memory => guest.memory, :vram => guest.vram)
    vbox.modifyvm(:natdnshostresolver1 => :on)

    guest.boot.each_with_index do |device, i|
      boot = "boot#{i + 1}".to_sym
      vbox.modifyvm(boot => device)
    end

    guest.interfaces.each_with_index do |interface, i|
      n = i  + 1
      nic  = "nic#{n}".to_sym
      net  = "intnet#{n}".to_sym
      port = "natpf#{n}".to_sym
      case interface.network
      when :nat, :bridged, :intnet, :hostonly then vbox.modifyvm(nic => interface.network)
      else vbox.modifyvm(nic => :intnet)
           vbox.modifyvm(net => interface.network)
      end
      interface.rules.each do |rule|
        vbox.modifyvm(port => rule.to_s)
      end
    end

    vbox.storagectl(:name => "IDE", :add => :ide)
    vbox.storagectl(:name => "SATA", :add => :sata, :controller => :IntelAHCI)
    dvds,disks = guest.disks.partition {|d| d.device == :sr0 }
    dvd = dvds.first

    vbox.storageattach(:storagectl => "IDE", :port => 0, :device => 0, :type => :dvddrive, :medium => dvd.medium)

    disks.each_with_index do |disk, port|
      path = File.join(@machine_folder, guest.name, "#{disk.device}.vdi")
      vbox.createhd(:filename => path, :size => disk.size)
      vbox.storageattach(:storagectl => "SATA", :port => port, :device => 0, :type => :hdd, :medium => path)
    end
  rescue
    raise
  end

  def start(guest, type = :headless)
    vbox = Vbox.new(guest.name)
    vbox.startvm(type)
  end

  def stop(guest, type = :acpipowerbutton)
    vbox = Vbox.new(guest.name)
    vbox.stopvm(type)
  end

  def destroy(guest)
    vbox = Vbox.new(guest.name)
    vbox.unregistervm
  end

end

