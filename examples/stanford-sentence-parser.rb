#!/usr/bin/env ruby

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

# == Synopsis
#
# Parse a sentence passed in on the command line.
#
# == Usage
#
# stanford-sentence-parser.rb [options] sentence
#
# options::
#    See the Java Stanford Parser documentation for details
#
# sentence::
#    A sentence to parse.  This must appear after all the options and be quoted.


require "stanfordparser"

# The last argument is the sentence.  The rest of the command line is passed
# along to the parser object.
sentence = ARGV.pop
parser = StanfordParser::LexicalizedParser.new(StanfordParser::ENGLISH_PCFG_MODEL, ARGV)
puts parser.apply(sentence)
