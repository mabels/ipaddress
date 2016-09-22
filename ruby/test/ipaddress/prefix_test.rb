require 'test_helper'

class IPAddress::Prefix32Test < Test::Unit::TestCase

  def setup
    @netmask0  = "0.0.0.0"
    @netmask8  = "255.0.0.0"
    @netmask16 = "255.255.0.0"
    @netmask24 = "255.255.255.0"
    @netmask30 = "255.255.255.252"
    @netmasks  = [@netmask0,@netmask8,@netmask16,@netmask24,@netmask30]

    @prefix_hash = {
      "0.0.0.0"         => 0,
      "255.0.0.0"       => 8,
      "255.255.0.0"     => 16,
      "255.255.255.0"   => 24,
      "255.255.255.252" => 30}

    @octets_hash = {
      [0,0,0,0]         => 0,
      [255,0,0,0]       => 8,
      [255,255,0,0]     => 16,
      [255,255,255,0]   => 24,
      [255,255,255,252] => 30}

    @u32_hash = {
      0  => 0,
      8  => 4278190080,
      16 => 4294901760,
      24 => 4294967040,
      30 => 4294967292}

    # @klass = IPAddress::IPAddress::Prefix32
  end

  def test_attributes
    @prefix_hash.values.each do |num|
      prefix = IPAddress::Prefix32.create(num)
      assert_equal num, prefix.num
    end
  end

  def test_parse_netmask
    @prefix_hash.each do |netmask, num|
      prefix = IPAddress.parse_netmask_to_prefix(netmask)
      assert_equal num, prefix
      # assert_instance_of @klass, prefix
    end
  end

  def test_method_to_ip
    @prefix_hash.each do |netmask, num|
      prefix = IPAddress::Prefix32.create(num)
      assert_equal netmask, prefix.to_ip_str
    end
  end

  def test_method_to_s
    prefix = IPAddress::Prefix32.create(8)
    assert_equal "8", prefix.to_s
  end

  def test_method_bits
    prefix = IPAddress::Prefix32.create(16)
    str = "1"*16 + "0"*16
    assert_equal str, prefix.bits
  end

  def test_method_to_u32
    @u32_hash.each do |num,u32|
      assert_equal u32, IPAddress::Prefix32.create(num).netmask.num
    end
  end

  def test_method_plus
    p1 = IPAddress::Prefix32.create 8
    p2 = IPAddress::Prefix32.create 10
    assert_equal 18, p1.add_prefix(p2).num
    assert_equal 12, p1.add(4).num
  end

  def test_method_minus
    p1 = IPAddress::Prefix32.create 8
    p2 = IPAddress::Prefix32.create 24
    assert_equal 16, p1.sub_prefix(p2).num
    assert_equal 16, p2.sub_prefix(p1).num
    assert_equal 20, p2.sub(4).num
  end

  def test_initialize
    assert_equal nil,  IPAddress::Prefix32.create(33)
    assert_not_equal nil, IPAddress::Prefix32.create(8)
    # assert_instance_of @klass, IPAddress::Prefix32.create(8)
  end

  def test_method_octets
    @octets_hash.each do |arr,pref|
      prefix = IPAddress::Prefix32.create(pref)
      assert_equal prefix.ip_bits.parts(prefix.netmask), arr
    end
  end

  def test_method_brackets
    @octets_hash.each do |arr,pref|
      prefix = IPAddress::Prefix32.create(pref)
      arr.each_with_index do |oct,index|
        assert_equal prefix.ip_bits.parts(prefix.netmask)[index], oct
      end
    end
  end

  def test_method_hostmask
    prefix = IPAddress::Prefix32.create(8)
    assert_equal "0.255.255.255", IPAddress::Ipv4.from_number(prefix.host_mask(), 32).to_s
  end

end # class IPAddress::Prefix32Test


class IPAddress::Prefix128Test < Test::Unit::TestCase

  def setup
    @u128_hash = {
      32  => 340282366841710300949110269838224261120,
      64 => 340282366920938463444927863358058659840,
      96 => 340282366920938463463374607427473244160,
      126 => 340282366920938463463374607431768211452}

    # @klass = IPAddress::IPAddress::Prefix128
  end

  def test_initialize
    assert_equal nil, IPAddress::Prefix128.create(129)
    assert_not_equal nil, IPAddress::Prefix128.create(64)
    # assert_instance_of @klass, IPAddress::Prefix128.create(64)
  end

  def test_method_bits
    prefix = IPAddress::Prefix128.create(64)
    str = "1"*64 + "0"*64
    assert_equal str, prefix.bits
  end

  def test_method_to_u32
    @u128_hash.each do |num,u128|
      assert_equal u128, IPAddress::Prefix128.create(num).netmask.num
    end
  end

end # class IPAddress::Prefix128Test
