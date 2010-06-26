# An additional example for the stanford parser wrapper. This class is designed to find connections between
# nouns in a block of text.
class ConnectionFinder
  attr_accessor :filename
  attr_accessor :cached_parser

  def initialize(_filename)
    raise ArgumentError, "File '#{_filename}' does not seem to exist." if !File.exists?(_filename)
    self.filename = _filename
  end

  def first(noun1, noun2)
    result = nil
    File.open(filename, 'r') do |f|
      f.each_line do |line|
        sentence = line.strip
        words = sentence.split(' ').uniq.map{|w| w.downcase}
        if [noun1,noun2].all?{|n| words.include?(n) }
          #tree = parser.apply(sentence)
          result = {:sentence => sentence}
          break
        end
      end
    end
    result
  end

  private

  def parse(string)
    ParsedTree.new(parser.apply(string))
  end

  def parser
    self.cached_parser ||= StanfordParser::LexicalizedParser.new(StanfordParser::ENGLISH_PCFG_MODEL, []) 
  end

  class ParsedTree
    attr_accessor :tree

    def initialize(_tree)
      self.tree = _tree
    end

    def prune(targets)
      #joinNode
    end

    def to_s

    end
  end
end