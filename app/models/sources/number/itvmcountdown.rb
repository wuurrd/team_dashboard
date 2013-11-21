require 'httparty'
require 'json'

module Sources
  module Number
    class Itvmcountdown < Sources::Number::Base
      @@cache = {}

      def cached_get(key)
        return yield if Rails.env.test?

        time = Time.now.to_i
        if entry = @@cache[key]
          if entry[:time] > 10.minutes.ago.to_i
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
          { :name => "max_tasks", :title => "Tasks to countdown to", :mandatory => true },
        ]
      end

      def get(options = {})
        widget     = Widget.find(options.fetch(:widget_id))
        url = widget.settings.fetch(:url)
        max_tasks = widget.settings.fetch(:max_tasks).to_i
        cached_result = cached_get("itvm") do
           HTTParty.get(url).body
        end
        response = JSON.parse(cached_result)
        total_count = response[4][1]
        daily_count = response[3][1]
        expected = max_tasks - total_count
        days_to_expected = expected/daily_count.to_f
        hours_to_expected = days_to_expected*24
        { :value => hours_to_expected.to_i }
      end

    end
  end
end
