require_relative 'helper'
 
class TestRubyGraphml < Test::Unit::TestCase
 
 context "GraphML class" do
    setup  do
      @gml=GraphML.new	
      @graph=GraphML::Graph.new
      @gml.add_graph @graph
      @node1=GraphML::Node.new
      @graph.add_node @node1	
      @node2=@graph.add_node "id1"
      @subgraph=@node1.add_graph "subgraph"
      @node3=@subgraph.add_node 'subgraph_node'

      @node1.add_data("name","shaoyang")
      @node1.add_data(GraphML::Data.new("age","22"))

      
    end	

    should "new graphml" do
    	  
          assert_not_nil @gml 
    end
    
    should "add_graph" do
    	assert_equal true,@gml.graph.is_a?(GraphML::Graph)
    end 
    
    should "nodes" do  
    	nodes=@gml.nodes
    	i "nodes",nodes.keys
    	assert_equal 3,nodes.size
    	assert_equal ["subgraph_node", "n0", "id1"],nodes.keys
    end

     should "auto_key_generate" do
    	@gml.auto_key_generate
    	keys=@gml.keys
    	i "auto_key_generate",keys.keys
    	assert_equal true,keys.has_key?("name")
    	assert_equal true,keys.has_key?("age")
    end 

 end
end
