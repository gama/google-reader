############################################################
# Copyright (c) 2010, iGenesis Ltda.                       #
# Author: Gustavo Machado C. Gama <gustavo.gama@gmail.com> #
############################################################

$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
require 'test/unit'
require 'mock_client'
require 'google-reader/tag'
require 'google-reader/user'

class TagTest < Test::Unit::TestCase
    GOOGLE_READER_FEED_ID = 'feed/http://googlereader.blogspot.com/atom.xml'

    def setup
        @client = MockClient.new
    end

    def test_01_build_id
        assert Google::Reader::Tag.build_id('test_label_1', '0123456789') == 'user/0123456789/label/test_label_1'
        assert Google::Reader::Tag.build_id('test_label_2', Google::Reader::User.new(nil, 'user_ids' => ['9876543210'])) == 'user/9876543210/label/test_label_2'
    end

    def test_02_label
        assert Google::Reader::Tag.new('id' => 'randomstring1/label/test_label_1').label == 'test_label_1'
        assert Google::Reader::Tag.new('id' => '/label/test_label_2').label == 'test_label_2'
        assert_nil Google::Reader::Tag.new('id' => 'randomstring2/labell/test_label_3').label
        assert_nil Google::Reader::Tag.new('id' => 'randomstring2/labeltest_label_4').label
        assert_nil Google::Reader::Tag.new('id' => 'label/test_label_5').label
        assert_nil Google::Reader::Tag.new('id' => '').label
        assert_nil Google::Reader::Tag.new('id' => nil).label
    end

    def test_03_list
        assert_instance_of Array, @client.user.tags
    end

    def ensure_test_label
        unless @client.user.tags.collect(&:id).include?(Google::Reader::Tag.build_id('test_label_1', @client.user))
            # google reader does not provide an explicit create-tag operation; one must
            # add a tag to an existing item/subscription
            unless subscription = @client.user.subscriptions.first
                assert subscription = Google::Reader::Subscription.new('id' => GOOGLE_READER_FEED_ID, 'client' => @client).subscribe
            end
            assert subscription.add_label('test_label_1')
            assert @client.user.tags!.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_1', @client.user)}
        end
    end

    def test_04_rename
        ensure_test_label
        assert tag = @client.user.tags.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_1', @client.user)}
        assert tag.rename('test_label_2')
        assert tag = @client.user.tags!.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_2', @client.user)}
        assert tag.rename(Google::Reader::Tag.build_id('test_label_3', @client.user))
        assert tag = @client.user.tags!.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_3', @client.user)}
    end

    def test_05_disable
        id = Google::Reader::Tag.build_id('test_label_3', @client.user)
        assert tag = @client.user.tags!.find{|tag| tag.id == id}
        assert tag.disable
        assert !@client.user.tags!.find{|tag| tag.id == id}
    end

    def test_06_share
        ensure_test_label
        assert tag = @client.user.tags.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_1', @client.user)}
        assert tag.share
        assert Net::HTTP.get_response(URI.parse("http://www.google.com/reader/api/0/stream/contents/#{Google::Reader::Tag.build_id('test_label_1', @client.user)}")).code_type == Net::HTTPOK
    end

    def test_07_unshare
        ensure_test_label
        assert tag = @client.user.tags.find{|tag| tag.id == Google::Reader::Tag.build_id('test_label_1', @client.user)}
        assert tag.unshare
        assert Net::HTTP.get_response(URI.parse("http://www.google.com/reader/api/0/stream/contents/#{Google::Reader::Tag.build_id('test_label_1', @client.user)}")).code_type == Net::HTTPUnauthorized
    end
end
