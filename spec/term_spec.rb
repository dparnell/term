require 'spec_helper'

describe Term do

  describe 'creation' do
    let :term do Term::Terminal.new(:mode => :ansi, :width => 80, :height => 25) end

    it 'should create a terminal object' do
      term.should_not be_nil
    end


  end

end
