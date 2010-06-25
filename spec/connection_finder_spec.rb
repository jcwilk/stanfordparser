require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ConnectionFinder do
  before(:all) do
    #@parser = StanfordParser::LexicalizedParser.new(StanfordParser::ENGLISH_PCFG_MODEL, [])
    @parser = PARSER
    @filename = File.dirname(__FILE__)+'/files/gpl-2.0.txt'
    @empty_filename = File.dirname(__FILE__)+'/files/empty_file.txt'
  end

  describe "initialization" do
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

  describe "finding a connection" do
    before(:each) do
      @noun1 = "software"
      @noun2 = "freedom"
    end

    describe "first" do
      describe "empty file" do
        it "returns nil if it finds nothing" do
          empty_finder = ConnectionFinder.new(@empty_filename)
          empty_finder.stub!(:parser).and_return(@parser)
          empty_finder.first(@noun1,@noun2).should be_nil
        end
      end

      describe "not empty" do
        before(:each) do
          @finder = ConnectionFinder.new(@filename)
          @finder.stub!(:parser).and_return(@parser)
          @result = @finder.first(@noun1,@noun2)
        end

        it "returns a result hash if it finds something" do
          @result.should_not be_nil
        end

        it "finds the first sentence using both nouns" do
          @result[:sentence].should ==
            "The licenses for most software are designed to take away your freedom to share and change it."
        end
      end
    end

    describe "all" do
      it "finds all connections between nouns"
    end
  end
end