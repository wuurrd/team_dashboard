require 'httparty'
require 'json'

module Sources
  module Datapoints
    class QastatusTestDuration < Sources::Datapoints::Base

      def supports_target_browsing?
        false
      end

      def custom_fields
        [
          { name: "project", title: "Project", mandatory: true },
          { name: "branch", title: "Branch", mandatory: true },
          { name: "sort_by", title: "Sort By", mandatory: false },
          { name: "direction", title: "Direction", mandatory: false },
          { name: "target_model", title: "Target Model", mandatory: false }
        ]
      end

      def get(options = {})
        from    = (options[:from]).to_i
        to      = (options[:to] || Time.now).to_i

        widget  = Widget.find(options.fetch(:widget_id))
        targets = targetsArray(widget.settings.fetch(:targets))
        source  = options[:source]

        hostname = "qastatus.rd.tandberg.com"
        project = widget.settings.fetch(:project)
        branch = widget.settings.fetch(:branch)
        sort_by = widget.settings.fetch(:sort_by)
        direction = widget.settings.fetch(:direction)
        target_model = widget.settings.fetch(:target_model)

        datapoints = []
        targets.each do |target|
          query = "test_id=#{target}"
          query << "&sort_by=#{sort_by}"
          query << "&target_model=#{target_model}"
          query << "&limit=100000000"
          query << "&from_date=#{Time.at(from)}"
          query << "&to_date=#{Time.at(to)}"

          url = "http://#{hostname}/#{project}/#{branch}/results.json?#{query}"
          url = URI::encode(url)
          results = HTTParty.get(url).body
          results = JSON.parse(results)
          results = results.sort_by {|r| r['created_at']}
          data = []
          results.each do |result|
            timestamp = result['created_at'].to_time.to_i
            duration = itvm_duration(result)
            if duration.abs > 5
              data << [duration, timestamp]
            end
          end
          datapoints << { target: target, datapoints: data}
        end
        datapoints
      end

      def itvm_duration(result)
        created_at = Time.parse(result['created_at']).to_i
        finished_at = Time.parse(result['finished_at']).to_i
        test_duration = result['duration'].to_i
        finished_at - created_at - test_duration
      end

      # def available_targets(options = {})
      #   pattern = options[:pattern] || ""
      #   limit = options[:limit] || 200
      #   response = HTTParty.get('http://itvm.qa.rd.tandberg.com/worker/widget/list')
      #   workers = JSON.parse(response.body)
      #   targets = []
      #   workers.each do |worker|
      #       targets << worker[0].to_s
      #   end
      #   targets
      # end

    end
  end
end
