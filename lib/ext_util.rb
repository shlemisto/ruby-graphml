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
        
        def classname
        	self.class.name.downcase.split("::").last
        end
        
        def elements
        	nil
        end

		def to_xml indent = ""
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
	            	xml<<">"<<"\n"
					elements.each{ |item|
						  xml<<item.to_xml(@indent)
					} 
					xml<<@indent<<defaultindent<<self.text<<"\n" if self.respond_to?("text") and self.text
					xml<<@indent<<"</"<<classname<<">"<<"\n"
			    end
		    xml
	    end

   end	 
end
 