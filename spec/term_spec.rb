require 'spec_helper'

describe Term do

  describe 'creation' do
    let :term do Term::Terminal.new(:mode => :ansi, :width => 80, :height => 25) end

    it 'should create a terminal object' do
      term.should_not be_nil
    end

    it 'should have the correct width' do
      term.width.should == 80
    end

    it 'should have the correct height' do
      term.height.should == 25
    end

    it 'should be an ANSI terminal' do
      term.mode.should == :ansi
    end

    it 'should have the cursor at the top left corner' do
      term.cursor_x.should == 0
      term.cursor_y.should == 0
    end

    it 'should not be dirty' do
      term.should_not be_dirty
    end
  end # creation

  describe 'text' do
    it 'should accept a simple string of characters which moves the cursor and makes the terminal dirty' do
      term = Term::Terminal.new

      term.accept('testing 1234')

      term.cursor_x.should == 12
      term.should be_dirty
    end

    it 'should go onto the next line when too many characters are entered' do
      term = Term::Terminal.new(:width => 16)

      term.accept('0123456789ABCDEF')

      term.cursor_x.should == 0
      term.cursor_y.should == 1
    end
    
    it 'should scroll the screen when too many lines are entered' do
      term = Term::Terminal.new(:width => 16, :height => 4)

      term.accept('a123456789ABCDEF')
      term.accept('b123456789ABCDEF')
      term.accept('c123456789ABCDEF')
      term.accept('d123456789ABCDEF')
      term.accept('e123456789ABCDEF')

      term.cursor_x.should == 0
      term.cursor_y.should == 3

      term.character_at(0,0).should == 'c'[0]
    end
  end # text

  describe 'control characters' do
    it 'must handle the bell character' do
      term = Term::Terminal.new
      term.accept("ABCDEFG\a")
      term.cursor_x.should == 7
      term.to_s.strip.should == 'ABCDEFG'
    end

    it 'must handle the backspace character' do
      term = Term::Terminal.new
      term.accept('ABCDEFG')
      term.cursor_x.should == 7
      term.to_s.strip.should == 'ABCDEFG'
      term.accept("\b1")
      term.cursor_x.should == 7
      term.to_s.strip.should == 'ABCDEF1'
    end

    it 'must drag the text back on a line in response to a backspace without affecting the text on the next line' do
      term = Term::Terminal.new
      term.accept("ABCDEFG\r\n12345")
      
      term.cursor_x = 3
      term.cursor_y = 0
      term.accept("\b")
      term.line(0).strip.should == 'ABDEFG'
      term.cursor_x.should == 2
    end

    it 'must handle the carriage return' do
      term = Term::Terminal.new
      term.accept('ABCDEFG')
      term.cursor_x.should == 7
      term.to_s.strip.should == 'ABCDEFG'
      term.accept("\r")
      term.cursor_x.should == 0
      term.to_s.strip.should == 'ABCDEFG'
    end

    it 'must handle the line feed' do
      term = Term::Terminal.new
      term.accept('ABCDEFG')
      term.cursor_x.should == 7
      term.cursor_y.should == 0
      term.to_s.strip.should == 'ABCDEFG'
      term.accept("\n")
      term.cursor_x.should == 7
      term.cursor_y.should == 1
      term.to_s.strip.should == 'ABCDEFG'
    end
    
    it 'must handle the delete character' do
      term = Term::Terminal.new
      term.accept("ABCDEFG\r\n12345")
      
      term.cursor_x = 3
      term.cursor_y = 0
      term.accept("\177")
      term.line(0).strip.should == 'ABCEFG'
      term.cursor_x.should == 3
    end

  end # control characters

  describe "Escape sequences" do
    
    it 'must handle the clear screen escape sequence' do
      term = Term::Terminal.new
      term.accept("ABCDEFG\r\n12345\r\n")

      term.cursor_x.should == 0
      term.cursor_y.should == 2

      term.accept("\033[2J")
      term.cursor_x.should == 0
      term.cursor_y.should == 0
      term.to_s.strip.should == ''
    end

    it 'must handle the set cursor position escape sequences' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[3;7f")
      term.cursor_x.should == 6
      term.cursor_y.should == 2
    end

    it 'must handle the cursor up sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5A")
      term.cursor_x.should == 14
      term.cursor_y.should == 4
      term.accept("\033[10A")
      term.cursor_y.should == 0
    end

    it 'must handle the cursor down sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5B")
      term.cursor_x.should == 14
      term.cursor_y.should == 14
      term.accept("\033[20B")
      term.cursor_y.should == 24
    end

    it 'must handle the cursor right sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5C")
      term.cursor_x.should == 19
      term.cursor_y.should == 9
      term.accept("\033[80C")
      term.cursor_x.should == 79
    end

    it 'must handle the cursor left sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5D")
      term.cursor_x.should == 9
      term.cursor_y.should == 9
      term.accept("\033[80D")
      term.cursor_x.should == 0
    end

    it 'must handle the cursor next line sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5E")
      term.cursor_x.should == 0
      term.cursor_y.should == 14
      term.accept("\033[E")
      term.cursor_y.should == 15
    end

    it 'must handle the cursor previous line sequence' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[5F")
      term.cursor_x.should == 0
      term.cursor_y.should == 4
      term.accept("\033[F")
      term.cursor_y.should == 3
    end

    it 'must handle the cursor horizontal absolute' do
      term = Term::Terminal.new
      term.accept("\033[10;15H")
      term.cursor_x.should == 14
      term.cursor_y.should == 9
      term.accept("\033[27G")
      term.cursor_x.should == 26
      term.cursor_y.should == 9
      term.accept("\033[G")
      term.cursor_x.should == 0
      term.cursor_y.should == 9
    end

    it 'must handle the clear screen escape sequences' do
      term = Term::Terminal.new
      term.accept("ABCDEFG\r\n12345\r\n")

      term.cursor_x.should == 0
      term.cursor_y.should == 2

      term.cursor_y = 0
      term.cursor_x = 10

      term.accept("\033[J")
      term.cursor_x.should == 10
      term.cursor_y.should == 0
      term.to_s.strip.should == 'ABCDEFG'

      term.cursor_x = 3
      term.accept("\033[1J")
      term.cursor_x.should == 3
      term.cursor_y.should == 0
      term.to_s.strip.should == 'EFG'
    end

    it 'must handle the erase in line escape sequences' do
      term = Term::Terminal.new
      term.accept("ABCDEFGHIJKLMNOP\r\n12345")
      term.cursor_x = 10
      term.cursor_y = 0

      term.accept("\033[K")
      term.cursor_x.should == 10
      term.cursor_y.should == 0
      term.line(0).strip.should == 'ABCDEFGHIJ'
      term.line(1).strip.should == '12345'

      term.cursor_x = 3
      term.accept("\033[1K")
      term.cursor_x.should == 3
      term.cursor_y.should == 0
      term.line(0).strip.should == 'EFGHIJ'
      term.line(1).strip.should == '12345'

      term.accept("\033[2K")
      term.cursor_x.should == 3
      term.cursor_y.should == 0
      term.to_s.strip.should == '12345'
    end

    it 'must handle the scroll up escape sequence' do
      term = Term::Terminal.new
      term.accept("ABCDEF\r\n123456\r\nFOOBAR\r\n")
      
      term.cursor_x.should == 0
      term.cursor_y.should == 3
      term.to_s.gsub(/\s/,'').should == 'ABCDEF123456FOOBAR'
      term.accept("\033[S")
      term.to_s.gsub(/\s/,'').should == '123456FOOBAR'
      term.cursor_x.should == 0
      term.cursor_y.should == 3
      term.accept("\033[5S")
      term.to_s.strip.should == ''
    end

    it 'must handle the scroll down escape sequence' do
      term = Term::Terminal.new
      term.accept("ABCDEF\r\n123456\r\nFOOBAR\r\n")
      
      term.cursor_x.should == 0
      term.cursor_y.should == 3
      term.to_s.gsub(/\s/,'').should == 'ABCDEF123456FOOBAR'
      term.accept("\033[T")
      term.to_s.gsub(/\s/,'').should == 'ABCDEF123456FOOBAR'
      term.cursor_x.should == 0
      term.cursor_y.should == 3
      term.line(0).strip.should == ''
      term.accept("\033[5T")
      term.to_s.gsub(/\s/,'').should == 'ABCDEF123456FOOBAR'
      term.line(6).strip.should == 'ABCDEF'
      term.accept("\033[50T")
      term.to_s.strip.should == ''
    end
    

    it 'must handle the delete line escape sequence' do
      term = Term::Terminal.new
      term.accept("ABCDEF\r\n123456\r\nFOOBAR\r\n")
      
      term.line(0).strip.should == 'ABCDEF'
      term.line(1).strip.should == '123456'
      term.line(2).strip.should == 'FOOBAR'

      term.cursor_y = 1
      term.cursor_x = 10

      term.accept("\033[M")
      term.line(0).strip.should == 'ABCDEF'
      term.line(1).strip.should == 'FOOBAR'
      term.line(2).strip.should == ''
      term.cursor_x.should == 0
      term.cursor_y.should == 1
    end

    it 'must handle the insert line escape sequence' do
      term = Term::Terminal.new
      term.accept("ABCDEF\r\n123456\r\nFOOBAR\r\n")
      
      term.line(0).strip.should == 'ABCDEF'
      term.line(1).strip.should == '123456'
      term.line(2).strip.should == 'FOOBAR'

      term.cursor_y = 1
      term.cursor_x = 10

      term.accept("\033[L")
      term.line(0).strip.should == 'ABCDEF'
      term.line(1).strip.should == ''
      term.line(2).strip.should == '123456'
      term.line(3).strip.should == 'FOOBAR'

      term.cursor_x.should == 0
      term.cursor_y.should == 1
    end

  end # escape sequences

  describe 'something a little more tricky' do

    it 'must be able to handle vi properly' do
      term = Term::Terminal.new
      # the following was captured using tee
      data = "\e[m\e[m\e[0m\e[H\e[2J\e[2;1H\e[1m\e[34m~                                                                               \e[3;1H~                                                                               \e[4;1H~                                                                               \e[5;1H~                                                                               \e[6;1H~                                                                               \e[7;1H~                                                                               \e[8;1H~                                                                               \e[9;1H~                                                                               \e[10;1H~                                                                               \e[11;1H~                                                                               \e[12;1H~                                                                               \e[13;1H~                                                                               \e[14;1H~                                                                               \e[15;1H~                                                                               \e[16;1H~                                                                               \e[17;1H~                                                                               \e[18;1H~                                                                               \e[19;1H~                                                                               \e[20;1H~                                                                               \e[21;1H~                                                                               \e[22;1H~                                                                               \e[23;1H~                                                                               \e[24;1H~                                                                               \e[0m\e[7;32HVIM - Vi IMproved\e[9;35Hversion 7.3\e[10;29Hby Bram Moolenaar et al.\e[11;19HVim is open source and freely distributable\e[13;26HHelp poor children in Uganda!\e[14;18Htype  :help iccf\e[1m\e[34m<Enter>\e[0m       for information \e[16;18Htype  :q\e[1m\e[34m<Enter>\e[0m               to exit         \e[17;18Htype  :help\e[1m\e[34m<Enter>\e[0m  or  \e[1m\e[34m<F1>\e[0m  for on-line help\e[18;18Htype  :help version7\e[1m\e[34m<Enter>\e[0m   for version info\e[1;1H\e[25;1H\e[1m-- INSERT --\e[1;1H\e[0m\e[2;1H\e[K\e[7;32H\e[1m\e[34m                 \e[9;35H           \e[10;29H                        \e[11;19H                                           \e[13;26H                             \e[14;18H                                              \e[16;18H                                              \e[17;18H                                              \e[18;18H                                              \e[2;1H\e[0mT\bTT\bTT\bTT\bTT\bTT\bTT\bT=\e[2;8H\e[K\e[2;8H \b E\bEE\bEE\bEE\bEE\bEE\bEE  \b\b S\bSS\bSS\bSS\bSS\bSS\bSS\bSS \b T\bTT\bTT\bTT\bTT\bTT\e[3;1H\e[K\e[3;1H  \b T\bTT    \b E\bEE      \b S\bSS         \b T\bTT\e[4;1H\e[K\e[4;1H  \b T\bTT    \b E\bEE\bEE\bEE\bEE\bEE  \b S\bSS\bSS\bSS\bSS\bSS\bSS\bSS   \b T\bTT\e[5;1H\e[K\e[5;1H\e[25;1H\e[K\e[5;1H\e[4;1H\e[3;1H\r\n\r\n\r\n  TT    EE      SS         TT\e[6;30H\e[K\e[6;3H\a\e[5;1H\e[M\e[24;1H\e[1m\e[34m~                                                                               \e[5;3H\e[4;3H\e[3;3H\e[2;3H\r\n\e[0m  \r\n  \r\n  \e[26C\e[25;1H\e[1m-- INSERT --\e[5;30H\e[0m\e[6;1H\e[K\e[6;1H  \b T\bTT    \b E\bEE\bEE\bEE\bEE\bEE  \b S\bSS\bSS\bSS\bSS\bSS\bSS\bSS\e[5;25H\b\b\b\b\b\b\b\b\b  SS\e[7C  TT\e[5;18H\b  SS\e[7C  TT\e[5;19H\b  SS\e[7C  TT\e[5;20H\b  SS\e[7C  TT\e[5;21H\b  SS\e[7C  TT\e[5;22H\b  SS\e[7C  TT\e[5;23HSS \e[25;1H\e[K\e[5;25H\e[7C T\e[5;35H\e[K\e[5;25H       T\e[5;34H\e[K\e[5;25H      T\e[5;33H\e[K\e[5;25H     T\e[5;32H\e[K\e[5;25H    T\e[5;31H\e[K\e[5;25H   T\e[5;30H\e[K\e[5;25H\e[6;24H\e[25;1H\e[1m-- INSERT --\e[6;25H\e[0m   \b T\bTT\e[7;1H\e[K\e[7;1H\e[8;1H\e[K\e[8;1Hi\e[8;1H\e[K\e[8;1H1\b12\b23\b34\b45\b56\b67\b78\b80\e[8;9H\e[K\e[8;9H\b89\b90\e[25;1H\e[K\e[8;10H\e[7;1H\e[6;10H\e[5;10H\e[4;10H\e[3;10H\e[2;10H\e[1;1H\a\a\e[24;1H\e[K\e[2;1H\e[L\e[2;1H1234567890\r\e[1;1H\e[24;1H\e[K\e[2;1H\e[L\e[2;1H1234567890\r\e[1;1H\e[25;1H\r\n\e[24;1H\e[1m\e[34m~                                                                               \e[1;1H\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\a\e[8;1H\e[0m\e[M\e[24;1H\e[1m\e[34m~                                                                               \e[8;1H\a\a\e[25;1H\e[0m:q!\r\e[25;1H\e[K\e[25;1H"
      term.accept(data)

      term.line(0).strip.should == '1234567890'
      term.line(1).strip.should == '1234567890'
      term.line(2).strip.should == 'TTTTTTT EEEEEEE SSSSSSSS TTTTTT'
      term.line(3).strip.should == 'TT    EE      SS         TT'
      term.line(4).strip.should == 'TT    EEEEEE  SSSSSSSS   TT'
      term.line(5).strip.should == 'TT    EE            SS   TT'
      term.line(6).strip.should == 'TT    EEEEEE  SSSSSSSS   TT'
      term.line(7).strip.should == '1234567890'
      term.line(8).strip.should == '~'

    end

  end
end
