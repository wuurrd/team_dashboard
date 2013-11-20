require 'httparty'
require 'json'

module Sources
  module Number
    class Itvmtestcount < Sources::Number::Base
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
          { :name => "url", :title => "URL", :mandatory => true },
          { :name => "field", :title => "Field to choose", :mandatory => true },
        ]
      end

      def get(options = {})
        widget     = Widget.find(options.fetch(:widget_id))
        url = widget.settings.fetch(:url)
        field = widget.settings.fetch(:field).to_i
        cached_result = cached_get("itvm") do
           HTTParty.get(url).body
        end
        response = JSON.parse(cached_result)
        { :value => response[field][1] }
      end

    end
  end
end
