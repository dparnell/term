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
    end

  end # escape sequences

end
