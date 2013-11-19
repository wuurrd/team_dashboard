require 'httparty'
require 'json'

module Sources
  module Datapoints
    class Itvmworker < Sources::Datapoints::Base

      def supports_target_browsing?
        true
      end

      def get(options = {})
        from    = (options[:from]).to_i
        to      = (options[:to] || Time.now).to_i

        widget  = Widget.find(options.fetch(:widget_id))
        targets = targetsArray(widget.settings.fetch(:targets))
        source  = options[:source]

        datapoints = []
        targets.each do |target|
          target_data = JSON.parse(HTTParty.get("http://itvm.qa.rd.tandberg.com/worker/usage/#{target}").body)[0]
          data = []
          target_data['data'].each do |d|
            data << [d[1], d[0].to_f / 1000.0]
            puts from, to, d[0]
          end
          datapoints << { :target => target, :datapoints => data }
        end
        datapoints
      end

      def available_targets(options = {})
        pattern = options[:pattern] || ""
        limit = options[:limit] || 200
        response = HTTParty.get('http://itvm.qa.rd.tandberg.com/worker/widget/list')
        workers = JSON.parse(response.body)
        targets = []
        workers.each do |worker|
            targets << worker[0].to_s
        end
        puts "FOO", targets
        targets
      end

    end
  end
end
