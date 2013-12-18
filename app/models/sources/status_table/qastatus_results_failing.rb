require 'uri'

module Sources
  module StatusTable
    class QastatusResultsFailing
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
        true
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
          { :name => "hours", :title => "Since (hours)", :mandatory => true },
        ]
      end

      # Returns ruby hash:
      def get(options = {})
          widget = Widget.find(options.fetch(:widget_id))
          project = widget.settings.fetch(:project)
          branch = widget.settings.fetch(:branch).gsub(/\.|-/, "_")
          hrs = widget.settings.fetch(:hours).to_i
          limit = 1000

          from_time = URI.encode(hrs.hours.ago.localtime.to_s)
          results_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/results.json?result_status_id=2,3,4,5&limit=#{limit}&from_date=#{from_time}"

          results_data = JSON.parse(HTTParty.get(results_url).body)

          return { :overall_value => -1,  :first_value => {"label" => "No results", "value" => ""} } if results_data.empty?
          build_json_response(results_data, project, branch)
      end

      def build_json_response(parsed_json, project, branch)
        all_messages = Array.new
        test_names = Array.new
        worst_tests = Array.new

        result_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/results/%s"
        results_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/results/platform_view?tezt_id=%s"
        parsed_json.each do |json|
          test_id = json["tezt_id"]
          test_url = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/tezts/#{test_id}.json"

          # get the test-name 
          test_name  = cached_get("tezt_id_#{test_id}", 440) do
            JSON.parse(HTTParty.get(test_url).body)["name"]
          end

          # do not add the same test twice but keep track of occurences
          worst_tests.push(test_name) 
          next if test_names.include? test_name
          test_names.push(test_name) 
          
          result_id = json["id"]
          all_messages << {
            "name" => "#{test_name}",
            "count" => 0,
            "status" => "#{json["result_status_id"]}",
            "label" => "#{test_name.truncate(20)} (%s)",
            "value" => "", 
            #<a target='_blank' href='#{result_url % [result_id]}'>last result</a> \ 
            #/<a target='_blank' href='#{results_url % [test_id]}'>platform view</a>".html_safe,
          }
        end

        # add number of fails and insert in label
        all_messages.each do |message|
            message["count"] = worst_tests.count(message["name"])
            message["label"] = message["label"] % [message["count"]]
        end

        # sort by count and reverse the hash.
        all_messages = all_messages.sort_by {|hsh| hsh["count"]}.reverse
        
        worst_test = all_messages.first
        { :overall_value => worst_test["status"], :first_value => {"label" => worst_test["label"], "value" => ""}, :label => all_messages }
      end

    end
  end
end
