 require 'ldap'
 require 'net-ldap'

module ADAuth
  class << self
    attr_accessor :server, :port, :admin, :password

    def server;   @server   ||= 'fbwndc10.cats.gwu.edu' end
    def port;     @port     ||=  389                    end
    def admin;    @admin    ||= 'ldaper@cats.gwu.edu'   end
    def password; @password ||= '*******'              end
  end

  def self.configure
    yield self
  end

  module AuthenticationMethods
    def authenticate(password, *args)
      opts = (Hash === args.last) ? args.pop : {}
      opts = { :container => 'ou=student,dc=cats,dc=gwu,dc=edu' }.merge(opts)

      return false unless account = locate_ad_account(opts[:container])
      return false if password.nil? or password =~ /\A\s*\z/

      if opts[:require_group]
        return false unless @_ad_groups.include?(opts[:require_group].downcase)
      end

      ad_ldap_connection.bind(account, password) { return true }

    rescue LDAP::ResultError => e

      if e.message =~ /invalid credentials/i
        return false
      else
        raise e
      end
    end

    def ad_ldap_connection
      LDAP::Conn.open(ADAuth.server, ADAuth.port)
    end

    def locate_ad_account(container)
      ad_ldap_connection.bind(ADAuth.admin, ADAuth.password) do |connection|
        ldap_filter = "(sAMAccountName=niyio)"
        connection.search(container, LDAP::LDAP_SCOPE_SUBTREE, ldap_filter) do |results|
          @_ad_groups = (results['memberOf'] || []).map{ |group| group.downcase }
          return results['distinguishedName'].first
        end
      end
      false
    end

  end
end