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
            's'  => self.id,     # the subscription id
            'ac' => 'subscribe', # the action
            'T'  => client.token # the write access token
        }
        client.access_token.post('/reader/api/0/subscription/edit', params).code_type == Net::HTTPOK and begin
            client.user.subscriptions << self
            true
        end
    end

    def unsubscribe
        params = {
            's'  => self.id,       # the subscription id
            'ac' => 'unsubscribe', # the action
            'T'  => client.token   # the write access token
        }
        client.access_token.post('/reader/api/0/subscription/edit', params).code_type == Net::HTTPOK and begin
            client.user.subscriptions.reject!{|s| s.id == self.id}
            true
        end
    end

    def set_title(title)
        self_title
        params = {
            's'  => self.id,     # the subscription id
            't'  => title,       # the subscription's title
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        client.access_token.post('/reader/api/0/subscription/edit', params).code_type == Net::HTTPOK and begin
            self.title = title
            true
        end
    end

    def add_label(label)
        label = label.is_a?(Google::Reader::Tag) ? label.id : Google::Reader::Tag.build_id(label, self.client.user)
        raise "duplicate label #{label}" if self.labels.collect(&:id).include?(label)
        params = {
            's'  => self.id,     # the subscription id
            'a'  => label,       # the label to be added
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        client.access_token.post('/reader/api/0/subscription/edit', params).code_type == Net::HTTPOK and begin
            labels << self.class.new('id' => label, 'label' => label[(label.rindex('/label/') + 7) .. -1])
            true
        end
    end

    def remove_label(label)
        label = label.is_a?(Google::Reader::Tag) ? label.id : Google::Reader::Tag.build_id(label, self.client.user)
        raise "invalid label #{label}" unless self.labels.collect(&:id).include?(label)
        params = {
            's'  => self.id,     # the subscription id
            'r'  => label,       # the label to be added
            'ac' => 'edit',      # the action
            'T'  => client.token # the write access token
        }
        client.access_token.post('/reader/api/0/subscription/edit', params).code_type == Net::HTTPOK and begin
            labels.delete_if{|l| l.id == label}
            true
        end
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
