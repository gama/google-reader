############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'

module Google; module Reader;

class Item < UnderscoreMash
    attr_accessor :client

    module State
        Read       = 'state/com.google/read'
        Starred    = 'state/com.google/starred'
        Shared     = 'state/com.google/broadcast'
        Broadcast  = 'state/com.google/broadcast'
        KeptUnread = 'state/com.google/kept-unread'
    end

    def mark_as_read
        add_tag("user/#{client.user.user_id}/#{State::Read}")
    end

    def mark_as_unread
        remove_tag("user/#{client.user.user_id}/#{State::Read}")
    end

    def add_star
        add_tag("user/#{client.user.user_id}/#{State::Starred}")
    end

    def remove_star
        remove_tag("user/#{client.user.user_id}/#{State::Starred}")
    end

    def share
        add_tag("user/#{client.user.user_id}/#{State::Shared}")
    end

    def unshare
        remove_tag("user/#{client.user.user_id}/#{State::Shared}")
    end

    def keep_unread
        add_tag("user/#{client.user.user_id}/#{State::KeptUnread}")
    end

    def keep_read
        remove_tag("user/#{client.user.user_id}/#{State::KeptUnread}")
    end
    alias :unkeep_unread :keep_read

    def add_tag(tag)
        params = {
            'i'  => id,          # entry
            'a'  => tag,         # label/state to add
            'ac' => 'edit',      # action (only known value: edit)
            'T'  => client.token # token
        }
        client.access_token.post('/reader/api/0/edit-tag', params)
    end

    def remove_tag(tag)
        params = {
            'i'  => id,          # entry
            'r'  => tag,         # label/state to remove
            'ac' => 'edit',      # action (only known value: edit)
            'T'  => client.token # token
        }
        client.access_token.post('/reader/api/0/edit-tag', params)
    end
end

end; end # module Google::Reader
