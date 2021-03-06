
require "virtualbox"
require "guest"

describe Virtualbox do

  describe ".list" do

    it "calls Vbox.list" do
      expect(Vbox).to receive(:vms).twice.and_return({})
      Virtualbox.list
    end

    it "classifies running vms" do
      allow(Vbox).to receive(:vms).with(:vms).and_return({ "{xxxx}" => "foo", "{yyyy}" => "bar" })
      allow(Vbox).to receive(:vms).with(:runningvms).and_return({ "{xxxx}" => "foo" })
      list = Virtualbox.list
      expect(list[0].state).to eql :running
      expect(list[1].state).to eql :stopped
    end

  end

  describe "#create" do

    let(:vbox) { vbox = instance_double("Vbox") }

    before (:each) do
      @guest = Guest.new
      @guest.name = "foo"
      @guest.dvd {}
      @guest.disk {}
      @guest.interface {|i| i.intnet }

      allow(Vbox).to receive(:new).and_return(vbox)
      allow(vbox).to receive(:name).and_return("bar")
      allow(vbox).to receive(:createvm)
      allow(vbox).to receive(:modifyvm)
      allow(vbox).to receive(:storagectl)
      allow(vbox).to receive(:storageattach)
      allow(vbox).to receive(:createhd)
    end

    it "should create vm" do
      expect(vbox).to receive(:createvm)
      subject.create(@guest)
    end

    it "should set boot order" do
      expect(vbox).to receive(:modifyvm).with(hash_including("boot1" => :net))
      expect(vbox).to receive(:modifyvm).with(hash_including("boot2" => :dvd))
      expect(vbox).to receive(:modifyvm).with(hash_including("boot3" => :disk))
      subject.create(@guest)
    end

    it "should create a disk" do
      expect(vbox).to receive(:createhd)   # TODO make better
      subject.create(@guest)
    end

    it "should attach a disk" do
      expect(vbox).to receive(:storageattach).with(hash_including(:storagectl => "SATA", :type => :hdd))
      subject.create(@guest)
    end

    it "should attach a dvd" do
      expect(vbox).to receive(:storageattach).with(hash_including(:storagectl => "IDE", :type => :dvddrive))
      subject.create(@guest)
    end

    it "should create a network interface" do
      expect(vbox).to receive(:modifyvm).with(hash_including("nic1" => :intnet))
      subject.create(@guest)
    end

    it "should add port forwarding" do
      expect(vbox).to receive(:modifyvm).with(hash_including("nic2" => :nat))
      expect(vbox).to receive(:modifyvm).with(hash_including(:natpf2 => "guestssh,tcp,,2222,,22"))
      @guest.interface {|i| i.nat; i.forward("guestssh", ":2222" => ":22") }
      subject.create(@guest)
    end

    context "when creating multiple hard disks" do

      before (:each) do
        @guest = Guest.new
        @guest.name = "foo"
        @guest.dvd {}
        @guest.disk {}
        @guest.disk {}
      end

      it "should create disks" do
        expect(vbox).to receive(:createhd).twice
        subject.create(@guest)
      end

      it "should attach the disks" do
        expect(vbox).to receive(:storageattach).with(hash_including(:type => :hdd, :port => 0))
        expect(vbox).to receive(:storageattach).with(hash_including(:type => :hdd, :port => 1))
        subject.create(@guest)
      end

    end

  end

end
