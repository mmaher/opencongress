module ::ActionController
  if Rails.version < '2.3'
    class AbstractRequest                         
      def relative_url_root
        Facebooker.path_prefix
      end
      
      # def relative_url_root
      #   "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']||ENV['FACEBOOK_CANVAS_PATH']}" if (parameters['fb_sig']  && (ENV['FACEBOOKER_RELATIVE_URL_ROOT']||ENV['FACEBOOK_CANVAS_PATH']))
      # end                                         
    end
  else
    class Request                         
      def relative_url_root
        Facebooker.path_prefix
      end                                         
    end
  end
  
  class Base
    def self.relative_url_root
      Facebooker.path_prefix
    end
  end  
  
  class UrlRewriter
    RESERVED_OPTIONS << :canvas
    def link_to_new_canvas?
      @request.parameters["fb_sig_in_new_facebook"] == "1" 
    end
    def link_to_canvas?(params, options)
      option_override = options[:canvas]
      return false if option_override == false # important to check for false. nil should use default behavior
      option_override || (can_safely_access_request_parameters? && (@request.parameters["fb_sig_in_canvas"] == "1" ||  @request.parameters[:fb_sig_in_canvas] == "1" ))
    end
    
    #rails blindly tries to merge things that may be nil into the parameters. Make sure this won't break
    def can_safely_access_request_parameters?
      @request.request_parameters
    end
      
    def rewrite_url_with_facebooker(*args)
      options = args.first.is_a?(Hash) ? args.first : args.last
      is_link_to_canvas = link_to_canvas?(@request.request_parameters, options)
      if is_link_to_canvas && !options.has_key?(:host)
        options[:host] = Facebooker.canvas_server_base
      end 
      options.delete(:canvas)
      Facebooker.request_for_canvas(is_link_to_canvas) do
        path = rewrite_url_without_facebooker(*args)

        if (ENV['FACEBOOKER_CALLBACK_PATH']) then
          path.sub!("/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}#{ENV['FACEBOOKER_CALLBACK_PATH']}", "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}")
        end

        path
      end
    end
        
    alias_method_chain :rewrite_url, :facebooker
  end
end
