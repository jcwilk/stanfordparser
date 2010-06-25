# An additional example for the stanford parser wrapper. This class is designed to find connections between
# nouns in a block of text.
class ConnectionFinder
  attr_accessor :file

  def initialize(filename)
    raise ArgumentError, "File '#{filename}' does not seem to exist." if !File.exists?(filename)
    self.file = File.open(filename, 'r')
  end

  def first(noun1, noun2)
    self.file.each(". ") do |line| #each sentence
      puts line
      tree = parser.apply(line.strip)
      words = tree.map{|n| n.text }
      return {:sentence => line} if [noun1,noun2].all?{|noun| words.include?(noun)}
    end
  end

  def parser
    @_parser ||= StanfordParser::LexicalizedParser.new(StanfordParser::ENGLISH_PCFG_MODEL, []) 
  end
end