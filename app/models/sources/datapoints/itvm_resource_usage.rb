require 'httparty'
require 'json'

module Sources
  module Datapoints
    class ItvmResourceUsage < Sources::Datapoints::Base

      def supports_target_browsing?
        false
      end

      def get(options = {})
        from    = (options[:from]).to_i
        to      = (options[:to] || Time.now).to_i

        widget  = Widget.find(options.fetch(:widget_id))
        targets = targetsArray(widget.settings.fetch(:targets))
        source  = options[:source]

        url = "http://itvm/resources/usage/json/"

        datapoints = []
        targets.each do |target|
          params = "?types=#{target}"
          params << "&period=7"
          target_data = JSON.parse(HTTParty.get(url+params).body)[0]
          data = []
          target_data['data'].each do |d|
            data << [d[1], d[0].to_f / 1000.0]
          end
          datapoints << { :target => target, :datapoints => data }
        end
        datapoints
      end

    end
  end
end
