############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'oauth'
require 'oauth/consumer'

module Google; module Reader;

module Auth
    DEFAULT_OAUTH_CONSUMER_KEY       = 'anonymous'
    DEFAULT_OAUTH_CONSUMER_SECRET    = 'anonymous'
    DEFAULT_OAUTH_AUTHORIZE_CALLBACK = 'oob'
    OAUTH_SCOPE                      =

    def self.included(base)
        base.instance_eval do
            def google_reader_consumer_key(key = nil)
                key ? (@@google_reader_consumer_key = key) : (@@google_reader_consumer_key)
            end

            def google_reader_consumer_secret(secret = nil)
                secret ? (@@google_reader_consumer_secret = secret) : (@@google_reader_consumer_secret)
            end

            google_reader_consumer_key    DEFAULT_OAUTH_CONSUMER_KEY
            google_reader_consumer_secret DEFAULT_OAUTH_CONSUMER_SECRET
        end

        base.class_eval do
            def google_reader_authorize_callback
                DEFAULT_OAUTH_AUTHORIZE_CALLBACK
            end
        end
    end

    def consumer
        @consumer ||= ::OAuth::Consumer.new(@@google_reader_consumer_key, @@google_reader_consumer_secret, {
            :site               => 'https://www.google.com',
            :scheme             => :header,
            :http_method        => :post,
            :request_token_path => '/accounts/OAuthGetRequestToken',
            :access_token_path  => '/accounts/OAuthGetAccessToken',
            :authorize_path     => '/accounts/OAuthAuthorizeToken',
        })
    end

    def request_token
        @request_token ||= get_request_token
    end

    def access_token
        @access_token ||= get_access_token
    end

    def verifier=(verifier)
        @oauth_verifier = verifier
    end

    def extract_verifier(request_uri)
        @oauth_token    = CGI.unescape(request_uri[/oauth_token=(.*?)(&|$)/, 1])
        @oauth_verifier = CGI.unescape(request_uri[/oauth_verifier=(.*?)(&|$)/, 1])
    end

    protected

    def get_request_token
        consumer.get_request_token({:oauth_callback => google_reader_authorize_callback},
                                   {:scope => 'https://www.google.com/reader/api/', :xoauth_display_name => 'Igenesis Priority Feedzz'})
    end

    def get_access_token
        #throw "no 'request token' or 'verifier' received" unless request_token && @oauth_verifier
        return nil unless request_token && @oauth_verifier
        token = request_token.get_access_token({:oauth_verifier => @oauth_verifier})
    end
end

end; end # module Google::Reader
