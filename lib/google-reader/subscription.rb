############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'google-reader/underscore-mash'
require 'google-reader/tag'

module Google; module Reader;

class Subscription < UnderscoreMash
    def subscribe
        params = {
            's'  => id,          # the subscription id
            'ac' => 'subscribe', # the action
            'T'  => client.token # the write access token
        }
        resp = client.access_token.post('/reader/api/0/subscription/edit', params)
        resp.code_type == Net::HTTPOK or raise "unable to subscribe to \"#{id}\": #{resp.inspect}"
        client.user.subscriptions << self
        true
    end

    def unsubscribe
        params = {
            's'  => id,            # the subscription id
            'ac' => 'unsubscribe', # the action
            'T'  => client.token   # the write access token
        }
        resp = client.access_token.post('/reader/api/0/subscription/edit', params)
        resp.code_type == Net::HTTPOK or raise "unable to unsubscribe from \"#{id}\": #{resp.inspect}"
        client.user.subscriptions.reject!{|s| s.id == id}
        true
    end

    def set_title(title)
        self_title
        params = {
            's'  => id,          # the subscription id
            't'  => title,       # the subscription's title
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        resp = client.access_token.post('/reader/api/0/subscription/edit', params)
        resp.code_type == Net::HTTPOK or raise "unable to set title of \"#{id}\" to \"#{title}\": #{resp.inspect}"
        self.title = title
        true
    end

    def add_label(label)
        label = label.is_a?(Google::Reader::Tag) ? label.id : Google::Reader::Tag.build_id(label, client.user)
        labels.collect(&:id).include?(label) and raise "duplicate label \"#{label}\""
        params = {
            's'  => id,          # the subscription id
            'a'  => label,       # the label to be added
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        resp = client.access_token.post('/reader/api/0/subscription/edit', params)
        resp.code_type == Net::HTTPOK or raise "unable to add label \"#{label}\" to \"#{id}\": #{resp.inspect}"
        labels << self.class.new('id' => label, 'label' => label[(label.rindex('/label/') + 7) .. -1])
        true
    end

    def remove_label(label)
        label = label.is_a?(Google::Reader::Tag) ? label.id : Google::Reader::Tag.build_id(label, client.user)
        labels.collect(&:id).include?(label) or raise "unknown label \"#{label}\""
        params = {
            's'  => id,          # the subscription id
            'r'  => label,       # the label to be added
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        resp = client.access_token.post('/reader/api/0/subscription/edit', params)
        resp.code_type == Net::HTTPOK or raise "unable to remove label \"#{label}\" from \"#{id}\": #{resp.inspect}"
        labels.delete_if{|l| l.id == label}
        true
    end

    # alias the 'categories' attribute as 'labels', which is term used
    # by the Google Reader UI
    def labels
        self['categories']
    end
    def labels=(labels)
        self['categories'] = labels
    end
end

end; end # module Google::Reader
