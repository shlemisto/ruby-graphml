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
 