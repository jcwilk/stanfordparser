$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'stanfordparser'
require 'spec'
require 'spec/autorun'
require 'examples/connection_finder.rb'

$parser = StanfordParser::LexicalizedParser.new #(StanfordParser::ENGLISH_PCFG_MODEL, [])

Spec::Runner.configure do |config|

end
