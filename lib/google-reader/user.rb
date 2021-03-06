############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'
require 'google-reader/subscription'
require 'google-reader/item-list'
require 'google-reader/item-ref'

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

    def initialize(cli, hash = nil)
        @client = cli
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

    protected

    def self.define_item_list_method(prefix)
        class_eval <<EOS
    def #{prefix}_items(params = {})
        @#{prefix}_items ||= filtered_items_list('#{prefix.gsub(/_/, '-')}', params)
    end

    def #{prefix}_items!(params = {})
        @#{prefix}_items = nil
        #{prefix}_items(params)
    end
EOS
    end

    def self.define_item_ids_method(prefix)
        class_eval <<EOS
    def #{prefix}_item_ids(params = {})
        filtered_item_ids('#{prefix.gsub(/_/, '-')}', params)
    end
EOS
    end

    # retrieve the a list of items from a given user, using a given filter
    def filtered_items_list(filter, params = {})
        resp = @client.access_token.get(ItemList.merge_query_string("/reader/api/0/stream/contents/user/#{user_id}/state/com.google/#{filter}?output=json", params))
        raise "unable to retrieve the list of #{filter} items for user \"#{user_id}\": #{resp.inspect}" unless resp.code_type == Net::HTTPOK
        Google::Reader::ItemList.new(@client, resp.body)
    end

    # retrieve the a list of items ids/refs from a given user, using a given filter
    def filtered_item_ids(filter, params = {})
        resp = @client.access_token.get(ItemList.merge_query_string("/reader/api/0/stream/items/ids?output=json&s=user/#{user_id}/state/com.google/#{filter}&n=20", params))
        raise "unable to retrieve the list of #{filter} item ids for user \"#{user_id}\": #{resp.inspect}" unless resp.code_type == Net::HTTPOK
        JSON.parse(resp.body)['itemRefs'].collect do |hash|
            Google::Reader::ItemRef.new(hash)
        end
    end

    public

    # retrieve the contents of each item present in the array parameter
    def items_from_ids(ids_array)
        id_strs = ids_array.collect do |id|
            id = if id.is_a? Google::Reader::ItemRef
                     id.id
                 elsif id.is_a?(Fixnum) || id.is_a?(Bignum)
                     id
                 else
                     raise "invalid item id type: #{id} (class: #{id.class})"
                 end
            "i=#{id}"
        end

        resp = @client.access_token.post("/reader/api/0/stream/items/contents", id_strs.join("&"))
        raise "unable to retrieve the item contents for user \"#{user_id}\": #{resp.inspect}" unless resp.code_type == Net::HTTPOK
        Google::Reader::ItemList.new(@client, resp.body)
    end

    define_item_list_method('broadcast')
    define_item_ids_method('broadcast')
    alias :shared_items    :broadcast_items
    alias :shared_items!   :broadcast_items!
    alias :shared_item_ids :broadcast_item_ids
end

class CurrentUser < User
    attr_accessor :friends

    # retrieve the list of subscriptions/feeds
    def subscriptions
        @subscriptions ||= begin
            resp = @client.access_token.get('/reader/api/0/subscription/list?output=json')
            raise "unable to retrieve the list of subscription for user \"#{user_id}\": #{resp.inspect}" unless resp.code_type == Net::HTTPOK
            JSON.parse(resp.body)['subscriptions'].collect do |hash|
                Google::Reader::Subscription.new(hash.merge({:client => @client}))
            end
        end
    end

    # define bang (!) version of the 'subscriptions' method that bypasses
    # the cache
    def subscriptions!
        @subscriptions = nil
        subscriptions
    end

    # retrieve the list of tags/folders
    def tags
        @tags ||= begin
            resp = @client.access_token.get('/reader/api/0/tag/list?output=json')
            raise "unable to retrieve the list of tags for user \"#{user_id}\": #{resp.inspect}" unless resp.code_type == Net::HTTPOK
            JSON.parse(resp.body)['tags'].collect do |hash|
                Google::Reader::Tag.new(hash.merge({:client => @client}))
            end
        end
    end

    # define bang (!) version of the 'tags' method that bypasses
    # the cache
    def tags!
        @tags = nil
        tags
    end

    # define 'list items' methods filtered by state; also, add an bang (!)
    # version of each *_items method, that bypasses the cache
    # and forces a new request
    %w(broadcast
       broadcast_friends
       kept_unread
       read
       reading_list
       starred
       tracking_body_link_used
       tracking_emailed
       tracking_item_link_used
       tracking_kept_unread).each do |prefix|
        define_item_list_method(prefix)
        define_item_ids_method(prefix)
    end

    # create a few method aliases to enable friendlier (or more common names
    # (for instance, shared vs broadcast)
    alias :reading_list              :reading_list_items
    alias :reading_list!             :reading_list_items!
    alias :reading_list_ids          :reading_list_item_ids
    alias :all_items                 :reading_list_items
    alias :all_items!                :reading_list_items!
    alias :all_item_ids              :reading_list_item_ids
    alias :shared_friends_items      :broadcast_friends_items
    alias :shared_friends_items!     :broadcast_friends_items!
    alias :shared_friends_item_ids   :broadcast_friends_item_ids
    alias :followed_body_items       :tracking_body_link_used_items
    alias :followed_body_items!      :tracking_body_link_used_items!
    alias :followed_body_item_ids    :tracking_body_link_used_item_ids
    alias :emailed_items             :tracking_emailed_items
    alias :emailed_items!            :tracking_emailed_items!
    alias :emailed_item_ids          :tracking_emailed_item_ids
    alias :followed_items            :tracking_item_link_used_items
    alias :followed_items!           :tracking_item_link_used_items!
    alias :followed_item_ids         :tracking_item_link_used_item_ids
    alias :kept_unread_ever_items    :tracking_kept_unread_items
    alias :kept_unread_ever_items!   :tracking_kept_unread_items!
    alias :kept_unread_ever_item_ids :tracking_kept_unread_item_ids

    # add the special the special case 'unread_items', which doesn't not
    # have a dedicated API method; we need to fetch the entire reading list
    # and exclude the 'read' items
    def unread_items(params = {})
        @unread_items ||= filtered_items_list('reading-list', params.merge(:exclude => 'user/-/state/com.google/read'))
    end
    def unread_items!(params = {})
        @unread_items = nil
        unread_items(params)
    end
    def unread_item_ids(params = {})
        @unread_items ||= filtered_item_ids('reading-list', params.merge(:exclude => 'user/-/state/com.google/read'))
    end
end

end; end # module Google::Reader
