############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'

module Google; module Reader;

class Item < UnderscoreMash
    attr_accessor :client

    STR_ID_PREFIX = 'tag:google.com,2005:reader/item/'

    def self.num_id(str)
        str.start_with?(STR_ID_PREFIX) or raise "invalid string id: #{str}"
        num = "0x#{str[-16..-1]}".hex
        num[63] == 1 and num = (num - 0xFFFFFFFFFFFFFFFF - 1)
        num
    end

    def self.str_id(num)
        STR_ID_PREFIX + ('%016x' % num)[-16..-1]
    end

    def item_ref_id
        self.class.num_id(self.id)
    end

    def mark_as_read
        add_tag("user/#{client.user.user_id}/#{Tag::Read}")
    end

    def mark_as_unread
        remove_tag("user/#{client.user.user_id}/#{Tag::Read}")
    end

    def add_star
        add_tag("user/#{client.user.user_id}/#{Tag::Starred}")
    end

    def remove_star
        remove_tag("user/#{client.user.user_id}/#{Tag::Starred}")
    end

    def share
        add_tag("user/#{client.user.user_id}/#{Tag::Shared}")
    end

    def unshare
        remove_tag("user/#{client.user.user_id}/#{Tag::Shared}")
    end

    def keep_unread
        add_tag("user/#{client.user.user_id}/#{Tag::KeptUnread}")
    end

    def keep_read
        remove_tag("user/#{client.user.user_id}/#{Tag::KeptUnread}")
    end
    alias :unkeep_unread :keep_read

    def add_tag(tag)
        categories.include?(tag) and raise "duplicate tag \"#{tag}\""
        params = {
            'i'  => id,          # item
            'a'  => tag,         # label/state to add
            'ac' => 'edit',      # action (only known value: edit)
            'T'  => client.token # token
        }
        resp = client.access_token.post('/reader/api/0/edit-tag', params)
        resp.code_type == Net::HTTPOK or raise "unable to add tag \"#{tag}\" to item \"#{id}\": #{resp.inspect}"
        categories << tag
        true
    end

    def remove_tag(tag)
        categories.include?(tag) or raise "unknown tag \"#{tag}\""
        params = {
            'i'  => id,          # item
            'r'  => tag,         # label/state to remove
            'ac' => 'edit',      # action (only known value: edit)
            'T'  => client.token # the write-access token
        }
        resp = client.access_token.post('/reader/api/0/edit-tag', params)
        resp.code_type == Net::HTTPOK or raise "unable to remove tag \"#{tag}\" from item \"#{id}\": #{resp.inspect}"
        categories.delete(tag)
        true
    end
end

end; end # module Google::Reader
