require 'ext_parser'
require 'ext_util'

require 'rexml/document'
include REXML

class GraphML
  class GraphMLError < RuntimeError
  end
 
  class Key
    attr_accessor :text
    include GraphML::ExtCore
    def initialize *arg
      attrs,default=arg
      attrs||={}
     self<<attrs      
     @text=default
     yield( self ) if block_given?
    end
  end

  class Edge
    include GraphML::ExtCore
    attr_accessor :data,:graph
    def initialize *arg
      attrs, graph=arg
      @graph = graph
      @data ={}
      self<<attrs
      # source.out_edges << self
      # target.in_edges << self
      yield( self ) if block_given?
    end
    
    def add_data *attrs 
      attrs,text=attrs
      attrs={:key => attrs} if attrs.kind_of? String
    	data=Data.new attrs,text
    	@data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 

     def get_or_new_data *attrs
      attrs,text=attrs
      attrs={:key => attrs} if attrs.kind_of? String
      data=@data[attrs[:key]]
      data=Data.new attrs,text if data.nil?
      data.text=text
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 
    	
    def source
      @graph.graphml.nodes[self[:source]]
    end
    
    def target
      @graph.graphml.nodes[self[:target]]
    end
   
    def elements
      e=[]
      e.concat @data.values
      e.count>0 ? e : nil
    end
  end

  class Hyperedge
    include GraphML::ExtCore
    attr_accessor :endpoints,:graph
    def initialize *arg
      attrs, graph=arg
      @graph=graph
      self<<attrs
      @endpoints={}
      yield( self ) if block_given?
    end 

    def add_endpoint attrs={}
       attrs={:node => attrs} if attrs.kind_of? String
       endpoint=EndPoint.new attrs
       endpoint[:id] ="ep"+endpoints.count.to_s
       endpoints[endpoint[:id]]=endpoint
       yield( endpoint ) if block_given?
       endpoint
    end
    def elements
      e=[]
      e.concat @endpoints.values
      e.count>0 ? e : nil
    end     
  end

  class EndPoint
    include GraphML::ExtCore
    def initialize *arg
      attrs=arg.first
      self<<attrs
      yield( self ) if block_given?
    end 
  end

  class Data
  	 include GraphML::ExtCore
     attr_accessor :text
  	 def initialize *arg
       attrs,text=arg
       attrs||={}
  	 	 self<<attrs
       @text=text
       yield( self ) if block_given?
  	 end

  	 def key name,graph
  	 	graph.keys[:name]
  	 end

     def cdata= value
      @text="<![CDATA["+value.to_s+"]]>"
     end 

  end 

  class Port 
    include GraphML::ExtCore
    def initialize *arg
      attrs=arg.first
      self<<attrs
      yield( self ) if block_given?
    end
  end

  class Node
    attr_accessor :subgraphs,:data,:ports,:graph,:bind
    include GraphML::ExtCore
    def initialize *arg
      attrs, graph=arg
      @graph = graph
      self<<attrs
      @bind={}
      @data = {}
      @subgraphs ={}
      @ports ={}
      @in_edges = []
      @out_edges = []
      yield( self ) if block_given?
    end
    
    def in_edges
      r=[]
      edges=graphml.edges
      edges.each{|edge|
               r<<edge.target if edge.target==self
      }
      r
    end

    def out_edges
      r=[]
      edges=graphml.edges
      edges.each{|edge|
               r<<edge.source if edge.source==self
      }
      r
    end

    def elements
      e=[]
      e.concat @data.values
      e.concat @ports.values 
      e.concat @subgraphs.values
      e.count>0 ? e : nil
    end

    def add_port attrs={}
      attrs={:name => attrs} if attrs.kind_of? String
      port=Port.new attrs
      @ports[port[:name]]=port
      yield( port ) if block_given?
      port
    end
      
    def add_data *attrs 
      attrs,text=attrs
      attrs={:key => attrs} if attrs.kind_of? String
      data=Data.new attrs,text
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 


    def add_key_and_data keyname,data,type="string",&block
        key=graphml.get_or_new_key keyname+"key"
        key<<{:for=>"node", :"attr.name"=>keyname, :"attr.type"=>type}
        data=get_or_new_data key[:id],data
        block.call key,data if block
        self
    end

    def graphml
        parent=@graph.parent

        if parent.kind_of?GraphML or parent.nil?
          parent
        else
            #parent is node
            parent.graphml
        end
    end
    def data_by_attrname name,attr_name="attr.name"
       k=""
       graphml.keys.each{|id,key|
                  
                  attrname=key[attr_name.to_sym]

                  next if attrname.nil?

                  if attrname.strip==name.strip
                    k=key[:id]
                    break
                  end   
           }
       data[k]    
    end

    def get_or_new_data *attrs
      attrs,text=attrs
      attrs={:key => attrs} if attrs.kind_of? String
      data=@data[attrs[:key]]
      data=Data.new attrs,text if data.nil?
      data.text=text
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 


    
    def add_graph attrs={}
      attrs={:id => attrs} if attrs.kind_of? String
    	graph=Graph.new attrs,self
    	@subgraphs[graph[:id]]=graph
      yield( graph ) if block_given?
      graph
    end 
    	
    def key(name)
      key_obj = @graph.keys[name]
      val = @data[key_obj[:id]]
      return key_obj[:default] if val.nil?
      val
    end
  end
  
  class Graph
    attr_accessor :nodes, :edges, :id, :edgedefault,:parent,:bind
    include GraphML::ExtCore
    def initialize *attrs
      attrs,@parent=attrs
      self<<attrs      
      @nodes = {}
      @edges = {}
      @hyperedges ={}
      yield( self ) if block_given?

    end
    
    def graphml
        parent=@parent
        if parent.kind_of?GraphML  
          parent
        else
            #parent is node
            parent.graphml
        end
    end

    def elements
      e=[]
      e.concat @nodes.values
      e.concat @edges.values
      e.concat @hyperedges.values 
      e.count>0 ? e : nil
    end

    def add_node attrs={}
      attrs={:id => attrs} if attrs.kind_of? String
      node =@nodes[attrs[:id]] 
      if node.nil?
      	node = Node.new attrs,self  
      	node[:id]="n"+nodes.count.to_s unless node[:id]
      	@nodes[node[:id]]=node
      else
        node<<attrs
      end
      graphml.nodes[node[:id]]=node
      yield( node ) if block_given?
    	node
    end
    
    def get_or_new_node id
      node=graphml.nodes[id.to_s]
      node =add_node(id) unless node
      yield( node ) if block_given?
      node
    end


    def add_edge *attrs 
      source,target= attrs
      source={:source => source,:target=>target} if source.kind_of? String
    	edge=Edge.new source,self
    	edge[:id]=("e"+edges.count.to_s) if edge[:id].nil?
    	@edges[edge[:id]]=edge
      graphml.edges[edge[:id]]=edge
      yield( edge ) if block_given?
    	edge
    end

    def add_hyperedge attrs={}
      attrs={:id => attrs} if attrs.kind_of? String
      hyperedge=HyperEdge.new attrs,self
      hyperedge[:id]="h"+hyperedges.count.to_s unless hyperedge[:id]
      @hyperedges[hyperedge[:id]]=hyperedge
      yield( hyperedge ) if block_given?
      hyperedge
    end

   end
end

class GraphML
    VERSION = "1.0.0"
    DEFAULT_NS ={
                   :xmlns => "http://graphml.graphdrawing.org/xmlns",
                   :"xmlns:xsi" =>"http://www.w3.org/2001/XMLSchema-instance",
                   :"xsi:schemaLocation"=>"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd"
                }
    attr_accessor :graph,:data,:keys,:nodes,:edges
    include GraphML::ExtCore    

    def initialize *arg
        file_or_str=arg.first
        file_or_str||=""
        @data={}
        @keys={}
        @nodes={}
        @edges={}
        self<<DEFAULT_NS
        Parser.new file_or_str,self if file_or_str and file_or_str.length>0
        yield( self ) if block_given?
    end
 
    def add_graph attrs={}
      attrs={:id => attrs} if attrs.kind_of? String
      @graph=Graph.new attrs,self
      yield( @graph ) if block_given?
      @graph
    end

    def add_key attrs={}
      attrs={:id => attrs} if attrs.kind_of? String

      key = Key.new attrs

      key[:id]=keys.count unless key[:id]

      @keys[key[:id]]=key
      yield( key ) if block_given?
      key
    end 

    def get_or_new_key id
      key=@keys[id.to_sym]
      key =add_key(id) unless key
      yield( key ) if block_given?
      key
    end

    def add_data attrs={},text
      attrs={:key => attrs} if attrs.kind_of? String
      data=Data.new attrs,text
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 

    def data_by_attrname name
       k=""
       keys.each{|id,key|
                  if key[:"attr.name"].strip==name.strip
                    k=key[:id]
                    break
                  end   
           }
       data[k]    
    end

    def elements
      e=[]
      e.concat @keys.values
      e<<@graph if @graph
      e.concat @data.values 
      e.count>0 ? e : nil
    end

    def output opt={}
       File.open(opt[:file], 'w') do |f2|  
          f2.puts to_xml
        end 
    end 
end