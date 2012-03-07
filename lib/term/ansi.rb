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
        when 127
          @terminal.delete
        else
          @terminal.put_byte(byte)
        end
      end
    end
  end

end
