require 'net/http'
require 'json'

module Gumroad
  API_ROOT = "https://gumroad.com/api/v1/"

  class Client
    # via http://snippets.dzone.com/posts/show/11121
    class << self
      attr_accessor :token, :password

      def symbolize_keys arg
        case arg
        when Array
          arg.map { |elem| symbolize_keys elem }
        when Hash
          Hash[
            arg.map { |key, value|  
              k = key.is_a?(String) ? key.to_sym : key
              v = symbolize_keys value
              [k,v]
            }]
        else
          arg
        end
      end
        
      def url(route)
        API_ROOT + route
      end

      def uri(route)
        URI.parse(self.url(route))
      end

      # method is string
      def authed_request(uri, method, params = {})
        klass = method.capitalize
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::const_get(klass).new(uri.request_uri)
        request.set_form_data(params) if method != "get"
        if @token and @password
          # do stuff
          request.basic_auth(@token, @password)
        end
        response = http.request(request)
        rep = symbolize_keys(JSON.parse(response.body))
        if !rep[:success]
          raise GumroadError, "#{(rep && (rep[:error] && rep[:error][:message]) || rep[:message]) || 'No message found.'}"
        end
        rep
      end

      def method_missing(method, *args, &block)
        if [:post, :delete, :put].member? method
          return authed_request(self.uri(args[0]), method.to_s, args[1]) if args.length == 2
          return authed_request(self.uri(args[0]), method.to_s, {}) if args.length == 1
        else
          super
        end
      end

      def get(route, params = {})
        route += "?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))
        authed_request(self.uri(route), "get", {})
      end
    end
  end

  class Dirtyable
    def self.dirty_attr(*args)
      @dirty_attrs = args
      dirty_attrs = "@dirty_attrs"

      args.each do |arg|
        ivar = "@#{arg}"
        define_method("#{arg}=") do |val|
          instance_variable_set(ivar, val)
          if (!(instance_variable_defined? dirty_attrs))
            instance_variable_set(dirty_attrs, [])
          end
          (instance_variable_get(dirty_attrs) << arg).uniq!
        end
        define_method("#{arg}") do |val|
          instance_variable_get(ivar)
        end
      end
    end

    def dirty?(field)
      @dirty_attrs.member? field 
    end
  end

  class Link < Dirtyable
    attr_reader :id, :currency, :short_url
    # too much fun not to do
    dirty_attr :name, :url, :description
    attr_reader :price # is actually dirtyable as well, but needs custom validation

    def self.find_all
      Client.get("links")[:links].collect {|l| Link.new(l)}
    end

    def self.find(id)
      Link.new(Client.get("links/#{id}")[:link])
    end

    def self.create(params)
      Link.new(Client.post("links", params)[:link])
    end

    def initialize(params = {})
      @dirty_attrs = []
      load(params)
    end

    def load(params = {})
      ivars = self.methods - Object.methods
      params.each do |k, v|
        if ivars.member? k
          setter = (k.to_s + "=").to_sym
          if ivars.member? setter
            self.send(setter, v)
          else
            instance_variable_set("@" + k.to_s, v)
          end
        end
      end
      @dirty_attrs = []
    end

    def save
      if @dirty_attrs.length > 0
        params = {}
        @dirty_attrs.each {|d| params[d] = self.send(d)}
        load(Client.put("links/#{self.id}", params)[:link])
      end
      self
    end

    def self.destroy(id)
      Client.delete("links/#{id}")
      true
    end

    def destroy
      Link.destroy(self.id)
    end

    # need to do some custom validation for price=
    # ensure it's a whole integer
    def price=(price)
      p_int = 0
      if price.is_a? Float and price % 1 != 0
        raise "Invalid price #{price}: must be whole-number integer"
      end
      begin
        p_int = Integer(price)
      rescue Exception => e
        raise "Invalid price #{price}: must be whole-number integer"
      end
      if p_int < 0
        raise "Invalid price #{price}: must be positive"
      end
      (@dirty_attrs << :price).uniq!
      @price = p_int
      return p_int
    end
  end

  class Session
    attr_reader :email, :password

    def initialize(email, password)
      @email = email
      @password = password

      # auth in
      res = Client.post("sessions", {email: @email, password: @password})
      Client.token = res[:token]
      Client.password = @password
    end

    def links
      Client.get("links")[:links].collect {|l| Link.new(l)}
    end

    def logout
      Client.delete("sessions")
      true
    end
  end

  class GumroadError < StandardError
  end
end