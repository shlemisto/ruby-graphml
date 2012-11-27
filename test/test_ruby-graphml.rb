require_relative 'helper'
 
class TestRubyGraphml < Test::Unit::TestCase
 context "Edge class" do
     setup  do
     end 
     should "new" do
       name="new"
       edge=GraphML::Edge.new()
       assert_equal true,edge.is_a?(GraphML::Edge)
       edge=GraphML::Edge.new("s1","s2")
       i name,edge.to_xml
       assert_equal "s1",edge[:source]

       edge=GraphML::Edge.new("s1","s2")
       i name,edge.to_xml
       assert_equal "s1",edge[:source]
       assert_equal nil,edge.graph
     end

      should "add_data" do
       name="add_data"
       edge=GraphML::Edge.new()
       edge.add_data "abc" ,"abc"
       i name,edge.to_xml
     end
   end 
 context "Graph class" do
     setup  do
      @graph=GraphML::Graph.new()
     end 
     should "new" do
       name="new"
       assert_equal true,@graph.is_a?(GraphML::Graph)
     end
     should "add_edge" do
       name="add_edge"
       edge=GraphML::Edge.new "a","b"
       s=@graph.add_edge edge
       i name,@graph.to_xml
       assert_equal true,s.is_a?(GraphML::Edge)
     end
   end   

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
      @edge1=GraphML::Edge.new @node1,@node2,@graph
      @edge1.add_data "abc","xxx"

      @node1.add_data("name","shaoyang")<<{:"mytype.xxx"=>"abc",:readonly=>"true"}
      @node1.add_data(GraphML::Data.new("age","22"))


    end	
    	  
    
    should "new graphml" do
      name="new graphml"
      assert_not_nil @gml 
      graphml=GraphML.new "../example/graph_attributes.graphml"
      s=graphml.to_xml
      assert_equal 0,s.count("{")

      graphml=GraphML.new s
      s=graphml.to_xml
      assert_equal 0,s.count("{")
    end

    should "to_file" do
      name="to_file"
      file=@gml.to_file "test.graphml" 
       assert_not_nil file
    end

    
    should "add_graph" do
      name="add_graph"
    	assert_equal true,@gml.graph.is_a?(GraphML::Graph)
    end 

    should "nodes" do
      name="nodes"
      nodes=@gml.nodes
    	i name,nodes.keys
    	assert_equal 3,nodes.size
    	assert_equal ["subgraph_node", "n0", "id1"],nodes.keys
    end

    
    should "auto_key_generate" do
      name="auto_key_generate"
    	@gml.auto_key_generate
    	keys=@gml.keys
    	i name,keys.keys
      i name,keys 
      i name,@gml.to_xml
    	assert_equal true,keys.has_key?("name")
    	assert_equal true,keys.has_key?("age")
    end 


    should "load basesample" do
        name="load basesample"
    	 gml=GraphML.new "../example/graph_base_simple.graphml"
    	 i name, gml.inspect
    	 i name, gml.graph.inspect
    	 assert_equal "G1",gml.graph[:id]
    	 assert_equal 2,gml.nodes.size
       i name,gml.edges.keys
    	 assert_equal 1,gml.edges.size
    end 

    
    should "load nested sample" do 
       name="load nested sample111"
    	 gml=GraphML.new "../example/graph_nested.graphml"
    	 # i name, gml.inspect
    	  i name, gml.to_xml
    	 assert_equal "G",gml.graph[:id]
       assert_equal true,gml.nodes.has_key?("n0")
       assert_equal "n5:",gml.nodes["n5"].subgraphs.keys.first
    	 assert_equal 14,gml.nodes.size
    	 assert_equal 12,gml.edges.size
    end 

 end
end
