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
          { :name => "hostname", :title => "QA Status Hostname", :mandatory => false },
          { :name => "project", :title => "Project", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "test_id", :title => "Test ID", :mandatory => true },
          { :name => "target_model", :title => "Target Model", :mandatory => true },
        ]
      end

      # Returns ruby hash:
      def get(options = {})
          widget = Widget.find(options.fetch(:widget_id))
          hostname = widget.settings.fetch(:hostname).presence || "qastatus.rd.tandberg.com"
          project = widget.settings.fetch(:project)
          branch = widget.settings.fetch(:branch)
          test_id = widget.settings.fetch(:test_id)
          target_models = widget.settings.fetch(:target_model).split(";").map { |t| t.strip }

          params = "limit=9"
          target_models.each { |model| params << "&target_model[]=#{model}" }
          url = "http://#{hostname}/#{project}/#{branch}/tezts/#{test_id}/results.json?#{params}"

          data = cached_get(url, 1) do
            JSON.parse(HTTParty.get(url).body)
          end
          build_json_response(data)
      end

      def build_json_response(data)
        possible_values = {
            0 => -1, #Pending
            1 => 0, #Passed
            2 => 2, #Failed
            3 => 3, #Setup error
            4 => 3, #Upload error
        }

        messages = []
        data['results'].each do |result|
          messages << {
            status: possible_values[result['result_status_id']],
            label: result['target_model'],
            value: result['revision'].truncate(10)
          }
        end

        last_completed = messages.find { |msg| msg[:status] >= 0 }
        overall_value = last_completed ? last_completed[:status] : -1

        { overall_value: overall_value, first_value: {label: data['name'], value: ""}, label: messages }
      end

    end
  end
end
