module Term
  class ANSIStateMachine
    def initialize(terminal)
      @terminal = terminal
      @state = :ground
    end

    def handle(byte)
      case @state
      when :ground
        case byte
        when 7
          @terminal.bell
        when 8
          @terminal.backspace
        when 10
          @terminal.line_feed
        when 13
          @terminal.carriage_return
        when 27
          @state = :escape
        when 127
          @terminal.delete
        else
          @terminal.put_byte(byte)
        end

      when :escape
        case byte
        when 91 # [
          @state = :csi
        else
          @state = :ground
          handle(byte)
        end
   
      when :csi
        case byte
        when 50 # 2
          @state = :clear_1
        else
          @state = :ground
          handle(byte)
        end

      when :clear_1
        if byte == 74 # J
          @terminal.clear
          @terminal.cursor_x = 0
          @terminal.cursor_y = 0
          @state = :ground
        else
          @state = :ground
          handle(byte)
        end
      end
    end
  end

end
