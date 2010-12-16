############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'
require 'google-reader/subscription'
require 'google-reader/item-list'

module Google; module Reader;

class User < UnderscoreMash
    # user types & flags (taken from
    # http://groups.google.com/group/fougrapi/browse_thread/thread/ba43dcaabe896bd3/a8527d8aab29e60d?lnk=gst&q=friends#a8527d8aab29e60d)
    @@types = [
        :FOLLOWER,              # 0: this person is following the user
        :FOLLOWING,             # 1: the user is following this person
        :NOTYPE2,               # 2: n/a
        :CONTACT,               # 3: this person is in the user's contacts list
        :PENDING_FOLLOWING,     # 4: the user is attempting to follow this person
        :PENDING_FOLLOWER,      # 5: this person is attempting to follow this user
        :ALLOWED_FOLLOWING,     # 6: the user is allowed to follow this person
        :ALLOWED_COMMENTING     # 7: the user is allowed to comment on this person's shared items
    ]
    @@flags = [
        :IS_ME,            # 0: represents the current user
        :IS_HIDDEN,        # 1: current user has hidden this person from the list of people with shared items that show up
        :IS_NEW,           # 2: this person is a recent addition to the user's list of people that they follow
        :USER_READER,      # 3: this person uses reader
        :IS_BLOCKED,       # 4: the user has blocked this person
        :HAS_PROFILE,      # 5: this person has created a Google Profile
        :IS_IGNORED,       # 6: this person has requested to follow the user, but the use has ignored the request
        :IS_NEW_FOLLOWER,  # 7: this person has just begun to follow the user
        :IS_ANONYMOUS,     # 8: this person doesn't have a display name set
        :HAS_SHARED_ITEMS  # 9: this person has shared items in reader
    ]

    # create constantized version of each flag & type
    @@types.each_with_index do |flag, index|
        const_set(flag, index)
    end
    @@flags.each_with_index do |flag, index|
        const_set(flag, index)
    end

    def initialize(req_proxy, hash = nil)
        @request_proxy = req_proxy
        super(hash, default, &blk)
        friends = Array.new
    end

    def has_flag?(flag)
        ((self['flags'] & (1 << flag)) > 0)
    end

    def flags
        bitmap_flags = self['flags']
        (0 .. @@flags.size).collect do |i|
            @@flags[i] if ((bitmap_flags & (1 << i)) > 0)
        end.compact
    end

    def has_type?(type)
        self['types'].include?(type)
    end

    def types
        self['types'].collect{|t| @@types[t]}
    end

    def user_id
        user_ids.first
    end

    # returns the list of broadcast, or shared items
    def broadcast_items
        @broadcast_items ||= filtered_items_list('broadcast')
    end
    alias :shared_items :broadcast_items

    protected

    # retrieve the a list of items from a given user, using a given filter
    def filtered_items_list(filter, params = {})
        begin
            resp = @request_proxy.get(ItemList.merge_query_string("/reader/api/0/stream/contents/user/#{user_id}/state/com.google/#{filter}?output=json", params))

            raise "unable to retrieve the list of #{filter} items for user #{user_id}" unless resp.code_type == Net::HTTPOK
            Google::Reader::ItemList.new(@request_proxy, resp.body)
        end
    end
end

class CurrentUser < User
    attr_accessor :friends

    # retrieve the list of subscriptions/feeds
    def subscriptions
        @subscriptions ||= begin
            resp = @request_proxy.get('/reader/api/0/subscription/list?output=json')
            raise "unable to retrieve the list of subscription for user #{user_id}" unless resp.code_type == Net::HTTPOK
            JSON.parse(resp.body)['subscriptions'].collect do |f|
                Google::Reader::Subscription.new(f)
            end
        end
    end

    # returns the list with all items
    def all_items(params = {})
        @all_items ||= filtered_items_list('reading-list', params)
    end
    alias :reading_list :all_items

    # returns the list of 'unread' items
    def unread_items(params = {})
        @unread_items ||= filtered_items_list('unread', params.merge(:exclude => 'user/-/state/com.google/read'))
    end

    # returns the list of 'read' items
    def read_items(params = {})
        @read_items ||= filtered_items_list('read', params)
    end

    # returns the list of items that the user's friends have shared
    def broadcast_friends_items(params = {})
        @broadcast_friends_items ||= filtered_items_list('broadcast-friends', params)
    end
    alias :shared_friends_items :broadcast_friends_items

    # returns the list of items that the user has 'starred'
    def starred_items(params = {})
        @starred_items ||= filtered_items_list('starred', params)
    end

    # returns the list of items that are currently marked as 'keep-unread'
    # by the user
    def kept_unread_items(params = {})
        @kept_unread_items ||= filtered_items_list('kept-unread', params)
    end

    # returns the list of items which the user has ever clicked on a link
    # inside its body
    def tracking_body_link_items(params = {})
        @tracking_body_link_items ||= filtered_items_list('tracking-body-link-used', params)
    end
    alias :followed_body_items :tracking_body_link_items

    # returns the list of items which the user has ever emailed to someone
    def tracking_emailed_items(params = {})
        @tracking_emailed_items ||= filtered_items_list('tracking-emailed', params)
    end
    alias :emailed_items :tracking_emailed_items

    # returns the list of items which the user has ever clicked on a link
    # inside its description
    def tracking_link_items(params = {})
        @tracking_link_items ||= filtered_items_list('tracking-item-link-used', params)
    end
    alias :followed_items :tracking_link_items

    # returns the list of items which the user has ever marked as 'keep-unread'
    def tracking_kept_unread_items(params = {})
        @tracking_kept_unread_items ||= filtered_items_list('tracking-kept-unread', params)
    end
    alias :kept_unread_ever_items :tracking_kept_unread_items
end

end; end # module Google::Reader
