require 'httparty'
require 'json'

module Sources
  module Number
    class Ullrtodaycount < Sources::Number::Base
      @@cache = {}

      def cached_get(key)
        return yield if Rails.env.test?

        time = Time.now.to_i
        if entry = @@cache[key]
          if entry[:time] > 5.minutes.ago.to_i
            Rails.logger.info("Sources::Datapoints - CACHE HIT for #{key}")
            return entry[:value]
          end
        end

        value = yield
        @@cache[key] = { :time => time, :value => value }
        value
      end

      def available?
        true
      end

      def supports_target_browsing?
        false
      end

      def supports_functions?
        false
      end

      def custom_fields
        [
          { :name => "product", :title => "Product", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "url", :title => "URL", :mandatory => true },
          { :name => "type", :title => "total/fail/timeout", :mandatory => true}
        ]
      end

      def get(options = {})
        widget     = Widget.find(options.fetch(:widget_id))
        product = widget.settings.fetch(:product)
        branch = widget.settings.fetch(:branch)
        type = widget.settings.fetch(:type)
        base_url = widget.settings.fetch(:url)

        request_url = "#{base_url}/#{type}?product=#{product}&branch=#{branch}"

        # field = widget.settings.fetch(:field).to_i
        cached_result = cached_get("ullr-#{type}") do
           HTTParty.get(request_url).body
        end
        response = JSON.parse(cached_result)
        { :value => response["data"][0]["test_count"] }
      end

    end
  end
end
