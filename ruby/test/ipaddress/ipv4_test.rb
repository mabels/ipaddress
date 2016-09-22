require_relative '../test_helper'

class IPv4Test < Test::Unit::TestCase

  def setup
    #@klass = IPAddress::IPv4

    @valid_ipv4 = {
      "0.0.0.0/0" => ["0.0.0.0", 0],
      "10.0.0.0" => ["10.0.0.0", 32],
      "10.0.0.1" => ["10.0.0.1", 32],
      "10.0.0.1/24" => ["10.0.0.1", 24],
      "10.0.0.1/255.255.255.0" => ["10.0.0.1", 24]}

    @invalid_ipv4 = ["10.0.0.256",
                     "10.0.0.0.0"]


    @valid_ipv4_range = ["10.0.0.1-254",
                         "10.0.1-254.0",
                         "10.1-254.0.0"]

    @netmask_values = {
      "0.0.0.0/0"        => "0.0.0.0",
      "10.0.0.0/8"       => "255.0.0.0",
      "172.16.0.0/16"    => "255.255.0.0",
      "192.168.0.0/24"   => "255.255.255.0",
      "192.168.100.4/30" => "255.255.255.252"}

    @decimal_values ={
      "0.0.0.0/0"        => 0,
      "10.0.0.0/8"       => 167772160,
      "172.16.0.0/16"    => 2886729728,
      "192.168.0.0/24"   => 3232235520,
      "192.168.100.4/30" => 3232261124}

    @ip = IPAddress.parse("172.16.10.1/24")
    @network = IPAddress.parse("172.16.10.0/24")

    @broadcast = {
      "10.0.0.0/8"       => "10.255.255.255/8",
      "172.16.0.0/16"    => "172.16.255.255/16",
      "192.168.0.0/24"   => "192.168.0.255/24",
      "192.168.100.4/30" => "192.168.100.7/30"}

    @networks = {
      "10.5.4.3/8"       => "10.0.0.0/8",
      "172.16.5.4/16"    => "172.16.0.0/16",
      "192.168.4.3/24"   => "192.168.4.0/24",
      "192.168.100.5/30" => "192.168.100.4/30"}

    @class_a = IPAddress.parse("10.0.0.1/8")
    @class_b = IPAddress.parse("172.16.0.1/16")
    @class_c = IPAddress.parse("192.168.0.1/24")

    @classful = {
      "10.1.1.1"  => 8,
      "150.1.1.1" => 16,
      "200.1.1.1" => 24 }

  end

  def test_initialize
    @valid_ipv4.keys.each do |i|
      ip = IPAddress.parse(i)
      # assert_instance_of @klass, ip
    end
    # assert_instance_of IPAddress::Prefix32, @ip.prefix
    assert_equal nil, IPAddress.parse("")
    assert_not_equal nil, IPAddress.parse("10.0.0.0/8")
  end

  def test_initialize_format_error
    @invalid_ipv4.each do |i|
      assert_equal nil, IPAddress.parse(i)
    end
    assert_equal nil, IPAddress.parse("10.0.0.0/asd")
  end

  def test_initialize_without_prefix
    assert_nothing_raised do
      IPAddress.parse("10.10.0.0")
    end
    ip = IPAddress.parse("10.10.0.0")
    # assert_instance_of IPAddress::Prefix32, ip.prefix
    assert_equal 32, ip.prefix.to_i
  end

  def test_attributes
    @valid_ipv4.each do |arg,attr|
      ip = IPAddress.parse(arg)
      assert_equal attr.first, ip.to_s
      assert_equal attr.last, ip.prefix.to_i
    end
  end

  def test_octets
    ip = IPAddress.parse("10.1.2.3/8")
    assert_equal ip.ip_bits.parts(ip.host_address), [10,1,2,3]
  end

  def test_initialize_should_require_ip
    assert_equal nil, IPAddress.parse("")
  end

  def test_method_data
    if RUBY_VERSION < "2.0"
      assert_equal "\254\020\n\001", @ip.data
    else
      assert_equal "\xAC\x10\n\x01".b, @ip.data
    end
  end

  def test_method_to_string
    @valid_ipv4.each do |arg,attr|
      ip = IPAddress.parse(arg)
      assert_equal attr.join("/"), ip.to_string
    end
  end

  def test_method_to_s
    @valid_ipv4.each do |arg,attr|
      ip = IPAddress.parse(arg)
      assert_equal attr.first, ip.to_s
      ip = IPAddress.parse(arg)
      assert_equal attr.first, ip.to_s
    end
  end

  def test_netmask
    @netmask_values.each do |addr,mask|
      ip = IPAddress.parse(addr)
      assert_equal mask, ip.netmask.to_s
    end
  end

  def test_method_to_u32
    @decimal_values.each do |addr,int|
      ip = IPAddress.parse(addr)
      assert_equal int, ip.host_address.num
    end
  end

  def test_method_network?
    assert_equal true, @network.network?
    assert_equal false, @ip.network?
  end

  def test_one_address_network
    network = IPAddress.parse("172.16.10.1/32")
    assert_equal false, network.network?
  end

  def test_method_broadcast
    @broadcast.each do |addr,bcast|
      ip = IPAddress.parse(addr)
      # assert_instance_of @klass, ip.broadcast
      assert_equal bcast, ip.broadcast.to_string
    end
  end

  def test_method_network
    @networks.each do |addr,net|
      ip = IPAddress.parse addr
      # assert_instance_of @klass, ip.network
      assert_equal net, ip.network.to_string
    end
  end

  def test_method_bits
    ip = IPAddress.parse("127.0.0.1")
    assert_equal "01111111000000000000000000000001", ip.bits
  end

  def test_method_first
    ip = IPAddress.parse("192.168.100.0/24")
    # assert_instance_of @klass, ip.first
    assert_equal "192.168.100.1", ip.first.to_s
    ip = IPAddress.parse("192.168.100.50/24")
    # assert_instance_of @klass, ip.first
    assert_equal "192.168.100.1", ip.first.to_s
  end

  def test_method_last
    ip = IPAddress.parse("192.168.100.0/24")
    # assert_instance_of @klass, ip.last
    assert_equal  "192.168.100.254", ip.last.to_s
    ip = IPAddress.parse("192.168.100.50/24")
    # assert_instance_of @klass, ip.last
    assert_equal  "192.168.100.254", ip.last.to_s
  end

  def test_method_each_host
    ip = IPAddress.parse("10.0.0.1/29")
    arr = []
    ip.each_host {|i| arr << i.to_s}
    expected = ["10.0.0.1","10.0.0.2","10.0.0.3",
                "10.0.0.4","10.0.0.5","10.0.0.6"]
    assert_equal expected, arr
  end

  def test_method_each
    ip = IPAddress.parse("10.0.0.1/29")
    arr = []
    ip.each {|i| arr << i.to_s}
    expected = ["10.0.0.0","10.0.0.1","10.0.0.2",
                "10.0.0.3","10.0.0.4","10.0.0.5",
                "10.0.0.6","10.0.0.7"]
    assert_equal expected, arr
  end

  def test_method_size
    ip = IPAddress.parse("10.0.0.1/29")
    assert_equal 8, ip.size
  end

  def test_method_hosts
    ip = IPAddress.parse("10.0.0.1/29")
    expected = ["10.0.0.1","10.0.0.2","10.0.0.3",
                "10.0.0.4","10.0.0.5","10.0.0.6"]
    hosts = []
    ip.each_host { |i| hosts << i.to_s }
    assert_equal expected, hosts
  end

  def test_method_network_u32
    assert_equal 2886732288, @ip.network.host_address.num
  end

  def test_method_broadcast_u32
    assert_equal 2886732543, @ip.broadcast.host_address.num
  end

  def test_method_include?
    ip = IPAddress.parse("192.168.10.100/24")
    addr = IPAddress.parse("192.168.10.102/24")
    assert_equal true, ip.include?(addr)
    assert_equal false, ip.include?(IPAddress.parse("172.16.0.48"))
    ip = IPAddress.parse("10.0.0.0/8")
    assert_equal true, ip.include?(IPAddress.parse("10.0.0.0/9"))
    assert_equal true, ip.include?(IPAddress.parse("10.1.1.1/32"))
    assert_equal true, ip.include?(IPAddress.parse("10.1.1.1/9"))
    assert_equal false, ip.include?(IPAddress.parse("172.16.0.0/16"))
    assert_equal false, ip.include?(IPAddress.parse("10.0.0.0/7"))
    assert_equal false, ip.include?(IPAddress.parse("5.5.5.5/32"))
    assert_equal false, ip.include?(IPAddress.parse("11.0.0.0/8"))
    ip = IPAddress.parse("13.13.0.0/13")
    assert_equal false, ip.include?(IPAddress.parse("13.16.0.0/32"))
  end

  def test_method_include_all?
    ip = IPAddress.parse("192.168.10.100/24")
    addr1 = IPAddress.parse("192.168.10.102/24")
    addr2 = IPAddress.parse("192.168.10.103/24")
    assert_equal true, ip.include_all?(addr1,addr2)
    assert_equal false, ip.include_all?(addr1, IPAddress.parse("13.16.0.0/32"))
  end

  def test_method_ipv4?
    assert_equal true, @ip.ipv4?
  end

  def test_method_ipv6?
    assert_equal false, @ip.ipv6?
  end

  def test_method_private?
    assert_equal true, IPAddress.parse("192.168.10.50/24").private?
    assert_equal true, IPAddress.parse("192.168.10.50/16").private?
    assert_equal true, IPAddress.parse("172.16.77.40/24").private?
    assert_equal true, IPAddress.parse("172.16.10.50/14").private?
    assert_equal true, IPAddress.parse("10.10.10.10/10").private?
    assert_equal true, IPAddress.parse("10.0.0.0/8").private?
    assert_equal false, IPAddress.parse("192.168.10.50/12").private?
    assert_equal false, IPAddress.parse("3.3.3.3").private?
    assert_equal false, IPAddress.parse("10.0.0.0/7").private?
    assert_equal false, IPAddress.parse("172.32.0.0/12").private?
    assert_equal false, IPAddress.parse("172.16.0.0/11").private?
    assert_equal false, IPAddress.parse("192.0.0.2/24").private?
  end

  def test_method_octet
    parts = @ip.ip_bits.parts(@ip.host_address)
    assert_equal 172, parts[0]
    assert_equal 16, parts[1]
    assert_equal 10, parts[2]
    assert_equal 1, parts[3]
  end

  def test_method_a?
    assert_equal true, IPAddress::Ipv4.is_class_a(@class_a)
    assert_equal false, IPAddress::Ipv4.is_class_a(@class_b)
    assert_equal false, IPAddress::Ipv4.is_class_a(@class_c)
  end

  def test_method_b?
    assert_equal true, IPAddress::Ipv4.is_class_b(@class_b)
    assert_equal false, IPAddress::Ipv4.is_class_b(@class_a)
    assert_equal false, IPAddress::Ipv4.is_class_b(@class_c)
  end

  def test_method_c?
    assert_equal true, IPAddress::Ipv4.is_class_c(@class_c)
    assert_equal false, IPAddress::Ipv4.is_class_c(@class_a)
    assert_equal false, IPAddress::Ipv4.is_class_c(@class_b)
  end

  def test_method_to_ipv6
    assert_equal "::ac10:a01", @ip.to_ipv6.to_s
  end

  def test_method_reverse
    # kaputt
    assert_equal "10.16.172.in-addr.arpa", @ip.dns_reverse
  end

  def test_method_rev_domains
    assert_equal ["4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"], IPAddress.parse("173.17.5.1/23").dns_rev_domains
    assert_equal ["16.173.in-addr.arpa", "17.173.in-addr.arpa"], IPAddress.parse("173.17.1.1/15").dns_rev_domains
    assert_equal ["172.in-addr.arpa", "173.in-addr.arpa"], IPAddress.parse("173.17.1.1/7").dns_rev_domains
    assert_equal             [
                "0.1.17.173.in-addr.arpa",
                "1.1.17.173.in-addr.arpa",
                "2.1.17.173.in-addr.arpa",
                "3.1.17.173.in-addr.arpa",
                "4.1.17.173.in-addr.arpa",
                "5.1.17.173.in-addr.arpa",
                "6.1.17.173.in-addr.arpa",
                "7.1.17.173.in-addr.arpa"
            ], IPAddress.parse("173.17.1.1/29").dns_rev_domains
    assert_equal ["1.17.174.in-addr.arpa"], IPAddress.parse("174.17.1.1/24").dns_rev_domains
    assert_equal ["17.175.in-addr.arpa"], IPAddress.parse("175.17.1.1/16").dns_rev_domains
    assert_equal ["176.in-addr.arpa"], IPAddress.parse("176.17.1.1/8").dns_rev_domains
    assert_equal ["in-addr.arpa"], IPAddress.parse("177.17.1.1/0").dns_rev_domains
    assert_equal ["1.1.17.178.in-addr.arpa"], IPAddress.parse("178.17.1.1/32").dns_rev_domains
  end

  def test_method_compare
    ip1 = IPAddress.parse("10.1.1.1/8")
    ip2 = IPAddress.parse("10.1.1.1/16")
    ip3 = IPAddress.parse("172.16.1.1/14")
    ip4 = IPAddress.parse("10.1.1.1/8")

    # ip2 should be greater than ip1
    assert_equal true, ip1 < ip2
    assert_equal false, ip1 > ip2
    assert_equal false, ip2 < ip1
    # ip2 should be less than ip3
    assert_equal true, ip2 < ip3
    assert_equal false, ip2 > ip3
    # ip1 should be less than ip3
    assert_equal true, ip1 < ip3
    assert_equal false, ip1 > ip3
    assert_equal false, ip3 < ip1
    # ip1 should be equal to itself
    assert_equal true, ip1 == ip1
    # ip1 should be equal to ip4
    assert_equal true, ip1 == ip4
    # test sorting
    arr = ["10.1.1.1/8","10.1.1.1/16","172.16.1.1/14"]
    assert_equal arr, [ip1,ip2,ip3].sort.map{|s| s.to_string}
    # test same prefix
    ip1 = IPAddress.parse("10.0.0.0/24")
    ip2 = IPAddress.parse("10.0.0.0/16")
    ip3 = IPAddress.parse("10.0.0.0/8")
    arr = ["10.0.0.0/8","10.0.0.0/16","10.0.0.0/24"]
    assert_equal arr, [ip1,ip2,ip3].sort.map{|s| s.to_string}
  end

  def test_method_minus
    ip1 = IPAddress.parse("10.1.1.1/8")
    ip2 = IPAddress.parse("10.1.1.10/8")
    assert_equal 9, ip2.sub(ip1)
    assert_equal 9, ip1.sub(ip2)
  end

  def test_method_plus
    ip1 = IPAddress.parse("172.16.10.1/24")
    ip2 = IPAddress.parse("172.16.11.2/24")
    assert_equal ["172.16.10.0/23"], (ip1.add(ip2)).map{|i| i.to_string}

    ip2 = IPAddress.parse("172.16.12.2/24")
    assert_equal [ip1.network.to_string, ip2.network.to_string],
    (ip1.add(ip2)).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_equal ["10.0.0.0/23","10.0.2.0/24"], (ip1.add(ip2)).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_equal ["10.0.0.0/23","10.0.2.0/24"], (ip2.add(ip1)).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/16")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_equal ["10.0.0.0/16"], (ip1.add(ip2)).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.1.0.0/24")
    assert_equal ["10.0.0.0/23","10.1.0.0/24"], (ip1.add(ip2)).map{|i| i.to_string}

  end

  def test_method_netmask_equal
    ip = IPAddress.parse("10.1.1.1/16")
    assert_equal 16, ip.prefix.to_i
    ip = ip.change_netmask("255.255.255.0")
    assert_equal 24, ip.prefix.to_i
  end

  def test_method_split
    assert_equal nil, @ip.split(0)
    assert_equal nil, @ip.split(257)

    assert_equal @ip.network, @ip.split(1).first

    arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
           "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
           "172.16.10.192/27", "172.16.10.224/27"]
    assert_equal arr, @network.split(8).map {|s| s.to_string}
    arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
           "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
           "172.16.10.192/26"]
    assert_equal arr, @network.split(7).map {|s| s.to_string}
    arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
           "172.16.10.96/27", "172.16.10.128/26", "172.16.10.192/26"]
    assert_equal arr, @network.split(6).map {|s| s.to_string}
    arr = ["172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
           "172.16.10.96/27", "172.16.10.128/25"]
    assert_equal arr, @network.split(5).map {|s| s.to_string}
    arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
           "172.16.10.192/26"]
    assert_equal arr, @network.split(4).map {|s| s.to_string}
    arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]
    assert_equal arr, @network.split(3).map {|s| s.to_string}
    arr = ["172.16.10.0/25", "172.16.10.128/25"]
    assert_equal arr, @network.split(2).map {|s| s.to_string}
    arr = ["172.16.10.0/24"]
    assert_equal arr, @network.split(1).map {|s| s.to_string}
  end

  def test_method_subnet
    assert_equal nil, @network.subnet(23)
    assert_equal nil, @network.subnet(33)
    assert_not_equal nil, @ip.subnet(30)
    arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
           "172.16.10.192/26"]
    assert_equal arr, @network.subnet(26).map {|s| s.to_string}
    arr = ["172.16.10.0/25", "172.16.10.128/25"]
    assert_equal arr, @network.subnet(25).map {|s| s.to_string}
    arr = ["172.16.10.0/24"]
    assert_equal arr, @network.subnet(24).map {|s| s.to_string}
  end

  def test_method_supernet
    assert_equal nil, @ip.supernet(24)
    assert_equal "0.0.0.0/0", @ip.supernet(0).to_string
    assert_equal "0.0.0.0/0", @ip.supernet(-2).to_string
    assert_equal "172.16.10.0/23", @ip.supernet(23).to_string
    assert_equal "172.16.8.0/22", @ip.supernet(22).to_string
  end

  def test_classmethod_parse_u32
    @decimal_values.each do  |addr,int|
      ip = IPAddress::Ipv4.from_number(IPAddress::Crunchy.from_number(int), 32)
      ip.prefix = addr.split("/").last.to_i
      assert_equal ip.to_string, addr
    end
  end

  # def test_classhmethod_extract
  #   str = "foobar172.16.10.1barbaz"
  #   assert_equal "172.16.10.1", IPAddress.extract(str).to_s
  # end

  def test_classmethod_summarize

    # Should return self if only one network given
    assert_equal IPAddress.to_s_vec([@ip.network]),
                 IPAddress.to_s_vec(IPAddress.summarize([@ip]))

    # Summarize homogeneous networks
    ip1 = IPAddress.parse("172.16.10.1/24")
    ip2 = IPAddress.parse("172.16.11.2/24")
    assert_equal ["172.16.10.0/23"], IPAddress.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.1/24")
    ip2 = IPAddress.parse("10.0.1.1/24")
    ip3 = IPAddress.parse("10.0.2.1/24")
    ip4 = IPAddress.parse("10.0.3.1/24")
    assert_equal ["10.0.0.0/22"], IPAddress.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    assert_equal ["10.0.0.0/22"], IPAddress.summarize(ip4,ip3,ip2,ip1).map{|i| i.to_string}

    # Summarize non homogeneous networks
    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_equal ["10.0.0.0/23","10.0.2.0/24"], IPAddress.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/16")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_equal ["10.0.0.0/16"], IPAddress.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.1.0.0/24")
    assert_equal ["10.0.0.0/23","10.1.0.0/24"], IPAddress.summarize(ip1,ip2).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/23")
    ip3 = IPAddress.parse("10.0.4.0/24")
    ip4 = IPAddress.parse("10.0.6.0/24")
    assert_equal ["10.0.0.0/22","10.0.4.0/24","10.0.6.0/24"],
              IPAddress.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.1.1/24")
    ip2 = IPAddress.parse("10.0.2.1/24")
    ip3 = IPAddress.parse("10.0.3.1/24")
    ip4 = IPAddress.parse("10.0.4.1/24")
    result = ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
    assert_equal result, IPAddress.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    assert_equal result, IPAddress.summarize(ip4,ip3,ip2,ip1).map{|i| i.to_string}

    ip1 = IPAddress.parse("10.0.1.1/24")
    ip2 = IPAddress.parse("10.10.2.1/24")
    ip3 = IPAddress.parse("172.16.0.1/24")
    ip4 = IPAddress.parse("172.16.1.1/24")
    result = ["10.0.1.0/24","10.10.2.0/24","172.16.0.0/23"]
    assert_equal result, IPAddress.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}

    ips = [IPAddress.parse("10.0.0.12/30"),
           IPAddress.parse("10.0.100.0/24")]
    result = ["10.0.0.12/30", "10.0.100.0/24"]
    assert_equal result, IPAddress.summarize(*ips).map{|i| i.to_string}

    ips = [IPAddress.parse("172.16.0.0/31"),
           IPAddress.parse("10.10.2.1/32")]
    result = ["10.10.2.1/32", "172.16.0.0/31"]
    assert_equal result, IPAddress.summarize(*ips).map{|i| i.to_string}

    ips = [IPAddress.parse("172.16.0.0/32"),
           IPAddress.parse("10.10.2.1/32")]
    result = ["10.10.2.1/32", "172.16.0.0/32"]
    assert_equal result, IPAddress.summarize(*ips).map{|i| i.to_string}

  end

  def test_classmethod_parse_data
    ip = IPAddress::Ipv4.parse_data "\254\020\n\001"
    # assert_instance_of IPAddress, ip
    assert_equal "172.16.10.1", ip.to_s
    assert_equal "172.16.10.1/32", ip.to_string
  end

  def test_classmethod_parse_classful
    @classful.each do |ip,prefix|
      res = IPAddress::Ipv4.parse_classful(ip)
      assert_equal prefix, res.prefix.num
      assert_equal "#{ip}/#{prefix}", res.to_string
    end
    assert_equal nil, IPAddress::Ipv4.parse_classful("192.168.256.257")
  end

end # class IPv4Test
