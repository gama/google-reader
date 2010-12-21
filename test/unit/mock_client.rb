############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'oauth'
require 'google-reader/auth'
require 'google-reader/client'

class MockClient
    include Google::Reader::Auth
    include Google::Reader::Client

    attr :access_token, :request_proxy

    def initialize
        token, secret = IO.read(File.join(File.expand_path('../../', __FILE__), 'oauth-access-token')).split(/\r?\n/)
        @access_token = @request_proxy = ::OAuth::AccessToken.new(consumer, token, secret)
    end
end
