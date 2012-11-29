class GraphML
	module ExtCore
		def [] key
			@attrs={} unless @attrs
			@attrs[key.to_sym]
		end
		def []= key,value
			@attrs={} unless @attrs
			@attrs[key.to_sym]=value
		end

		def set_attrs attrs={}
			 self << attrs
		end

		def << attrs={}
			@attrs={} unless @attrs
			@attrs=@attrs.merge attrs if attrs
		end  

		def attrs
			 @attrs
		end
        
        def classname
        	self.class.name.downcase.split("::").last
        end
        
        def elements
        	nil
        end

        def before_to_xml
        end

        def after_to_xml xml
        end
        
        def add_datakey graphml
        	if respond_to? "data"  
             
	        	 data.each{|key,data|
	                         dataattr=data.attrs.clone
	                         type=dataattr[:type]
	                         if type.nil? or type!="custom"
	                          type="string" if type.nil?
	                          dataattr.merge! :"attr.name"=>key,:"attr.type"=>type
	                         end
	                         dataattr.delete :key
	                         dataattr.delete :type
	                         which=self.class.name.split("::").last.downcase
	                         dataattr.merge! :id=>key,:for=>which
	                         graphml.add_key(dataattr) unless graphml.keys.has_key? key
	                  } 
	         
            end
           elements.each{|item| item.add_datakey(graphml) if item.respond_to?("add_datakey")} if elements
        end

		def to_xml indent = ""
			before_to_xml

			defaultindent="    "
			xml=""
			@indent=indent+defaultindent
			xml<<%Q{<?xml version="1.0" encoding="UTF-8"?>\n} if classname=="graphml"
			xml<<@indent 
            xml<<"<"<<classname
				@attrs.each{|key,value|
			            xml<<" "<<key.to_s<<"="<<%Q{"#{value.to_s}"}  
						} if @attrs
	            if(elements.nil? and !self.respond_to?("text") )
	                    xml<<"/>"<<"\n"
	            else	
	            	xml<<">"
	            	xml<<self.text  if self.respond_to?("text") and self.text
					elements.each{ |item|
						  xml<<item.to_xml(@indent)
					} if elements
					
					xml<<@indent<<"</"<<classname<<">"<<"\n"
			    end
			after_to_xml xml
		    xml
	    end



   end	 
end
 