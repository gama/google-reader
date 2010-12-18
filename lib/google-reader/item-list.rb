############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

require 'json'
require 'google-reader/item'

module Google; module Reader;

class ItemList
    attr_reader :items

    def initialize(req_proxy, json_str = nil)
        @request_proxy = req_proxy
        if json_str
            json = JSON.parse(json_str)
            %w(author title updated direction continuation).each do |key|
                instance_variable_set(('@'+key).to_sym, json[key])
            end
            @url   = json['self'].first['href']
            @items = json['items'].collect{|i| Google::Reader::Item.new(i)}
        else
            @items = Array.new
        end
    end

    def size
        @items.size
    end

    # check whether there are more items available (using the 'continuation'
    # attribute')
    def next?
        !@continuation.nil?
    end
    alias :has_next? :next?
    alias :more? :next?

    # fetch next batch of items, if available
    def next(params = {})
        next? or return nil
        resp = @request_proxy.get(merge_query_string(@url, params.merge({:continuation => @continuation})))
        self.class.new(@request_proxy, resp.body)
    end
    alias :more :next

    # fetch all available items
    def all
        all_items = Array.new
        cur_items = self
        begin
            all_items += cur_items.items
            cur_items = cur_items.next
        end until cur_items.nil?
        all_items
    end

    def self.merge_query_string(url, new_params)
        url = URI.parse(url) if url.is_a?(String)
        url.is_a?(URI) or return nil

        query_hash = url.query.split(/\&/).collect{|i|i.split(/=/)}

        query_hash = convert_key_aliases(query_hash).merge(convert_key_aliases(new_params))
        url.query = query_hash.collect{|k, v| "#{k}=#{v}"}.join('&')
        url.to_s
    end
    def merge_query_string(*args); self.class.merge_query_string(*args); end

    protected

    def self.convert_key_aliases(query_hash)
        new_hash = {} 
        query_hash.each do |key, value|
            new_key = case key.to_s
                      when 'n',  'count', 'n_items': 'n'
                      when 'r',  'order':            'r'
                      when 'ot', 'start_time':       'ot'
                      when 'ck', 'timestamp':        'ck'
                      when 'xt', 'exclude':          'xt'
                      when 'c',  'continuation':     'c'
                      when 'client':                 'client'
                      when 'output':                 'output'
                      else raise "invalid key: #{key}"
                      end
            new_hash[new_key] = value
        end
        new_hash
    end
end

end; end # module Google::Reader
