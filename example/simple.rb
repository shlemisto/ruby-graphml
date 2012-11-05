$:.unshift( "../lib" )
require "ruby-graphml"
graphml=GraphML.new("graph_base_simple.graphml")
graph=graphml.graph
p "=================================="
	graphml.output :file=>"abc.graphml" 

 