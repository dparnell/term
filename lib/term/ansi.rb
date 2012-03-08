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
          @csi = []
        else
          @state = :ground
          handle(byte)
        end
   
      when :csi
        case byte
        when 48,49,50,51,52,53,54,55,56,57,58,59
          @csi << byte

        else
          csi = @csi.pack('c*').split(';').map{|p| p.to_i}

          case byte
          when 65 # A
            @terminal.cursor_up(csi[0] || 1)
          when 66 # B
            @terminal.cursor_down(csi[0] || 1)
          when 67 # C
            @terminal.cursor_forward(csi[0] || 1)
          when 68 # D
            @terminal.cursor_backward(csi[0] || 1)
          when 69 # E
            @terminal.cursor_down(csi[0] || 1)
            @terminal.cursor_x = 0
          when 70 # F
            @terminal.cursor_up(csi[0] || 1)
            @terminal.cursor_x = 0
          when 72, 102 # H or f
            @terminal.cursor_x = (csi[1] || 1) - 1
            @terminal.cursor_y = (csi[0] || 1) - 1
          when 74 # J
            if csi[0] == 2
              @terminal.clear
              @terminal.cursor_x = 0
              @terminal.cursor_y = 0
            end
          end
          @state = :ground
        end
      end
    end
  end

end
