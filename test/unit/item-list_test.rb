$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
$LOAD_PATH << File.expand_path('..', __FILE__)
require 'test/unit'
require 'mock_client'
require 'google-reader/item-list'

class TagTest < Test::Unit::TestCase
    ITEM_LIST_1_STR = IO.read(File.expand_path('../../fixtures/google-reader-blog.json', __FILE__))
    ITEM_LIST_2_STR = IO.read(File.expand_path('../../fixtures/google-reader-blog-next.json', __FILE__))

    def setup
        @client = MockClient.new
    end

    def test_01_constructor
        il = Google::Reader::ItemList.new(@client)
        assert il.instance_variable_get(:@client) == @client
        assert il.instance_variable_get(:@items).empty?
        assert !il.next?
        assert il.next.nil?
        il = Google::Reader::ItemList.new(@client, ITEM_LIST_1_STR)
        assert il.instance_variable_get(:@id)           == 'feed/http://googlereader.blogspot.com/atom.xml'
        assert il.instance_variable_get(:@title)        == 'Official Google Reader Blog'
        assert il.instance_variable_get(:@url)          == 'https://www.google.com/reader/api/0/stream/contents/feed/http://googlereader.blogspot.com/atom.xml'
        assert il.instance_variable_get(:@description)  == 'News, tips and tricks from the Google reader team.'
        assert il.instance_variable_get(:@updated)      == 1291234023
        assert il.instance_variable_get(:@continuation) == 'CN-zmeLUv5wC'
        assert il.instance_variable_get(:@direction)    == 'ltr'
        assert il.instance_variable_get(:@items).is_a?(Array)
        assert il.instance_variable_get(:@items).size   == 20
    end

    def test_02_forwarding
        il = Google::Reader::ItemList.new(nil)
        assert il.size   == 0
        assert il.empty?
        il << 1
        assert il.size   == 1
        assert il[0]     == 1
        assert il.first  == 1
        assert il.empty? == false
        il[1] = 2
        assert il.size   == 2
        assert il[0]     == 1
        assert il[1]     == 2
        assert il.last   == 2
        il[0] = 3
        assert il.size   == 2
        assert il[0]     == 3
        assert il.first  == 3
        assert il[1]     == 2
        a = []; il.each{|i| a << i}
        assert a == [3, 2]
        assert il.collect{|i| (i * 2)} == [6, 4]
        assert il.reverse == [2, 3]
        assert il.sort    == [2, 3]
        assert il.shift  == 3
        assert il.pop    == 2
        assert il.empty?
    end

    def test_03_merge_query_string
        assert Google::Reader::ItemList.merge_query_string('http://example.com/page', {
                                                                :count        => 10,
                                                                :order        => 'o',
                                                                :tag          => 'newtag',
                                                                :start_time   => 123456789,
                                                                :timestamp    => 987654321,
                                                                :exclude      => 'state/com.google/read',
                                                                :continuation => 'abcDEFghi',
                                                                :client       => 'RubyClient',
                                                                :output       => 'json'
                                                           }) ==
        'http://example.com/page?c=abcDEFghi&ck=987654321&client=RubyClient&n=10&ot=123456789&output=json&r=o&s=newtag&xt=state/com.google/read'

        assert Google::Reader::ItemList.merge_query_string('http://example.com/page?n=25&r=a', {:count => 10, :order => 'o'}) == 'http://example.com/page?n=10&r=o'
        assert Google::Reader::ItemList.new(@client).merge_query_string('http://example.com/page?n=25', {:count => 10, :r => 'o'}) == 'http://example.com/page?n=10&r=o'
    end

    def test_04_next
        @client.access_token = Object.new
        @client.access_token.instance_eval do
            def get(*args)
                if args.first =~ /c=CN-zmeLUv5wC/
                    resp = Net::HTTPOK.new(Net::HTTP::HTTPVersion, 200, '')
                    resp.instance_variable_set(:@read, true)
                    resp.instance_variable_set(:@body, ITEM_LIST_2_STR)
                    resp
                else
                    Net::HTTPOK.new(Net::HTTP::HTTPVersion, 403, '')
                end
            end
        end

        il = Google::Reader::ItemList.new(@client, ITEM_LIST_1_STR)
        assert il.size == 20
        assert il.first.title == 'The Android Google Reader app is here!'
        assert il.last.title  == 'Calling All Ideas!'
        assert il.next?

        nl = il.next
        assert nl.size == 18
        assert nl.first.title == 'Looking for great stuff to read?'
        assert nl.last.title  == 'Better Cooking Through Reader-ing'
        assert !nl.next?

        al = il.all
        assert al.size == 38
        assert al.first.title == il.first.title
        assert al.last.title  == nl.last.title
    end
end
