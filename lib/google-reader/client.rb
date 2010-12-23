############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/user'

module Google; module Reader;

# implement the base functionality of the Google Reader API
module Client
    attr_accessor :request_proxy

    # update requests (i.e., not read-only) need an additional google-reader
    # specific token
    def token
        resp = request_proxy.get('/reader/api/0/token')
        resp.code_type == Net::HTTPOK or raise "unable to retrieve token: #{resp.inspect}"
        @google_reader_token = resp.body 
    end

    # build a profile of the logged in Google Reader user/profile
    def user
        @user ||= begin
            # we rely on the 'friends' request to fetch the user's profile; this was the only
            # reliable way I could find that did it
            _friends = friends
            _current_user = _friends.slice!(_friends.find_index{|f| f.is_a?(CurrentUser)})
            _current_user.friends = _friends
            _current_user
        end
    end
    alias :profile :user

    protected

    # fetch the list of profiles of the logged user's friends/followers
    # (which includes the logged user him/herself)
    def friends
        resp = request_proxy.get('/reader/api/0/friend/list?output=json')
        resp.code_type == Net::HTTPOK or raise "unable to retrieve the list of friends: #{resp.inspect}"
        JSON.parse(resp.body)['friends'].collect do |friend|
            ((friend['flags'] & (1 << User::IS_ME)) > 0) ? CurrentUser.new(self, friend) : User.new(self, friend)
        end
    end
end

end; end # module Google::Reader
