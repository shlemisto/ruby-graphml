$:.unshift( "../lib" )
require "ruby-graphml"
 
# graphml=GraphML.new("graph_simple.graphml")
# graph=graphml.graph
# p "=================================="
# graph.nodes.each{|item| p item}
# graph.edges.each{|item| p item}
# p graphml.output :file=>"abc.graphml" 
 
GraphML.new do |graphml|
	graphml.add_key("k1"){|k|
		              k<<{:for => "node",:"attr.name"=>"color",:"attr.type"=>"string"}
		              k.text=%Q{<default>yellow</default>}
	   }

	graphml.add_graph("abc"){|g|
                     g.add_node("n0"){ |node|
                                         node.add_data("k1").text = %Q{abc  }
                                      }
	   				 g.add_node("n1")  

					 g.add_edge(:source=>"n0",:target=>"n1")<< {:directed => "true " }
	}
	
    graphml.output :file=>"output_graphml.graphml" 
end	

 



 