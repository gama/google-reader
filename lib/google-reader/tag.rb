############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'

module Google; module Reader;

class Tag < UnderscoreMash
    Read       = self.new(:id => 'state/com.google/read')
    Starred    = self.new(:id => 'state/com.google/starred')
    Shared     = self.new(:id => 'state/com.google/broadcast')
    Broadcast  = self.new(:id => 'state/com.google/broadcast')
    KeptUnread = self.new(:id => 'state/com.google/kept-unread')

    def self.build_id(label, user)
        "user/#{user.is_a?(Google::Reader::User) ? user.user_id : user}/label/#{label}"
    end

    def label
        (self.id.nil? || (idx = self.id.rindex('/label/')).nil?) ? nil : self.id[(idx + 7) .. -1]
    end

    def share(val = true)
        params = {
            's'   => self.id,     # the tag id
            'pub' => val,         # true => public/share, false => not public/unshare
            'T'   => client.token # the write-access token
        }
        client.access_token.post('/reader/api/0/tag/edit', params)
    end

    def unshare
        share(false)
    end

    def disable
        params = {
            's'  => self.id,        # the tag id
            'ac' => 'disable-tags', # action (only known value: disable-tags'
            'T'  => client.token    # the write-access token
        }
        client.access_token.post('/reader/api/0/disable-tag', params)
    end
    alias :delete :disable

    def to_s
        self.id.to_s
    end
end

end; end # module Google::Reader
