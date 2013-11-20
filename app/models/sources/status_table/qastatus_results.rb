module Sources
  module StatusTable
    class QastatusResults
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
          { :name => "project", :title => "Project", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "test_id", :title => "Test ID", :mandatory => true },
          { :name => "target_model", :title => "Target Model", :mandatory => true },
        ]
      end

      # Returns ruby hash:
      def get(options = {})
          widget     = Widget.find(options.fetch(:widget_id))
          project = widget.settings.fetch(:project)
          branch = widget.settings.fetch(:branch)
          test_id = widget.settings.fetch(:test_id)
          target_model = widget.settings.fetch(:target_model)

          tests_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/tezts/#{test_id}.json"
          test_name  = cached_get("name", 120) do
            JSON.parse(HTTParty.get(tests_url).body)["name"]
          end
          results_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/results.json?test_id=#{test_id}&limit=9"
          if target_model != "false"
            results_url << "&target_model=#{target_model}"
          end
          target_data = cached_get("results_#{test_id}_#{target_model}", 1) do
            JSON.parse(HTTParty.get(results_url).body)
          end
          build_json_response(target_data, test_name)
      end

      def build_json_response(parsed_json, test_name)
        #0 = Green
        #1 =
        possible_values = {
            0 => -1, #Pending
            1 => 0, #Passed
            2 => 2, #Failed
            3 => 3, #Setup error
            4 => 3, #Upload error
        }
        values_array = []
        all_messages = Array.new
        parsed_json.each do |json|
          values_array.push(json["result_status_id"])
          all_messages << {
            "status" => "#{possible_values[json["result_status_id"]]}",
            "label" => "#{json["target_model"]}",
            "value" => "#{json["revision"]}".truncate(10),
          }

        end
        if !values_array.empty?
            item = 0
            for i in values_array
                if i != 0
                    item = i
                    break
                end
            end
          overall_value = possible_values[item]
        else
          overall_value = 0
        end
        { :overall_value => overall_value, :first_value => {"label" => test_name, "value" => ""}, :label => all_messages }
      end

    end
  end
end
