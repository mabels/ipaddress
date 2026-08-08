class IPAddress
  class Crunchy
    include Comparable

    attr_accessor :num
    def initialize
      @num = 0
    end

    def <=>(other)
      @num <=> if other.instance_of?(Crunchy)
        other.num
      else
        other
      end
    end

    def clone
      ret = Crunchy.new
      ret.num = @num
      ret
    end

    def self.parse(val)
      from_string(val, 10)
    end

    def self.from_number(val)
      ret = Crunchy.new
      ret.num = val
      ret
    end

    def self.from_string(val, radix)
      ret = Crunchy.new
      ret.num = val.to_i(radix)
      ret
    end

    def compare(y)
      num <=> y.num
    end

    def eq(oth)
      compare(oth) == 0
    end

    def lte(oth)
      compare(oth) <= 0
    end

    def lt(oth)
      compare(oth) < 0
    end

    def gt(oth)
      compare(oth) > 0
    end

    def gte(oth)
      compare(oth) >= 0
    end

    def add(y)
      ret = Crunchy.new
      ret.num = num + y.num
      ret
    end

    def sub(y)
      ret = Crunchy.new
      ret.num = num - y.num
      ret
    end

    def mul(y)
      ret = Crunchy.new
      ret.num = num * y.num
      ret
    end

    def shr(s)
      ret = Crunchy.new
      ret.num = num >> s
      ret
    end

    def shl(s)
      ret = Crunchy.new
      ret.num = num << s
      ret
    end

    def div(y)
      ret = Crunchy.new
      ret.num = num / y.num
      ret
    end

    def mod(y)
      ret = Crunchy.new
      ret.num = num % y.num
      ret
    end

    def mds(y)
      # ret = Crunchy.new
      num % y
    end

    def toString(radix = 10)
      num.to_s(radix)
    end

    ZERO = Crunchy.from_number(0)
    def self.zero
      ZERO
    end

    ONE = Crunchy.from_number(1)
    def self.one
      ONE
    end

    TWO = Crunchy.from_number(2)
    def self.two
      TWO
    end
  end
end
