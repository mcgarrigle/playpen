
class Forward

  attr_accessor :protocol, :from_ip, :from_port, :to_ip, :to_port

  def initialize(name, options)
    @name     = name
    @protocol = :tcp
  end

  def to_s
    "#{@name},#{@protocol},127.0.0.1,2022,10.0.30.100,22"
  end

end

