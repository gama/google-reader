$LOAD_PATH << File.expand_path('../../../lib', __FILE__)
require 'test/unit'
require 'mock_client'
require 'google-reader/subscription'

class SubscriptionTest < Test::Unit::TestCase
    GOOGLE_READER_FEED_ID = 'feed/http://googlereader.blogspot.com/atom.xml'

    def setup
        @client = MockClient.new
    end

    def test_01_list
        assert_instance_of Array, @client.user.subscriptions
    end

    def test_02_subscribe
        n_subscriptions = @client.user.subscriptions.size
        assert Google::Reader::Subscription.new('id' => GOOGLE_READER_FEED_ID, 'client' => @client).subscribe
        subscriptions = @client.user.subscriptions!
        assert_instance_of Google::Reader::Subscription, subscriptions.find{|s| s.id == GOOGLE_READER_FEED_ID}
        assert subscriptions.size == (n_subscriptions + 1)
    end

    def test_03_set_title
        subscription = @client.user.subscriptions.find{|s| s.id ==  GOOGLE_READER_FEED_ID}
        assert subscription.set_title('newtitle')
        subscription2 = @client.user.subscriptions!.find{|s| s.id ==  GOOGLE_READER_FEED_ID}
        assert subscription.object_id != subscription2.object_id
        assert subscription2.title == 'newtitle'
    end

    def test_04_add_label
        assert Google::Reader::Subscription.new(:id => GOOGLE_READER_FEED_ID, :client => @client).subscribe
        subscription = @client.user.subscriptions.find{|s| s.id ==  GOOGLE_READER_FEED_ID}
        assert subscription.add_label('testlabel')
        subscription2 = @client.user.subscriptions!.find{|s| s.id == GOOGLE_READER_FEED_ID}
        assert subscription.object_id != subscription2.object_id
        assert subscription2.labels.collect(&:label).include?('testlabel')
        assert_raise RuntimeError do; subscription2.add_label('testlabel'); end # duplicate label
    end

    def test_05_remove_label
        subscription = @client.user.subscriptions.find{|s| s.id ==  GOOGLE_READER_FEED_ID}
        assert subscription.labels.collect(&:label).include?('testlabel')
        assert subscription.remove_label('testlabel')
        subscription2 = @client.user.subscriptions!.find{|s| s.id == GOOGLE_READER_FEED_ID}
        assert subscription.object_id != subscription2.object_id
        assert !subscription2.labels.collect(&:label).include?('testlabel')
        assert_raise RuntimeError do; subscription2.remove_label('invalidlabel'); end
    end

    def test_06_unsubscribe
        n_subscriptions = @client.user.subscriptions.size
        assert Google::Reader::Subscription.new(:id => GOOGLE_READER_FEED_ID, :client => @client).unsubscribe
        assert @client.user.subscriptions.size == (n_subscriptions - 1)
    end
end
