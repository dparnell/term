module Term
  
  class Terminal
    attr_accessor :width, :height, :mode
    attr_accessor :cursor_x, :cursor_y

    def initialize(options = {})
      @width = options[:width] || 80
      @height = options[:height] || 25
      @mode = options[:mode] || :ansi
      @cursor_x = 0
      @cursor_y = 0

      @dirty = {}
      @characters = []
      clear
      @dirty = {}

      klass = Term.const_get("#{@mode.to_s.upcase}StateMachine")
      @machine = klass.new(self)
    end

    def clear(range = :all)
      case range
      when :to_end
        start = @cursor_x + @cursor_y * @width
        finish = @width*@height-1
      when :to_start
        start = 0
        finish = @cursor_x + @cursor_y * @width
      when :all
        start = 0 
        finish = @width*@height-1
      when :to_start_of_line
        start = @cursor_y * @width
        finish = start + @cursor_x
      when :to_end_of_line
        start = @cursor_y * @width + @cursor_x
        finish = @cursor_y * @width + @width - 1
      when :line
        start = @cursor_y * @width
        finish = start + @width - 1
      else
        raise "Unknown clear #{range.inspect}"
      end

      (start..finish).each do |i| 
        @dirty[i] = true
        @characters[i] = 32 
      end
    end

    def dirty?
      !@dirty.empty?
    end

    def put_byte(b)
      pos = @cursor_x+@width*@cursor_y
      @characters[pos] = b
      @dirty[pos] = true
      @cursor_x = @cursor_x + 1
      if @cursor_x == @width
        @cursor_x = 0
        line_feed
      end
    end

    def bell
      # do nothing
    end

    def backspace
      @cursor_x = @cursor_x - 1
      if @cursor_x < 0
        @cursor_x == 0
      end
      pos = @cursor_x+@width*@cursor_y
      eol_pos = @width*@cursor_y + @width - 1
      @characters.slice!(pos)
      @characters.insert(eol_pos, 32)

      (pos..eol_pos).each do |i|
        @dirty[i] = true
      end
    end

    def carriage_return
      @cursor_x = 0
    end

    def line_feed
      @cursor_y = @cursor_y + 1
      
      if @cursor_y == @height
        @cursor_y = @height - 1
        scroll_up(1)
      end
    end

    def scroll_up(rows)
      if rows < @height
        @characters.slice!(0, @width*rows)
        @characters = @characters + ([32]*(@width*rows))
        # the whole screen is now dirty
        (0..@width*@height-1).each do |i|
          @dirty[i] = true
        end
      else
        clear
      end
    end

    def scroll_down(rows)
      if rows < @height
        @characters = ([32]*(@width*rows) + @characters).slice(0, @width*@height)
      else
        clear
      end
    end

    def delete
      pos = @cursor_x+@width*@cursor_y
      eol_pos = @width*@cursor_y + @width - 1
      @characters.slice!(pos)
      @characters.insert(eol_pos, 32)

      (pos..eol_pos).each do |i|
        @dirty[i] = true
      end
    end

    def cursor_up(lines)
      @cursor_y = @cursor_y - lines
      if @cursor_y < 0
        @cursor_y = 0
      end
    end

    def cursor_down(lines)
      @cursor_y = @cursor_y + lines
      if @cursor_y >= @height
        @cursor_y = @height - 1
      end
    end

    def cursor_forward(cols)
      @cursor_x = @cursor_x + cols
      if @cursor_x >= @width
        @cursor_x = @width - 1
      end
    end

    def cursor_backward(cols)
      @cursor_x = @cursor_x - cols
      if @cursor_x < 0
        @cursor_x = 0
      end
    end

    def accept(s)
      s.each_byte do |b|
        @machine.handle(b)
      end
    end 

    def character_at(x,y)
      @characters[x + y*@width].to_i
    end

    def lines
      (1..@height).collect do |y|
        line(y-1)
      end
    end

    def line(y)
      @characters.slice(y*@width, @width).pack('c*')
    end

    def to_s
      lines.join("\n")
    end

  end

end
