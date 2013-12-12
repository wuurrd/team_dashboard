module Sources
  module StatusTable
    class UllrstatusResults
      @@cache = {}

      def cached_get(key, invalidation_timeout)
        return yield if Rails.env.test?

        time = Time.now.to_i
        if entry = @@cache[key]
          if entry[:time] > invalidation_timeout.minutes.ago.to_i
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

      def default_fields
        []
      end

      def custom_fields
        [
          { :name => "product", :title => "Product", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "limit", :title => "Limit", :mandatory => true },
          { :name => "url", :title => "Url", :mandatory => true }
        ]
      end

      # Returns ruby hash:
      def get(options = {})
          widget     = Widget.find(options.fetch(:widget_id))
          product = widget.settings.fetch(:product)
          branch = widget.settings.fetch(:branch)
          limit = widget.settings.fetch(:limit)
    
          base_url = widget.settings.fetch(:url)
          request_url = "#{base_url}?product=#{product}&branch=#{branch}&limit=#{limit}"

          data = cached_get("results_#{product}_#{branch}", 1) do
            HTTParty.get(request_url).body
          end
          build_json_response(JSON.parse(data))
      end

      def build_json_response(parsed_json)
        overall_value = nil
        first_value = nil
        all_messages = Array.new
        parsed_json["data"].each do |item|
          failed = item["test_fail"]
          timeouts = item["test_timeout"]
          status = 0
          if failed+timeouts > 0
            status = 2
          end         
          product = parsed_json["product"]
          branch = parsed_json["branch"]
          label = "#{product}-#{branch}"
          value = item['commit']
          overall_value ||= status
          first_value ||= label

          all_messages << {
            "status" => status,
            "label" => label,
            "value" => value.truncate(10),
          }

        end

        { :overall_value => overall_value, :first_value => {"label" => first_value, "value" => ""}, :label => all_messages }
      end
    end
  end
end
