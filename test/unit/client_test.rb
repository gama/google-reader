############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
require 'test/unit'
require 'mock_client'

class ClientTest < Test::Unit::TestCase
    def setup
        @client = MockClient.new
    end

    def teardown
    end

    def test_user
        assert_kind_of     Google::Reader::User, @client.user
        assert_instance_of String, @client.user.given_name
        assert_match       /^\d+$/, @client.user.user_id
        assert_instance_of Array,  @client.user.friends
    end

    def test_token
        assert @client.token.is_a?(String)
    end
end
