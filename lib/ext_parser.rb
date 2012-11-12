class GraphML
  class Parser 

      def initialize  file_or_str,graphml
        @current_node = nil
        @current_key = nil
        @current_edge = nil
        @state = nil
        @sub_state = nil
        @graphml=graphml
        data = ((File.file?( file_or_str )) ? File::new(file_or_str) : file_or_str)
        @xmlDoc = REXML::Document::new( data )
        parse( @xmlDoc.root )
      end
      
      def parse( node ) #:nodoc:
        send( node.name.to_sym, node )
      end
      def to_hash attrs
      	h=Hash.new
      	attrs.each{|key,value| h[key.to_sym]=attrs[key]}
      	h
      end
      def graphml( node ) #:nodoc:
        @graphml<<to_hash(node.attributes)
        node.each_element( ) do |child|
          begin
            send( "graphml_#{child.name}".to_sym, child )
          rescue NoMethodError => e
            raise GraphMLError, "node #{child.name} can't be child of graphml"
          end
        end
      end

      def graphml_data(node)
         @graphml.add_data to_hash(node.attributes),node.texts().join("\n")
      end

      def graphml_key( node ) #:nodoc:
         @current_key=@graphml.add_key to_hash(node.attributes)  
           node.each_element( ) do |child|
            begin
              send( "graphml_key_default".to_sym, child )
            rescue NoMethodError => e

              raise GraphMLError, "node #{child.name} can be child of key"
            end
          end
      end
   
      def graphml_key_default( node ) #:nodoc:
        @current_key.text << node.texts().join('\n')
      end

      def graphml_graph( node ) #:nodoc:
        if @current_graph.nil? # parent is graphml
          @graph = @graphml.add_graph to_hash(node.attributes)
          @current_graph = @graph
          previous_graph = @graph
        else # parent is node
          previous_graph = @current_graph
          @current_graph = @current_node.add_graph to_hash(node.attributes)
        end

        node.each_element( ) do |child|
          send( "graphml_graph_#{child.name}".to_sym, child )
        end

        @current_graph = previous_graph
      end

      def graphml_graph_data( node ) #:nodoc:
        begin
          if node.elements.size>0
            text=""
            node.elements.each{|elem| text<<elem.to_s<<"\n"}
          else
            text=node.texts().join('\n')
          end

          data=@current_graph.add_data to_hash(node.attributes),text
        rescue ArgumentError => e
          warn e
        end
      end

      def graphml_graph_node( node ) #:nodoc:
        @current_node  = @current_graph.add_node to_hash(node.attributes)

        node.each_element( ) do |child|
          case child.name
          when "graph"
            graphml_graph( child )
          else
            begin
              send( "graphml_graph_node_#{child.name}".to_sym, child )
            rescue NoMethodError => e
              raise GraphMLError, "node #{child.name} can be child of node"
            end
          end
        end
        @current_node = nil
      end

      def graphml_graph_node_data( node ) #:nodoc:
        begin
          if node.elements.size>0
            text=""
            node.elements.each{|elem| text<<elem.to_s<<"\n"}
          else
            text=node.texts().join('\n')
          end
          @current_node.add_data to_hash(node.attributes),text
        rescue ArgumentError => e
          warn e
        end
      end

      def graphml_graph_node_port( node ) #:nodoc:
        port = @current_node.add_port to_hash(node.attributes)
      end

      def graphml_graph_edge( node ) #:nodoc:
        
        @current_edge =@current_graph.add_edge to_hash(node.attributes)

        node.each_element( ) do |child|
          begin
            send( "graphml_graph_edge_#{child.name}".to_sym, child )
          rescue NoMethodError => e
            raise GraphMLError, "node #{child.name} can be child of edge"
          end
        end

        @current_edge = nil
      end

      def graphml_graph_edge_data( node ) #:nodoc:
        
        begin
          @current_edge.add_data to_hash(node.attributes),node.texts().join('\n')
        rescue ArgumentError => e
          warn e
        end
      end

      def graphml_graph_hyperedge( node ) #:nodoc:
        hyperedge=@current_graph.add_hyperedge to_hash(node.attributes)
        node.each_element( ) do |child|
          if child.name == "endpoint"
              hyperedge.add_endpoint to_hash(child.attributes)              
          end
        end
      end
    end
end