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
    end
  end

  class Edge
    include GraphML::ExtCore
    attr_accessor :data,:graph
    def initialize source=nil,target=nil,graphv=nil
      @graph = graphv
      # @graph.add_edge self if @graph
      @data ={}
      self[:source]=source
      self[:target]=target
      # source.out_edges << self
      # target.in_edges << self
    end

     def destroy
      @graph.remove_edge self
     end

     def add_data datakey,text="" 
      if datakey.is_a? GraphML::Data
        data=datakey
      else
        data=Data.new datakey,text
      end
      data.parent=self
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

    def source
       graphml.nodes[self[:source]]
    end
    
    def target
       graphml.nodes[self[:target]]
    end

    def graphml
      @graph.graphml
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
    end 
  end

  class Data
  	 include GraphML::ExtCore
     attr_accessor :text,:key,:parent
  	 def initialize keyname,text="" 
  	 	 self<<{:key=>keyname} if keyname
       @text=text
  	 end


     def attrname
       key["attr.name"]
     end

     def key
      @parent.graphml.keys[self[:key]]
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
    end
  end

  class Node
    attr_accessor :subgraphs,:data,:ports,:graph,:bind
    include GraphML::ExtCore
    def initialize nodename=nil,graph=nil
      @graph = graph
      self<<{:id=>nodename} if nodename
      @bind={}
      @data = {}
      @subgraphs ={}
      @ports ={}
      @in_edges = []
      @out_edges = []
    end

    def destroy
       @graph.remove_node self
    end

    def in_edges
      r=[]
      edges=graphml.edges
      edges.each{|key,edge|
               r<<edge  if edge.target==self
      }
      r
    end

    def out_edges
      r=[]
      edges=graphml.edges
      edges.each{|key,edge|
               r<<edge  if edge.source==self
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
      
    def add_data datakey,text="" 
      if datakey.is_a? GraphML::Data
        data=datakey
      else
        data=Data.new datakey,text
      end
      data.parent=self
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 


    def add_key_and_data keyname,data,type="string",&block
        key=graphml.get_or_new_key keyname
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


    
    def add_graph graph_or_id
      if graph_or_id.is_a? GraphML::Graph
         graph=graph_or_id
         graph.parent=self
      else
      	graph=Graph.new graph_or_id,self
      end

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
    attr_accessor :nodes, :edges, :hyperedges,:edgedefault,:parent,:bind
    include GraphML::ExtCore
    def initialize id=nil,parent=nil
      @parent=parent
      self<<{:id=>id} if id     
      @nodes = {}
      @edges = {}
      @hyperedges ={}

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

    def allsubnodes
      r={} 
      nodes.each{|key,node|
            node.subgraphs.each{|k,subgraph|
               r.merge! subgraph.allsubnodes
             }
      }
      r.merge! nodes
    end

    def allsubedges
      r={} 
      nodes.each{|key,node|
            node.subgraphs.each{|k,subgraph|
               r.merge! subgraph.allsubedges
             }
      }
      r.merge! edges
    end

    def add_node nodename
      
      if nodename.is_a? GraphML::Node
        node=nodename
        node.graph=self
      else
        node =@nodes[nodename] 
        if node.nil?
        	node = Node.new nodename,self  
        end
      end
      
      node[:id]="n"+nodes.count.to_s unless node[:id]
      @nodes[node[:id]]=node
      
      yield( node ) if block_given?
    	node
    end

    def remove_node node
      @nodes.delete node[:id]
    end
    
    def get_or_new_node id
      node=graphml.nodes[id.to_s]
      node =add_node(id) unless node
      yield( node ) if block_given?
      node
    end


    def add_edge *attrs 
      source,target= attrs
      if source.is_a? GraphML::Edge
        edge=source
        edge.graph=self
      else
       	edge=Edge.new(source,target,self) if  source.is_a? String
        if  source.is_a? Hash
          edge=Edge.new("","",self) 
          edge<<source
        end
        edge
      end
    	edge[:id]=("#{self[:id]}::e"+edges.count.to_s) if edge[:id].nil?
    	@edges[edge[:id]]=edge
      yield( edge ) if block_given?
    	edge
    end

    def remove_edge edge
      @edges.delete edge[:id]
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
    attr_accessor :data,:keys,:nodes,:edges
    attr_reader :graph
    include GraphML::ExtCore    

    def initialize *arg
        @file_or_str=arg.first
        @file_or_str||=""
        @data={}
        @keys={}
        self<<DEFAULT_NS
        Parser.new @file_or_str,self if @file_or_str and @file_or_str.length>0
    end

    def nodes
        @graph.allsubnodes if @graph
    end

    def edges
        @graph.allsubedges if @graph
    end


    def add_graph graph_or_id
          if graph_or_id.is_a? GraphML::Graph
             graph=graph_or_id
             graph.parent=self
          else
            graph=Graph.new graph_or_id,self
          end

          @graph=graph
          yield( graph ) if block_given?
          @graph
    end 

    def auto_key_generate
      begin
      nodes.each{|k,node| 
                  node.data.each{|key,data|
                         dataattr=data.attrs.clone
                         type=dataattr[:type]
                         if type.nil? or type!="custom"
                          type="string" if type.nil?
                          dataattr.merge! :"attr.name"=>key,:"attr.type"=>type
                         end
                         dataattr.delete :key
                         dataattr.delete :type
                         dataattr.merge! :id=>key,:for=>"node" 
                         add_key(dataattr) unless keys.has_key? key
                  }
                }  
      rescue Exception => e
        
      end

      begin
      edges.each{|k,edge| 
                  edge.data.each{|key,data|
                                    dataattr=data.attrs.clone
                                    type=dataattr[:type]
                                    if type.nil? or type!="custom"
                                     type="string" if type.nil?
                                     dataattr.merge! :"attr.name"=>key,:"attr.type"=>type
                                    end
                                    dataattr.delete :key
                                    dataattr.delete :type
                                    dataattr.merge! :id=>key,:for=>"edge" 
                                    add_key(dataattr) unless keys.has_key? key
                                }
                }  
      rescue Exception => e
        
      end
      
      begin
      data.each{|key,data|
                        dataattr=data.attrs.clone
                        type=dataattr[:type]
                        if type.nil? or type!="custom"
                         type="string" if type.nil?
                         dataattr.merge! :"attr.name"=>key,:"attr.type"=>type
                        end
                        dataattr.delete :key
                        dataattr.delete :type
                        dataattr.merge! :id=>key,:for=>"graphml" 
                        add_key(dataattr) unless keys.has_key? key
                    }  
      rescue Exception => e
        
      end
      
      

      self

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
    

    def add_data datakey,text="" 
      if datakey.is_a? GraphML::Data
        data=datakey
      else
        data=Data.new datakey,text
      end
      data.parent=self
      @data[data[:key]]=data
      yield( data ) if block_given?
      data
    end 

    def graphml
      self
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
       File.new(opt[:file], 'w') do |f2|  
          f2.puts self.to_xml
        end 
    end 

    def to_file name
       file=File.new(name, 'w') 
       file.puts self.to_xml
       file.close
       file 
    end
end