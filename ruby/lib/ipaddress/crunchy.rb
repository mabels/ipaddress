class IPAddress
  class Crunchy

    include Comparable

    attr_accessor :num
    def initialize()
      @num = 0
    end

    def <=>(oth)
      if oth.instance_of?(Crunchy)
        @num <=> oth.num
      else
        @num <=> oth
      end
    end

    def clone()
      ret = Crunchy.new()
      ret.num = @num
      return ret
    end

    def self.parse(val)
      return self.from_string(val, 10)
    end

    def self.from_number(val)
      ret = Crunchy.new()
      ret.num = val
      return ret
    end

    def self.from_string(val, radix)
      ret = Crunchy.new()
      ret.num = val.to_i(radix)
      return ret
    end

    def compare(y)
      return self.num <=> y.num
    end

    def eq(oth)
      return self.compare(oth) == 0
    end

    def lte(oth)
      return self.compare(oth) <= 0
    end

    def lt(oth)
      return self.compare(oth) < 0
    end

    def gt(oth)
      return self.compare(oth) > 0
    end

    def gte(oth)
      return self.compare(oth) >= 0
    end

    def add(y)
      ret = Crunchy.new
      ret.num = self.num + y.num
      return ret
    end

    def sub(y)
      ret = Crunchy.new
      ret.num = self.num - y.num
      return ret
    end

    def mul(y)
      ret = Crunchy.new
      ret.num = self.num * y.num
      return ret
    end

    def shr(s)
      ret = Crunchy.new
      ret.num = self.num >> s
      return ret
    end

    def shl(s)
      ret = Crunchy.new
      ret.num = self.num << s
      return ret
    end

    def div(y)
      ret = Crunchy.new
      ret.num = self.num / y.num
      return ret
    end

    def mod(y)
      ret = Crunchy.new
      ret.num = self.num % y.num
      return ret
    end

    def mds(y)
      #ret = Crunchy.new
      self.num % y
    end

    def toString(radix=10)
      return self.num.to_s(radix)
    end

    ZERO = Crunchy.from_number(0)
    def self.zero
      return ZERO
    end

    ONE = Crunchy.from_number(1)
    def self.one
      return ONE
    end

    TWO = Crunchy.from_number(2)
    def self.two
      return TWO
    end
  end
end
