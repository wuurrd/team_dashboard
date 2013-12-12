require 'httparty'
require 'json'

module Sources
  module Datapoints
    class ItvmTestTimer < Sources::Datapoints::Base

      def supports_target_browsing?
        false
      end

      def custom_fields
        [
          { name: "hostname", title: "QA Status Hostname", mandatory: true },
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

        hostname = widget.settings.fetch(:hostname)
        project = widget.settings.fetch(:project)
        branch = widget.settings.fetch(:branch)
        sort_by = widget.settings.fetch(:sort_by)
        direction = widget.settings.fetch(:direction)
        target_models = targetsArray(widget.settings.fetch(:target_model))
                
        params = "limit=1000000"
        params << "&sort_by=#{sort_by}" unless sort_by.blank?
        params << "&direction=#{direction}" unless direction.blank?
        params << "&from_date=#{Time.at(from)}"
        params << "&to_date=#{Time.at(to)}"
        target_models.each do |target_model|
          params << "&target_model[]=#{target_model}"
        end

        datapoints = []
        targets.each do |target|
          url = "http://#{hostname}/#{project}/#{branch}/tezts/#{target}/results.json?#{params}"
          url = URI::encode(url)
          response = HTTParty.get(url).body
          test = JSON.parse(response)
          results = test['results'].sort_by { |r| r['created_at'] }
          data = []
          results.each do |result|
            timestamp = result['created_at'].to_time.to_i
            duration = itvm_duration(result)
            if duration.abs > 5
              data << [duration, timestamp]
            end
          end
          datapoints << { target: "#{test['name']}", datapoints: data}
        end
        datapoints
      end

      def itvm_duration(result)
        created_at = Time.parse(result['created_at']).to_i
        finished_at = Time.parse(result['finished_at']).to_i
        test_duration = result['duration'].to_i
        finished_at - created_at - test_duration
      end

      #def available_targets(options = {})
      # not supported
      #end

    end
  end
end
