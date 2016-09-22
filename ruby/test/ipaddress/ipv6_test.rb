require_relative '../test_helper'

class IPv6Test < Test::Unit::TestCase

  def setup
    #@klass = IPAddress::IPv6

    @compress_addr = {
      "2001:db8:0000:0000:0008:0800:200c:417a" => "2001:db8::8:800:200c:417a",
      "2001:db8:0:0:8:800:200c:417a" => "2001:db8::8:800:200c:417a",
      "ff01:0:0:0:0:0:0:101" => "ff01::101",
      "0:0:0:0:0:0:0:1" => "::1",
      "0:0:0:0:0:0:0:0" => "::"}

    @valid_ipv6 = { # Kindly taken from the python IPy library
      "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210" => 338770000845734292534325025077361652240,
      "1080:0000:0000:0000:0008:0800:200C:417A" => 21932261930451111902915077091070067066,
      "1080:0:0:0:8:800:200C:417A" => 21932261930451111902915077091070067066,
      "1080:0::8:800:200C:417A" => 21932261930451111902915077091070067066,
      "1080::8:800:200C:417A" => 21932261930451111902915077091070067066,
      "FF01:0:0:0:0:0:0:43" => 338958331222012082418099330867817087043,
      "FF01:0:0::0:0:43" => 338958331222012082418099330867817087043,
      "FF01::43" => 338958331222012082418099330867817087043,
      "0:0:0:0:0:0:0:1" => 1,
      "0:0:0::0:0:1" => 1,
      "::1" => 1,
      "0:0:0:0:0:0:0:0" => 0,
      "0:0:0::0:0:0" => 0,
      "::" => 0,
      "::/0" => 0,
      "1080:0:0:0:8:800:200C:417A" => 21932261930451111902915077091070067066,
      "1080::8:800:200C:417A" => 21932261930451111902915077091070067066}

    @invalid_ipv6 = [":1:2:3:4:5:6:7",
                     ":1:2:3:4:5:6:7",
                     "2002:516:2:200",
                     "dd"]

    @networks = {
      "2001:db8:1:1:1:1:1:1/32" => "2001:db8::/32",
      "2001:db8:1:1:1:1:1::/32" => "2001:db8::/32",
      "2001:db8::1/64" => "2001:db8::/64"}

    @ip = IPAddress.parse "2001:db8::8:800:200c:417a/64"
    @network = IPAddress.parse "2001:db8:8:800::/64"
    @arr = [8193,3512,0,0,8,2048,8204,16762]
    @hex = "20010db80000000000080800200c417a"
  end

  def test_attribute_address
    addr = "2001:0db8:0000:0000:0008:0800:200c:417a"
    assert_equal addr, @ip.to_s_uncompressed
  end

  def test_initialize
    #assert_instance_of @klass, @ip
    @valid_ipv6.keys.each do |ip|
      assert_not_equal nil, IPAddress.parse(ip)
    end
    @invalid_ipv6.each do |ip|
      assert_equal nil, IPAddress.parse(ip)
    end
    assert_equal 64, @ip.prefix.num

    assert_equal "::ffff:10.1.1.1", IPAddress.parse("::10.1.1.1").to_s_mapped
  end

  def test_attribute_groups
    assert_equal @arr, @ip.ip_bits.parts(@ip.host_address)
  end

  def test_method_hexs
    assert_equal "2001:0db8:0000:0000:0008:0800:200c:417a", @ip.to_s_uncompressed
  end

  def test_method_to_i
    @valid_ipv6.each do |ip,num|
      assert_equal num, IPAddress.parse(ip).host_address.num
    end
  end

  def test_method_bits
    bits = "0010000000000001000011011011100000000000000000000" +
      "000000000000000000000000000100000001000000000000010000" +
      "0000011000100000101111010"
    assert_equal bits, @ip.bits
  end

  def test_method_prefix=()
    ip = IPAddress.parse "2001:db8::8:800:200c:417a"
    assert_equal 128, ip.prefix.num
    ip = ip.change_prefix(64)
    assert_equal 64, ip.prefix.num
    assert_equal "2001:db8::8:800:200c:417a/64", ip.to_string
  end

  def test_method_mapped?
    assert_equal false, @ip.mapped?
    ip6 = IPAddress.parse "::ffff:1234:5678"
    assert_equal true, ip6.mapped?
  end

  # def test_method_literal
  #   str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net"
  #   assert_equal str, @ip.literal
  # end

  def test_method_group
    @arr.each_with_index do |val,index|
      assert_equal val, @ip.ip_bits.parts(@ip.host_address)[index]
    end
  end

  def test_method_ipv4?
    assert_equal false, @ip.ipv4?
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

  def test_method_network?
    assert_equal true, @network.network?
    assert_equal false, @ip.network?
  end

  def test_method_network_u128
    assert_equal 42540766411282592856903984951653826560, @ip.network.host_address.num
  end

  def test_method_broadcast_u128
    assert_equal 42540766411282592875350729025363378175, @ip.broadcast.host_address.num
  end

  def test_method_size
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/64")
    assert_equal 2**64, ip.size.num
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32")
    assert_equal 2**96, ip.size.num
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120")
    assert_equal 2**8, ip.size.num
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124")
    assert_equal 2**4, ip.size.num
  end

  def test_method_include?
    assert_equal true, @ip.include?(@ip)
    # test prefix on same address
    included = IPAddress.parse "2001:db8::8:800:200c:417a/128"
    not_included = IPAddress.parse "2001:db8::8:800:200c:417a/46"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
    # test address on same prefix
    included = IPAddress.parse "2001:db8::8:800:200c:0/64"
    not_included = IPAddress.parse "2001:db8:1::8:800:200c:417a/64"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
    # general test
    included = IPAddress.parse "2001:db8::8:800:200c:1/128"
    not_included = IPAddress.parse "2001:db8:1::8:800:200c:417a/76"
    assert_equal true, @ip.include?(included)
    assert_equal false, @ip.include?(not_included)
  end

  def test_method_to_hex
    assert_equal @hex, @ip.to_hex
  end

  def test_method_to_s
    assert_equal "2001:db8::8:800:200c:417a", @ip.to_s
  end

  def test_method_to_string
    assert_equal "2001:db8::8:800:200c:417a/64", @ip.to_string
  end

  def test_method_to_string_uncompressed
    str = "2001:0db8:0000:0000:0008:0800:200c:417a/64"
    assert_equal str, @ip.to_string_uncompressed
  end

  def test_method_data
    if RUBY_VERSION < "2.0"
      str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
    else
      str = " \x01\r\xB8\x00\x00\x00\x00\x00\b\b\x00 \fAz".b
    end
    assert_equal str, @ip.data
  end

  def test_method_reverse
    str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
    assert_equal str, IPAddress.parse("3ffe:505:2::f").dns_reverse
  end

  def test_method_rev_domains
    assert_equal ["e.ip6.arpa", "f.ip6.arpa"], IPAddress.parse("f000:f100::/3").dns_rev_domains
    assert_equal ["2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"], IPAddress.parse("fea3:f120::/15").dns_rev_domains
    assert_equal ["f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"], IPAddress.parse("3a03:2f80:f::/48").dns_rev_domains

    assert_equal ["0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                  "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa"],
                  IPAddress.parse("f000:f100::1234/125").dns_rev_domains
  end

  def test_method_compressed
    assert_equal "1:1:1::1", IPAddress.parse("1:1:1:0:0:0:0:1").to_s
    assert_equal "1:0:1::1", IPAddress.parse("1:0:1:0:0:0:0:1").to_s
    assert_equal "1:2:1:1:1:2:3:0", IPAddress.parse("1:2:1:1:1:2:3::").to_s
    assert_equal "1::1:1:1:2:3:1", IPAddress.parse("1:0:1:1:1:2:3:1").to_s
    assert_equal "1::1:1:0:2:3:1", IPAddress.parse("1:0:1:1::2:3:1").to_s
    assert_equal "1:0:0:1::1", IPAddress.parse("1:0:0:1:0:0:0:1").to_s
    assert_equal "1::1:0:0:1", IPAddress.parse("1:0:0:0:1:0:0:1").to_s
    assert_equal "1::1", IPAddress.parse("1:0:0:0:0:0:0:1").to_s
    #assert_equal "1:1::1:2:0:0:1", IPAddress.parse("1:1:0:1:2::1").to_s
  end

  def test_method_unspecified?
    assert_equal true, IPAddress.parse("::").unspecified?
    assert_equal false, @ip.unspecified?
  end

  def test_method_loopback?
    assert_equal true, IPAddress.parse("::1").loopback?
    assert_equal false, @ip.loopback?
  end

  def test_method_network
    @networks.each do |addr,net|
      ip = IPAddress.parse addr
      # assert_instance_of @klass, ip.network
      assert_equal net, ip.network.to_string
    end
  end

  def test_method_each
    ip = IPAddress.parse("2001:db8::4/125")
    arr = []
    ip.each {|i| arr << i.to_s}
    expected = ["2001:db8::","2001:db8::1","2001:db8::2",
                "2001:db8::3","2001:db8::4","2001:db8::5",
                "2001:db8::6","2001:db8::7"]
    assert_equal expected, arr
  end

  def test_method_each_net
    test_addrs = []
    (0..15).each do |nibble|
      test_addrs << (0..7).to_a.map{(0..3).to_a.map{"%x"%nibble}.join("")}.join(":")
    end
    (0..128).each do |prefix|
      nr_networks = 1<<((128-prefix)%4)
      test_addrs.each do |adr|
        net_adr = IPAddress.parse("#{adr}/#{prefix}")
        ret = net_adr.dns_networks
        assert_equal ret.first.prefix.to_i%4, 0
        assert_equal ret.size, nr_networks
        assert_equal net_adr.network.to_s, ret.first.network.to_s
        assert_equal net_adr.broadcast.to_s, ret.last.broadcast.to_s
#        puts "#{adr}/#{prefix} #{nr_networks} #{ret}"
      end
    end
    assert_equal ["e000::/4","f000::/4"], IPAddress.parse("fd01:db8::4/3").dns_networks.map{|i| i.to_string}
    assert_equal ["3a03:2f80:f::/48"], IPAddress.parse("3a03:2f80:f::/48").dns_networks.map{|i| i.to_string}
  end

  def test_method_compare
    ip1 = IPAddress.parse("2001:db8:1::1/64")
    ip2 = IPAddress.parse("2001:db8:2::1/64")
    ip3 = IPAddress.parse("2001:db8:1::2/64")
    ip4 = IPAddress.parse("2001:db8:1::1/65")

    # ip2 should be greater than ip1
    assert_equal true, ip2 > ip1
    assert_equal false, ip1 > ip2
    assert_equal false, ip2 < ip1
    # ip3 should be less than ip2
    assert_equal true, ip2 > ip3
    assert_equal false, ip2 < ip3
    # ip1 should be less than ip3
    assert_equal true, ip1 < ip3
    assert_equal false, ip1 > ip3
    assert_equal false, ip3 < ip1
    # ip1 should be equal to itself
    assert_equal true, ip1 == ip1
    # ip4 should be greater than ip1
    assert_equal true, ip1 < ip4
    assert_equal false, ip1 > ip4
    # test sorting
    arr = ["2001:db8:1::1/64","2001:db8:1::1/65",
           "2001:db8:1::2/64","2001:db8:2::1/64"]
    assert_equal arr, [ip1,ip2,ip3,ip4].sort.map{|s| s.to_string}
  end

  def test_classmethod_expand
    compressed = "2001:db8:0:cd30::"
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    assert_equal expanded, IPAddress.parse(compressed).to_s_uncompressed
    assert_not_equal expanded, IPAddress.parse("2001:0db8:0::cd3").to_s
    assert_not_equal expanded, IPAddress.parse("2001:0db8::cd30").to_s
    assert_not_equal expanded, IPAddress.parse("2001:0db8::cd3").to_s
  end

  def test_classmethod_compress
    compressed = "2001:db8:0:cd30::"
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    assert_equal compressed, IPAddress.parse(expanded).to_s
    assert_not_equal compressed, IPAddress.parse("2001:0db8:0::cd3").to_s_uncompressed
    assert_not_equal compressed, IPAddress.parse("2001:0db8::cd30").to_s_uncompressed
    assert_not_equal compressed, IPAddress.parse("2001:0db8::cd3").to_s_uncompressed
  end

  def test_classmethod_parse_data
    str = " \001\r\270\000\000\000\000\000\b\b\000 \fAz"
    ip = IPAddress::Ipv6.parse_data str
    # assert_instance_of @klass, ip
    assert_equal "2001:0db8:0000:0000:0008:0800:200c:417a", ip.to_s_uncompressed
    assert_equal "2001:db8::8:800:200c:417a/128", ip.to_string
  end

  def test_classhmethod_parse_u128
    @valid_ipv6.each do |ip,num|
      assert_equal IPAddress.parse(ip).to_s, IPAddress::Ipv6.from_number(IPAddress::Crunchy.from_number(num), 128).to_s
    end
  end

  def test_classmethod_parse_hex
    assert_equal @ip.to_s, IPAddress::Ipv6.from_number(IPAddress::Crunchy.from_string(@hex, 16),64).to_s
  end

end # class IPv6Test

class IPv6UnspecifiedTest < Test::Unit::TestCase

  def setup
    # @klass = IPAddress::IPv6::Unspecified
    @ip = IPAddress::Ipv6Unspec.create
    @s = "::"
    @str = "::/128"
    @string = "0000:0000:0000:0000:0000:0000:0000:0000/128"
    @u128 = 0
    @address = "::"
  end

  def test_initialize
    assert_not_equal nil, IPAddress.parse("::")
    # assert_instance_of @klass, @ip
  end

  def test_attributes
    assert_equal @address, @ip.to_s
    assert_equal 128, @ip.prefix.num
    assert_equal true, @ip.unspecified?
    assert_equal @s, @ip.to_s
    assert_equal @str, @ip.to_string
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.host_address.num
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

end # class IPv6UnspecifiedTest


class IPv6LoopbackTest < Test::Unit::TestCase

  def setup
    # @klass = IPAddress::IPv6::Loopback
    @ip = IPAddress::Ipv6Loopback.create
    @s = "::1"
    @str = "::1/128"
    @string = "0000:0000:0000:0000:0000:0000:0000:0001/128"
    @u128 = 1
    @address = "::1"
  end

  def test_initialize
    assert_not_equal nil, IPAddress.parse("::1")
    # assert_instance_of @klass, @ip
  end

  def test_attributes
    assert_equal @address, @ip.to_s
    assert_equal 128, @ip.prefix.num
    assert_equal true, @ip.loopback?
    assert_equal @s, @ip.to_s
    assert_equal @str, @ip.to_string
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.host_address.num
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

end # class IPv6LoopbackTest

class IPv6MappedTest < Test::Unit::TestCase

  def setup
    # @klass = IPAddress::IPv6::Mapped
    @ip = IPAddress.parse("::172.16.10.1")
    @s = "::ffff:172.16.10.1"
    @str = "::ffff:172.16.10.1/32"
    @string = "0000:0000:0000:0000:0000:ffff:ac10:0a01/128"
    @u128 = 281473568475649
    @address = "::ffff:ac10:a01"

    @valid_mapped = {'::13.1.68.3' => 281470899930115,
      '0:0:0:0:0:ffff:129.144.52.38' => 281472855454758,
      '::ffff:129.144.52.38' => 281472855454758}

    @valid_mapped_ipv6 = {'::ffff:0d01:4403' => 281470899930115,
      '0:0:0:0:0:ffff:8190:3426' => 281472855454758,
      '::ffff:8190:3426' => 281472855454758}

    @valid_mapped_ipv6_conversion = {'::ffff:0d01:4403' => "13.1.68.3",
      '0:0:0:0:0:ffff:8190:3426' => "129.144.52.38",
      '::ffff:8190:3426' => "129.144.52.38"}

  end

  def test_initialize
    assert_not_equal nil, IPAddress.parse("::172.16.10.1")
    # assert_instance_of @klass, @ip
    @valid_mapped.each do |ip, u128|
      assert_not_equal nil, IPAddress.parse(ip)
      assert_equal u128, IPAddress.parse(ip).host_address.num
    end
    @valid_mapped_ipv6.each do |ip, u128|
      assert_not_equal nil, IPAddress.parse(ip)
      assert_equal u128, IPAddress.parse(ip).host_address.num
    end
  end

  def test_mapped_from_ipv6_conversion
    @valid_mapped_ipv6_conversion.each do |ip6,ip4|

      assert_equal ip4, IPAddress.parse(ip6).mapped.to_s
    end
  end

  def test_attributes
    assert_equal @address, @ip.to_s
    assert_equal 128, @ip.prefix.num
    assert_equal @s, @ip.to_s_mapped
    assert_equal @str, @ip.to_string_mapped
    assert_equal @string, @ip.to_string_uncompressed
    assert_equal @u128, @ip.host_address.num
  end

  def test_method_ipv6?
    assert_equal true, @ip.ipv6?
  end

  def test_mapped?
    assert_equal true, @ip.mapped?
  end

end # class IPv6MappedTest
