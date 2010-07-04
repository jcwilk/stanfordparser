require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ConnectionFinder do
  before(:all) do
    @filename = File.dirname(__FILE__)+'/files/gpl-2.0-simple.txt'
    @empty_filename = File.dirname(__FILE__)+'/files/empty_file.txt'
    @finder = ConnectionFinder.new(@filename)
    @finder.cached_parser = $parser
  end

  describe "initialization:" do
    it "takes in a filename" do
      lambda{ConnectionFinder.new(@filename)}.should_not raise_error
    end

    it "raises ArgumentError on new without a parameter" do
      lambda{ConnectionFinder.new}.should raise_error(ArgumentError)
    end

    it "raises ArgumentError if the file doesn't exist" do
      lambda{ConnectionFinder.new("bogus_filename.txt")}.should raise_error(ArgumentError)
    end
  end

  describe "finding a connection:" do
    before(:each) do
      @noun1 = "rights"
      @noun2 = "restrictions"
    end

    describe "first:" do
      describe "empty file:" do
        it "returns nil if it finds nothing" do
          empty_finder = ConnectionFinder.new(@empty_filename)
          empty_finder.stub!(:parser).and_return(@parser)
          empty_finder.first("anything","whatever").should be_nil
        end
      end

      describe "non empty file:" do
        it "freedom software" do
          result = @finder.first("freedom","software")
          result.should_not be_nil
          result[:sentence].should ==
            "The licenses for most software are designed to take away your freedom to share and change it."
        end

        it "restrictions rights" do
          result = @finder.first("restrictions","rights")
          result.should_not be_nil
          result[:sentence].should ==
            "To protect your rights, we need to make restrictions that forbid anyone to deny you these rights or to ask you to surrender the rights."
        end
      end
    end
  end

  describe ConnectionFinder::ParsedTree do
    before(:all) do
      @sentence = "Few people know, though many assume, "+
                         "that a sentence is better than a phrase."
      @tree = @finder.send(:parse, @sentence)
    end

    it "has a tree object" do
      @tree.tree.class.to_s.should == 'StanfordParser::Tree'
    end

    it "reduces back to its original form" do
      debugger
      @tree.to_s.should == @sentence
    end
  end
end