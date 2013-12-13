require 'httparty'
require 'json'

module Sources
  module StatusTable
    class JenkinsCommits < Sources::StatusTable::Base
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

      def custom_fields
        [
          { :name => "target_model", :title => "Target model", :mandatory => true },
          { :name => "jenkins_url", :title => "Jenkins URL", :mandatory => true}
        ]
      end

      def get(options = {})
        widget = Widget.find(options.fetch(:widget_id))
        target = widget.settings.fetch(:target_model)
        jenkins_url = widget.settings.fetch(:jenkins_url)
        url = "#{jenkins_url}/job/#{target}/api/json"
        data = cached_get("commit_#{target}", 10) do
            JSON.parse(HTTParty.get(url).body)
        end
        builds = data["builds"]
        build_json_response(builds, target)
      end

      private

        def map_result_values(status)
          case status
            when "SUCCESS"
              0
            when "UNSTABLE"
              1
            when "FAILURE"
              2
            else
              3
          end
        end

        def build_json_response(builds, target)
          all_messages = []
          overall_value = nil
          latest_build_number = nil
          builds.each do |build|
            build_number = build["number"]
            build_url = build["url"]
            build_data = cached_get("build_#{build_number}", 1) do
              JSON.parse(HTTParty.get("#{build_url}/api/json").body)
            end
            build_result = build_data["result"]
            items = build_data["changeSet"]["items"]
            status = map_result_values(build_result)
            overall_value ||= status
            latest_build_number ||= build["number"]
            if not items.empty?
              items.each do |item|
                author = item["author"]["fullName"]
                commit_msg = item["msg"]
                all_messages << {
                  status: status,
                  label: "#{author} - #{build_number}",
                  value: commit_msg
                }
              end
            else
              all_messages << {status: status, label: "N/A", value: ""}
            end
          end
          {
            overall_value: overall_value,
            first_value: {
                          label: target,
                          value: "- #{latest_build_number}"
                         },
            label: all_messages
          }
        end
    end
  end
end
