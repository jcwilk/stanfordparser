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

  def parsed_java_obj(string)
    @_parsed_hash ||= {}
    @_parsed_hash[string] ||= parser.apply(string)
  end

  def parsed_tree(string)
    ParsedTree.new(parsed_java_obj(string))
  end

  def dependency_tree(string)
    DependencyTree.new(parsed_java_obj(string))
  end

  def parser
    self.cached_parser ||= StanfordParser::LexicalizedParser.new(StanfordParser::ENGLISH_PCFG_MODEL, []) 
  end

  class DependencyTree
    attr_accessor :dependencies
    attr_accessor :tree

    def initialize(java_tree)
      self.tree = java_tree
      self.dependencies = java_tree.dependencies
    end
  end

  class ParsedTree
    attr_accessor :tree

    def initialize(java_tree)
      self.tree = java_tree
    end

    def prune_for(targets)
      target_nodes = all_nodes.select{|n| targets.include?(n.value)}.map{|n| n.java_object}
      raise ArgumentError, "Wrong number of targets found, need 2." if target_nodes.size != 2
      return self.class.new(tree.joinNode(*target_nodes))
    end

    def to_s
      objects = tree.to_a.select{|n| n.isLeaf }.map{|n| n.value}
      objects.inject(''){ |sent, obj|
        #only add a space before it if it doesn't start with a comma, period, etc
        sent + (obj =~ /^[A-Za-z"'\(\[\{]/ ? " #{obj}" : obj)
      }.strip
    end

    #TODO: Find a better way of doing this
    #This is sort of a quick ugly hack, but basically it's purpose is to grab a list
    #of all of the nodes in the tree -by reference-. If you do getLeaves() or to_a instead
    #of children(), it'll give you all the leaves but they aren't the same reference
    #and when you try to do something like joinNode() later it won't work. This is the
    #simplest way I've found so far to get access to all of the nodes by reference.
    #Note that you still have to do map{|node| node.java_object} eventually.
    def all_nodes
      @_all_nodes ||= begin
        pending = [self.tree]
        done = []
        pending.each do |n|
          n.children.each{|c| pending.push c }
          done.push n
        end
        done
      end
    end
  end

  #This is something I was trying to get to work as a edu.stanford.nlp.util.Filter
  #Have yet to get it to work, though...
  class TreeFilter
    attr_accessor :checker

    def initialize(&block)
      self.checker = Proc.new{|node| yield(node)}
    end

    def accept(node)
      checker.call(node) ? true : false
    end
  end
end