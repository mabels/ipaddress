class IPAddress
  class ResultCrunchyParts
    attr_accessor :crunchy, :parts
    def initialize(crunchy, parts)
      @crunchy = crunchy
      @parts = parts
    end
  end
end
