#!/bin/env ruby

#--

# Copyright 2007-2008 William Patrick McNeill
#
# This file is part of the Stanford Parser Ruby Wrapper.
#
# The Stanford Parser Ruby Wrapper is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
#
# The Stanford Parser Ruby Wrapper is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# editalign; if not, write to the Free Software Foundation, Inc., 51 Franklin
# St, Fifth Floor, Boston, MA 02110-1301 USA
#
#++

# Test cases for the Stanford Parser module

require "test/unit"
require "set"
require "singleton"
require "stanfordparser"


class LexicalizedParserTestCase < Test::Unit::TestCase
  def test_root_path
    assert_equal StanfordParser::ROOT.class, Pathname
  end

  def setup
    @parser = StanfordParser::DefaultParser.instance
    @tree = @parser.apply("This is a sentence.")
  end

  def test_parser
    assert_equal @parser.grammar, StanfordParser::ROOT + "englishPCFG.ser.gz"
    assert_equal @tree.class, StanfordParser::Tree
  end

  def test_localTrees
    # The following call exercises the conversion from java.util.HashSet
    # objects to Ruby sets.
    l = @tree.localTrees
    assert_equal l.size, 5
    assert_equal Set.new(l.collect {|t| "#{t.label}"}),
                 Set.new(["S", "NP", "VP", "ROOT", "NP"])
  end

  def test_enumerable
    # StanfordParser::LexicalizedParser is not an enumerable object.
    assert_equal @parser.map, []
  end
end # LexicalizedParserTestCase


class TreeTestCase < Test::Unit::TestCase
  def setup
    @parser = StanfordParser::DefaultParser.instance
    @tree = @parser.apply("This is a sentence.")
  end

  def test_enumerable
    assert @tree.all? {|n| n.class == StanfordParser::Tree}
    assert @tree.all? {|n|
      n._classname == "edu.stanford.nlp.trees.LabeledScoredTreeNode" or
      n._classname == "edu.stanford.nlp.trees.LabeledScoredTreeLeaf"
    }
    assert_equal @tree.map {|n| "#{n.label}"},
      ["ROOT", "S", "NP", "DT", "This", "VP", "VBZ", "is", "NP", "DT", "a", \
       "NN", "sentence", ".", "."]
  end
end # TreeTestCase


class FeatureLabelTestCase < Test::Unit::TestCase
  def test_feature_label
    f = StanfordParser::FeatureLabel.new
    assert_equal "BEGIN_POS", f.BEGIN_POSITION_KEY
    f.put(f.BEGIN_POSITION_KEY, 3)
    assert_equal "END_POS", f.END_POSITION_KEY
    f.put(f.END_POSITION_KEY, 7)
    assert_equal "current", f.CURRENT_KEY
    f.put(f.CURRENT_KEY, "word")
    assert_equal "{BEGIN_POS=3, END_POS=7, current=word}", f.inspect
    assert_equal "word [3,7]", f.to_s
  end
end


class DocumentPreprocessorTestCase < Test::Unit::TestCase
  def setup
    @preproc = StanfordParser::DocumentPreprocessor.new
    @standoff_preproc = StanfordParser::StandoffDocumentPreprocessor.new
  end

  def test_get_sentences_from_string
    # The following call exercises the conversion from java.util.ArrayList
    # objects to Ruby arrays.
    s = @preproc.getSentencesFromString("This is a sentence.  So is this.")
    assert_equal "#{s[0]}", "This is a sentence ."
    assert_equal "#{s[1]}", "So is this ."
  end

  def test_enumerable
    # StanfordParser::DocumentPreprocessor is not an enumerable object.
    assert_equal @preproc.map, []
  end

  # Segment and tokenize text containing two sentences.
  def test_standoff_document_preprocessor
    sentences = @standoff_preproc.getSentencesFromString("He (John) is tall.  So is she.")
    # Recognize two sentences.
    assert_equal 2, sentences.length
    assert sentences.all? {|sentence| sentence.instance_of? StanfordParser::StandoffSentence}
    assert_equal "He (John) is tall.", sentences.first.to_s
    assert_equal 7, sentences.first.length
    assert sentences[0].all? {|token| token.instance_of? StanfordParser::StandoffToken}
    assert_equal "So is she.", sentences.last.to_s
    assert_equal 4, sentences.last.length
    assert sentences[1].all? {|token| token.instance_of? StanfordParser::StandoffToken}
    # Get the correct token information for the first sentence.
    assert_equal ["He", "He"], [sentences[0][0].current(), sentences[0][0].word()]
    assert_equal [0,2],        [sentences[0][0].begin_position(), sentences[0][0].end_position()]
    assert_equal ["(", "-LRB-"], [sentences[0][1].current(), sentences[0][1].word()]
    assert_equal [3,4],          [sentences[0][1].begin_position(), sentences[0][1].end_position()]
    assert_equal ["John", "John"], [sentences[0][2].current(), sentences[0][2].word()]
    assert_equal [4,8],            [sentences[0][2].begin_position(), sentences[0][2].end_position()]
    assert_equal [")", "-RRB-"], [sentences[0][3].current(), sentences[0][3].word()]
    assert_equal [8,9],          [sentences[0][3].begin_position(), sentences[0][3].end_position()]
    assert_equal ["is", "is"], [sentences[0][4].current(), sentences[0][4].word()]
    assert_equal [10,12],      [sentences[0][4].begin_position(), sentences[0][4].end_position()]
    assert_equal ["tall", "tall"], [sentences[0][5].current(), sentences[0][5].word()]
    assert_equal [13,17],          [sentences[0][5].begin_position(), sentences[0][5].end_position()]
    assert_equal [".", "."], [sentences[0][6].current(), sentences[0][6].word()]
    assert_equal [17,18],    [sentences[0][6].begin_position(), sentences[0][6].end_position()]
    # Get the correct token information for the second sentence.
    assert_equal ["So", "So"], [sentences[1][0].current(), sentences[1][0].word()]
    assert_equal [20,22],      [sentences[1][0].begin_position(), sentences[1][0].end_position()]
    assert_equal ["is", "is"], [sentences[1][1].current(), sentences[1][1].word()]
    assert_equal [23,25],      [sentences[1][1].begin_position(), sentences[1][1].end_position()]
    assert_equal ["she", "she"], [sentences[1][2].current(), sentences[1][2].word()]
    assert_equal [26,29],        [sentences[1][2].begin_position(), sentences[1][2].end_position()]
    assert_equal [".", "."], [sentences[1][3].current(), sentences[1][3].word()]
    assert_equal [29,30],    [sentences[1][3].begin_position(), sentences[1][3].end_position()]
  end

  def test_stringification
    assert_equal "<DocumentPreprocessor>", @preproc.inspect
    assert_equal "<DocumentPreprocessor>", @preproc.to_s
    assert_equal "<StandoffDocumentPreprocessor>", @standoff_preproc.inspect
    assert_equal "<StandoffDocumentPreprocessor>", @standoff_preproc.to_s
  end

end # DocumentPreprocessorTestCase


class StandoffParsedTextTestCase < Test::Unit::TestCase
  def setup
    @text = "He (John) is tall.  So is she."
  end

  def test_parse_text_default_nodetype
    parsed_text = StanfordParser::StandoffParsedText.new(@text)
    verify_parsed_text(parsed_text, StanfordParser::StandoffNode)
  end

  # Verify correct parsing with variable node types for text containing two sentences.
  def verify_parsed_text(parsed_text, nodetype)
    # Verify that there are two sentences.
    assert_equal 2, parsed_text.length
    assert parsed_text.all? {|sentence| sentence.instance_of? nodetype}
    # Verify the tokens in the leaf node of the first sentence.
    leaves = parsed_text[0].leaves.collect {|node| node.label}
    assert_equal ["He", "He"], [leaves[0].current(), leaves[0].word()]
    assert_equal [0,2],        [leaves[0].begin_position(), leaves[0].end_position()]
    assert_equal ["(", "-LRB-"], [leaves[1].current(), leaves[1].word()]
    assert_equal [3,4],          [leaves[1].begin_position(), leaves[1].end_position()]
    assert_equal ["John", "John"], [leaves[2].current(), leaves[2].word()]
    assert_equal [4,8],            [leaves[2].begin_position(), leaves[2].end_position()]
    assert_equal [")", "-RRB-"], [leaves[3].current(), leaves[3].word()]
    assert_equal [8,9],          [leaves[3].begin_position(), leaves[3].end_position()]
    assert_equal ["is", "is"], [leaves[4].current(), leaves[4].word()]
    assert_equal [10,12],      [leaves[4].begin_position(), leaves[4].end_position()]
    assert_equal ["tall", "tall"], [leaves[5].current(), leaves[5].word()]
    assert_equal [13,17],          [leaves[5].begin_position(), leaves[5].end_position()]
    assert_equal [".", "."], [leaves[6].current(), leaves[6].word()]
    assert_equal [17,18],    [leaves[6].begin_position(), leaves[6].end_position()]
    # Verify the tokens in the leaf node of the second sentence.
    leaves = parsed_text[1].leaves.collect {|node| node.label}
    assert_equal ["So", "So"], [leaves[0].current(), leaves[0].word()]
    assert_equal [20,22],      [leaves[0].begin_position(), leaves[0].end_position()]
    assert_equal ["is", "is"], [leaves[1].current(), leaves[1].word()]
    assert_equal [23,25],      [leaves[1].begin_position(), leaves[1].end_position()]
    assert_equal ["she", "she"], [leaves[2].current(), leaves[2].word()]
    assert_equal [26,29],        [leaves[2].begin_position(), leaves[2].end_position()]
    assert_equal [".", "."], [leaves[3].current(), leaves[3].word()]
    assert_equal [29,30],    [leaves[3].begin_position(), leaves[3].end_position()]
    # Verify that the original string is recoverable.
    assert_equal "He (John) is tall.  ", parsed_text[0].to_original_string
    assert_equal "So is she."          , parsed_text[1].to_original_string
    # Draw < and > brackets around 3 constituents.
    b = parsed_text[0].to_bracketed_string([[0,0], [0,0,1,1], [0,1,1]], "<", ">")
    assert_equal "<He (<John>)> is <tall>.  ", b
  end
end


class MiscPreprocessorTestCase < Test::Unit::TestCase
  def test_model_location
    assert_equal "$(ROOT)/englishPCFG.ser.gz", StanfordParser::ENGLISH_PCFG_MODEL
  end

  def test_word
    assert StanfordParser::Word.new("edu.stanford.nlp.ling.Word", "dog") ==  "dog"
  end
end # MiscPreprocessorTestCase
