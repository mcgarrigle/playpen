
class Command 

  def initialize(laboratory)
    @hypervisor = Hypervisor.new
    vms = Hypervisor.status
    @laboratory = laboratory
    @laboratory.guests.each {|g| g.status = vms[g.name] }
  end

  def running
    @laboratory.guests.select {|g| g.status == :running }
  end

  def _list_help_text
    "list: lists guests"
  end

  def _list
    @laboratory.guests.each do |guest|
      puts guest
    end
  end

  def _up_help_text
    "up: starts all guests"
  end

  def _up(*names)
    if names.size == 0
      @laboratory.guests.each {|guest| up(guest) }
    else
      names.each {|name| up(@laboratory.find(name)) }
    end
  end

  def up(guest)
    puts "create #{guest.name} #{guest.status}"
    if guest.status.nil?
      puts "create #{guest.name}"
      @hypervisor.create(guest) 
    end
    unless guest.status == :running
      puts "starting #{guest.name}"
      @hypervisor.start(guest)
    end 
  end

  def _down_help_text
    "down: stop all guests"
  end

  def _down
    @laboratory.guests.each do |guest|
      down(guest)
    end
  end

  def down(guest)
    @hypervisor.stop(guest)
  rescue
  end

  def _delete_help_text
    "delete: stop and delete all guests"
  end

  def _delete
    running.each do |guest|
      @hypervisor.stop(guest)
    end
    @laboratory.guests.each do |guest|
      @hypervisor.destroy(guest)
    end
  end

  def delete(guest)
    @hypervisor.stop(guest)
    @hypervisor.destroy(guest)
  rescue
  end

  def _ssh(host)
    # rules = @laboratory.guests.map {|g| g.interfaces }.map {|a| a.map {|i| i.rules } }.flatten
    # rules = @laboratory.all.guests.interfaces.rules
    rules = []
    @laboratory.guests.each do |g|
      g.interfaces.each do |i|
        i.rules.each do |r|
          rules << r
        end
      end
    end
    p rules
    ssh_rule = rules.select {|r| r.name == "ssh" }.first
    p ssh_rule
  end

  def _help
    methods = self.class.instance_methods.select {|m| m.to_s.end_with? "_help_text" }
    text = methods.map {|method| self.send method }.join("\n")
    puts "\n#{text}"
  end

  def run(*args)
    command = args.shift
    method  = "_#{command}".to_sym
    unless self.respond_to? method
      puts "command '#{command}' not known"
      _help
      exit
    end
    self.send method, *args
  end

end
