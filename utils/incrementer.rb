class Incrementer
  def initialize(i = 0)
    @i = i
  end

  def set(i)
    @i = i
  end

  def inc
    @i = @i + 1
  end

  def inc_after
    i = @i
    inc
    i
  end

  def dec
    @i = @i - 1
  end

  def dec_after
    i = @i
    dec
    i
  end
end
