class IPAddress


  class Last
    attr_reader :val, :max_poses, :ret
    attr_writer :val

    def initialize()
      @val = nil
      @max_poses = {}
      @ret = []
    end

    def handle_last()
      if (nil == val)
        return
      end

      _last = @val
      max_rles = @max_poses[_last.part]
      if (max_rles == nil)
        max_rles = []
        @max_poses[_last.part] = max_rles
      end

      # console.log(_last.part, @max_poses)
      # puts ">>>>#{@ret}  #{@max_poses} #{max_rles}"
      max_rles.each do |idx|
        # puts "#{@ret}  #{max_rles} #{idx}"
        prev = @ret[idx]
        if (prev.cnt > _last.cnt)
          # console.log(`>>>>> last=${_last}->${idx}->prev=${prev}`)
          _last.max = false
        elsif (prev.cnt == _last.cnt)
          # nothing
        elsif (prev.cnt < _last.cnt)
          # console.log(`<<<<< last=${_last}->${idx}->prev=${prev}`)
          prev.max = false
        end
      end

      #println!("push:{}:{:?}", self.ret.len(), _last)
      max_rles.push(@ret.length)
      _last.pos = @ret.length
      @ret.push(_last)
    end
  end

  class Rle
    attr_accessor :part, :pos, :cnt, :max

    def initialize(obj)
      @part = obj[:part]
      @pos = obj[:pos]
      @cnt = obj[:cnt]
      @max = obj[:max]
    end

    def toString()
      return "<Rle@part:#{@part},pos:#{@pos},cnt:#{@cnt},max:#{@max}>"
    end

    def eq(other)
      return @part == other.part && @pos == other.pos &&
        @cnt == other.cnt && @max == other.max
    end

    def ne(other)
      return !eq(other)
    end

    def self.code(parts)
      last = Last.new()
      # println!("code")
      parts.length.times do |i|
        part = parts[i]
        # console.log(`part:${part}`)
        if (last.val && last.val.part == part)
          last.val.cnt += 1
        else
          last.handle_last()
          last.val = Rle.new({ part: part, pos: 0, cnt: 1, max: true })
        end
      end

      last.handle_last()
      return last.ret
    end
  end
end
