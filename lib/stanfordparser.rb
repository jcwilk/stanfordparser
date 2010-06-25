require 'rubygems'

require "pathname"
require "rjb"
require "singleton"
begin
  require "treebank"
  gem "treebank", ">= 3.0.0"
rescue LoadError
  require "treebank"
end
require "yaml"

# Wrapper for the {Stanford Natural Language
# Parser}[http://nlp.stanford.edu/downloads/lex-parser.shtml].
module StanfordParser

  require "stanfordparser/java_object"

  VERSION = "2.2.1"

  # The default sentence segmenter and tokenizer.  This is an English-language
  # tokenizer with support for Penn Treebank markup.
  EN_PENN_TREEBANK_TOKENIZER = "edu.stanford.nlp.process.PTBTokenizer"

  # Path to an English PCFG model that comes with the Stanford Parser.  The
  # location is relative to the parser root directory.  This is a valid value
  # for the <em>grammar</em> parameter of the LexicalizedParser constructor.
  ENGLISH_PCFG_MODEL = "$(ROOT)/englishPCFG.ser.gz"

  # This function is executed once when the module is loaded.  It initializes
  # the Java virtual machine in which the Stanford parser will run.  By
  # default, it adds the parser installation root to the Java classpath and
  # launches the VM with the arguments <tt>-server -Xmx150m</tt>.  Different
  # values may be specified with the <tt>ruby-stanford-parser.yaml</tt>
  # configuration file.
  #
  # This function determines which operating system we are running on and sets
  # default pathnames accordingly:
  #
  # UNIX:: /usr/local/stanford-parser/current, /etc/ruby-stanford-parser.yaml
  # Windows:: C:\stanford-parser\current,
  #           C:\stanford-parser\ruby-stanford-parser.yaml
  #
  # This function returns the path of the parser installation root.
  def StanfordParser.initialize_on_load
    if RUBY_PLATFORM =~ /(win|w)32$/
      root = Pathname.new("C:\\stanford-parser\\current ")
      config = Pathname.new("C:\\stanford-parser\\ruby-stanford-parser.yaml")
    else
      root = Pathname.new("/usr/local/stanford-parser/current")
      config = Pathname.new("/etc/ruby-stanford-parser.yaml")
    end
    jvmargs = ["-server", "-Xmx150m"]
    if config.file?
      configuration = open(config) {|f| YAML.load(f)}
      if configuration.key?("root") and not configuration["root"].nil?
        root = Pathname.new(configuration["root"])
      end
      if configuration.key?("jvmargs") and not configuration["jvmargs"].nil?
        jvmargs = configuration["jvmargs"].split
      end
    end
    Rjb::load(classpath = (root + "stanford-parser.jar").to_s, jvmargs)
    root
  end

  private_class_method :initialize_on_load

  # The root directory of the Stanford parser installation.
  ROOT = initialize_on_load

  #--
  # The documentation below is for the original Rjb::JavaObjectWrapper object.
  # It is reproduced here because rdoc only takes the last document block
  # defined.  If Rjb is moved into its own gem, this documentation should go
  # with it, and the following should be written as documentation for this
  # class:
  #
  # Extension of the generic Ruby-Java Bridge wrapper object for the
  # StanfordParser module.
  #++
  # A generic wrapper for a Java object loaded via the {Ruby-Java
  # Bridge}[http://rjb.rubyforge.org/].  The wrapper class handles
  # intialization and stringification, and passes other method calls down to
  # the underlying Java object.  Objects returned by the underlying Java
  # object are converted to the appropriate Ruby object.
  #
  # Other modules may extend the list of Java objects that are converted by
  # adding their own converter functions.  See wrap_java_object for details.
  #
  # This object is enumerable, yielding items in the order defined by the
  # underlying Java object's iterator.
  class Rjb::JavaObjectWrapper
    # FeatureLabel objects go inside a FeatureLabel wrapper.
    def wrap_edu_stanford_nlp_ling_FeatureLabel(object)
      StanfordParser::FeatureLabel.new(object)
    end

    # Tree objects go inside a Tree wrapper.  Various tree types are aliased
    # to this function.
    def wrap_edu_stanford_nlp_trees_Tree(object)
      Tree.new(object)
    end

    alias :wrap_edu_stanford_nlp_trees_LabeledScoredTreeLeaf :wrap_edu_stanford_nlp_trees_Tree
    alias :wrap_edu_stanford_nlp_trees_LabeledScoredTreeNode :wrap_edu_stanford_nlp_trees_Tree
    alias :wrap_edu_stanford_nlp_trees_SimpleTree            :wrap_edu_stanford_nlp_trees_Tree
    alias :wrap_edu_stanford_nlp_trees_TreeGraphNode         :wrap_edu_stanford_nlp_trees_Tree

    protected :wrap_edu_stanford_nlp_trees_Tree, :wrap_edu_stanford_nlp_ling_FeatureLabel
  end # Rjb::JavaObjectWrapper


  # Lexicalized probabalistic parser.
  #
  # This is an wrapper for the
  # <tt>edu.stanford.nlp.parser.lexparser.LexicalizedParser</tt> object.
  class LexicalizedParser < Rjb::JavaObjectWrapper
    # The grammar used by the parser
    attr_reader :grammar

    # Create the parser given a grammar and options.  The <em>grammar</em>
    # argument is a path to a grammar file.  This path may contain the string
    # <tt>$(ROOT)</tt>, which will be replaced with the root directory of the
    # Stanford Parser. By default, an English PCFG grammar is loaded.
    #
    # The <em>options</em> argument is a list of string arguments as they
    # would appear on a command line.  See the documentaion of
    # <tt>edu.stanford.nlp.parser.lexparser.Options.setOptions</tt> for more
    # details.
    def initialize(grammar = ENGLISH_PCFG_MODEL, options = [])
      @grammar = Pathname.new(grammar.gsub(/\$\(ROOT\)/, ROOT))
      super("edu.stanford.nlp.parser.lexparser.LexicalizedParser", @grammar.to_s)
      @java_object.setOptionFlags(options)
    end

    def to_s
      "LexicalizedParser(#{grammar.basename})"
    end
  end # LexicalizedParser


  # A singleton instance of the default Stanford Natural Language parser.  A
  # singleton is used because the parser can take a few seconds to load.
  class DefaultParser < StanfordParser::LexicalizedParser
    include Singleton
  end


  # This is a wrapper for
  # <tt>edu.stanford.nlp.trees.Tree</tt> objects.  It customizes
  # stringification.
  class Tree < Rjb::JavaObjectWrapper
    def initialize(obj = "edu.stanford.nlp.trees.Tree")
      super(obj)
    end

    # Return the label along with the score if there is one.
    def inspect
      s = "#{label}" + (score.nan? ? "" : " [#{sprintf '%.2f', score}]")
      "(#{s})"
    end

    # The Penn treebank representation.  This prints with indenting instead of
    # putting everything on one line.
    def to_s
      "#{pennString}"
    end
  end # Tree


  # This is a wrapper for
  # <tt>edu.stanford.nlp.ling.Word</tt> objects.  It customizes
  # stringification and adds an equivalence operator.
  class Word < Rjb::JavaObjectWrapper
    def initialize(obj = "edu.stanford.nlp.ling.Word", *args)
      super(obj, *args)
    end

    # See the word values.
    def inspect
      to_s
    end

    # Equivalence is defined relative to the word value.
    def ==(other)
      word == other
    end
  end # Word


  # This is a wrapper for <tt>edu.stanford.nlp.ling.FeatureLabel</tt> objects.
  # It customizes stringification.
  class FeatureLabel < Rjb::JavaObjectWrapper
    def initialize(obj = "edu.stanford.nlp.ling.FeatureLabel")
      super
    end

    # Stringify with just the token and its begin and end position.
    def to_s
      # BUGBUG The position values come back as java.lang.Integer though I
      # would expect Rjb to convert them to Ruby integers.
      begin_position = get(self.BEGIN_POSITION_KEY)
      end_position = get(self.END_POSITION_KEY)
      "#{current} [#{begin_position},#{end_position}]"
    end

    # More verbose stringification with all the fields and their values.
    def inspect
      toString
    end
  end


  # Tokenizes documents into words and sentences.
  #
  # This is a wrapper for the
  # <tt>edu.stanford.nlp.process.DocumentPreprocessor</tt> object.
  class DocumentPreprocessor < Rjb::JavaObjectWrapper
    def initialize(suppressEscaping = false)
      super("edu.stanford.nlp.process.DocumentPreprocessor", suppressEscaping)
    end

    # Returns a list of sentences in a string.
    def getSentencesFromString(s)
      s = Rjb::JavaObjectWrapper.new("java.io.StringReader", s)
      _invoke(:getSentencesFromText, "Ljava.io.Reader;", s.java_object)
    end
    
    def inspect
      "<#{self.class.to_s.split('::').last}>"
    end
    
    def to_s
      inspect
    end
  end # DocumentPreprocessor

  # A text token that contains raw and normalized token identity (.e.g "(" and
  # "-LRB-"), an offset span, and the characters immediately preceding and
  # following the token.  Given a list of these objects it is possible to
  # recreate the text from which they came verbatim.
  class StandoffToken < Struct.new(:current, :word, :before, :after,
                                   :begin_position, :end_position)
    def to_s
      "#{current} [#{begin_position},#{end_position}]"
    end
  end


  # A preprocessor that segments text into sentences and tokens that contain
  # character offset and token context information that can be used for
  # standoff annotation.
  class StandoffDocumentPreprocessor < DocumentPreprocessor
    def initialize(tokenizer = EN_PENN_TREEBANK_TOKENIZER)
      # PTBTokenizer.factory is a static function, so use RJB to call it
      # directly instead of going through a JavaObjectWrapper.  We do it this
      # way because the Standford parser Java code does not provide a
      # constructor that allows you to specify the second parameter,
      # invertible, to true, and we need this to write character offset
      # information into the tokens.
      ptb_tokenizer_class = Rjb::import(tokenizer)
      # See the documentation for
      # <tt>edu.stanford.nlp.process.DocumentPreprocessor</tt> for a
      # description of these parameters.
      ptb_tokenizer_factory = ptb_tokenizer_class.factory(false, true, false)
      super(ptb_tokenizer_factory)
    end

    # Returns a list of sentences in a string.  This wraps the returned
    # sentences in a StandoffSentence object.
    def getSentencesFromString(s)
      super(s).map!{|s| StandoffSentence.new(s)}
    end
  end


  # A sentence is an array of StandoffToken objects.
  class StandoffSentence < Array
    # Construct an array of StandoffToken objects from a Java list sentence
    # object returned by the preprocessor.
    def initialize(stanford_parser_sentence)
      # Convert FeatureStructure wrappers to StandoffToken objects.
      s = stanford_parser_sentence.to_a.collect do |fs|
        current = fs.current
        word = fs.word
        before = fs.before
        after = fs.after
        # The to_s.to_i is necessary because the get function returns
        # java.lang.Integer objects instead of Ruby integers.
        begin_position = fs.get(fs.BEGIN_POSITION_KEY).to_s.to_i
        end_position = fs.get(fs.END_POSITION_KEY).to_s.to_i
        StandoffToken.new(current, word, before, after,
                          begin_position, end_position)
      end
      super(s)
    end

    # Return the original string verbatim.
    def to_s
      self[0..-2].inject(""){|s, word| s + word.current + word.after} + last.current
    end

    # Return the original string verbatim.
    def inspect
      to_s
    end
  end


  # Standoff syntactic annotation of natural language text which may contain
  # multiple sentences.
  #
  # This is an Array of StandoffNode objects, one for each sentence in the
  # text.
  class StandoffParsedText < Array
    # Parse the text and create the standoff annotation.
    #
    # The default parser is a singleton instance of the English language
    # Stanford Natural Langugage parser.  There may be a delay of a few
    # seconds for it to load the first time it is created.
    def initialize(text, nodetype = StandoffNode,
                   tokenizer = EN_PENN_TREEBANK_TOKENIZER,
                   parser = DefaultParser.instance)
      preprocessor = StandoffDocumentPreprocessor.new(tokenizer)
      # Segment the text into sentences.  Parse each sentence, writing
      # standoff annotation information into the terminal nodes.
      preprocessor.getSentencesFromString(text).map do |sentence|
        parse = parser.apply(sentence.to_s)
        push(nodetype.new(parse, sentence))
      end
    end

    # Print class name and number of sentences.
    def inspect
      "<#{self.class.name}, #{length} sentences>"
    end

    # Print parses.
    def to_s
      flatten.join(" ")
    end
  end


  # Standoff syntactic tree annotation of text.  Terminal nodes are labeled
  # with the appropriate StandoffToken objects.  Standoff parses can reproduce
  # the original string from which they were generated verbatim, optionally
  # with brackets around the yields of specified non-terminal nodes.
  class StandoffNode < Treebank::ParentedNode
    # Create the standoff tree from a tree returned by the Stanford parser.
    # For non-terminal nodes, the <em>tokens</em> argument will be a
    # StandoffSentence containing the StandoffToken objects representing all
    # the tokens beneath and after this node.  For terminal nodes, the
    # <em>tokens</em> argument will be a StandoffToken.
    def initialize(stanford_parser_node, tokens)
      # Annotate this node with a non-terminal label or a StandoffToken as
      # appropriate.
      super(tokens.instance_of?(StandoffSentence) ?
            stanford_parser_node.value : tokens)
      # Enumerate the children depth-first.  Tokens are removed from the list
      # left-to-right as terminal nodes are added to the tree.
      stanford_parser_node.children.each do |child|
        subtree = self.class.new(child, child.leaf? ? tokens.shift : tokens)
        attach_child!(subtree)
      end
    end

    # Return the original text string dominated by this node.
    def to_original_string
      leaves.inject("") do |s, leaf|
        s += leaf.label.current + leaf.label.after
      end
    end

    # Print the original string with brackets around word spans dominated by
    # the specified consituents.
    #
    # The constituents to bracket are specified by passing a list of node
    # coordinates, which are arrays of integers of the form returned by the
    # tree enumerators of Treebank::Node objects.
    #
    # _coords_:: the coordinates of the nodes around which to place brackets
    # _open_:: the open bracket symbol
    # _close_:: the close bracket symbol
    def to_bracketed_string(coords, open = "[", close = "]")
      # Get a list of all the leaf nodes and their coordinates.
      items = depth_first_enumerator(true).find_all {|n| n.first.leaf?}
      # Enumerate over all the matching constituents inserting open and close
      # brackets around their yields in the items list.
      coords.each do |matching|
        # Insert using a simple state machine with three states: :start,
        # :open, and :close.
        state = :start
        # Enumerate over the items list looking for nodes that are the
        # children of the matching constituent.
        items.each_with_index do |item, index|
          # Skip inserted bracket characters.
          next if item.is_a? String
          # Handle terminal node items with the state machine.
          node, terminal_coordinate = item
          if state == :start
            next if not in_yield?(matching, terminal_coordinate)
            items.insert(index, open)
            state = :open
          else # state == :open
            next if in_yield?(matching, terminal_coordinate)
            items.insert(index, close)
            state = :close
            break
          end
        end # items.each_with_index
        # Handle the case where a matching constituent is flush with the end
        # of the sentence.
        items << close if state == :open
      end # each
      # Replace terminal nodes with their string representations.  Insert
      # spacing characters in the list.
      items.each_with_index do |item, index|
        next if item.is_a? String
        text = item.first.label.current
        spacing = item.first.label.after
        # Replace the terminal node with its text.
        items[index] = text
        # Insert the spacing that comes after this text before the first
        # non-close bracket character.
        close_pos = find_index(items[index+1..-1]) {|item| not item == close}
        items.insert(index + close_pos + 1, spacing)
      end
      items.join
    end # to_bracketed_string

    # Find the index of the first item in _list_ for which _block_ is true.
    # Return 0 if no items are found.
    def find_index(list, &block)
      list.each_with_index do |item, index|
        return index if block.call(item)
      end
      0
    end

    # Is the node at _terminal_ in the yield of the node at _node_?
    def in_yield?(node, terminal)
      # If node A's coordinates match the prefix of node B's coordinates, node
      # B is in the yield of node A.
      terminal.first(node.length) == node
    end

    private :in_yield?, :find_index
  end # StandoffNode

end # StanfordParser
