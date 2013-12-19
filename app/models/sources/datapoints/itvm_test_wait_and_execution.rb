require 'httparty'
require 'json'

module Sources
  module Datapoints
    class ItvmTestWaitAndExecution < Sources::Datapoints::Base

      def supports_target_browsing?
        false
      end

      def custom_fields
        [
          { name: "hostname", title: "QA Status Hostname", mandatory: true },
          { name: "project", title: "Project", mandatory: true },
          { name: "branch", title: "Branch", mandatory: true },
          { name: "sort_by", title: "Sort By", mandatory: true },
          { name: "direction", title: "Direction", mandatory: true },
          { name: "target_model", title: "Target Model", mandatory: true }
        ]
      end

      def get(options = {})
        from    = (options[:from]).to_i
        to      = (options[:to] || Time.now).to_i
        widget  = Widget.find(options.fetch(:widget_id))
        source  = options[:source]

        hostname = widget.settings.fetch(:hostname)
        project = widget.settings.fetch(:project)
        branch = widget.settings.fetch(:branch)
        sort_by = widget.settings.fetch(:sort_by)
        direction = widget.settings.fetch(:direction)
        target_model = targetsArray(widget.settings.fetch(:target_model)).first
        test_id = targetsArray(widget.settings.fetch(:targets)).first

        params = "limit=1000000"
        params << "&sort_by=#{sort_by}"
        params << "&direction=#{direction}"
        params << "&from_date=#{Time.at(from)}"
        params << "&to_date=#{Time.at(to)}"
        params << "&target_model=#{target_model}"

        url = "http://#{hostname}/#{project}/#{branch}/tezts/#{test_id}/results.json?#{params}"
        url = URI::encode(url)
        response = HTTParty.get(url).body
        test = JSON.parse(response)
        results = test['results'].sort_by { |r| r['created_at'] }

        wait_data = []
        exec_data = []
        results.each do |result|
          next unless valid(result)
          timestamp = result['created_at'].to_time.to_i
          exec_time = result['duration']
          wait_time = itvm_duration(result)
          wait_data << [wait_time, timestamp]
          exec_data << [exec_time, timestamp]
        end
        datapoints = []
        datapoints << { target: "run time", datapoints: exec_data}
        datapoints << { target: "wait time", datapoints: wait_data}
      end

      def valid(result)
        if result['result_status_id'] != 1 ||
          result['revision'].blank? ||
          result['duration'] < 5 ||
          itvm_duration(result).abs < 5 ||
          itvm_duration(result).abs > 10000
          return false
        else
          return true
        end
      end

      def itvm_duration(result)
        created_at = Time.parse(result['created_at']).to_i
        finished_at = Time.parse(result['finished_at']).to_i
        test_duration = result['duration'].to_i
        finished_at - created_at - test_duration
      end

    end
  end
end