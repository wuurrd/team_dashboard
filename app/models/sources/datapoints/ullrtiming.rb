require 'httparty'
require 'json'
require 'date'


module Sources
  module Datapoints
    class Ullrtiming < Sources::Datapoints::Base

      def supports_target_browsing?
        true
      end

      def custom_fields
        [
          { :name => "product", :title => "Product", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "url", :title => "Url", :mandatory => true}
        ]
      end

      def get(options = {})
        from    = (options[:from]).to_i
        to      = (options[:to] || Time.now).to_i

        widget  = Widget.find(options.fetch(:widget_id))

        product = widget.settings.fetch(:product)
        branch = widget.settings.fetch(:branch)
        base_url = widget.settings.fetch(:url)
        targets = targetsArray(widget.settings.fetch(:targets))
        source  = options[:source]

        request_url = "#{base_url}?product=#{product}&branch=#{branch}&from=#{from}"

        request_data = HTTParty.get(request_url).body
        product_data = JSON.parse(request_data)

        datapoints = []
        targets.each do |target|
          data = []

          product_data["data"].each_with_index do |d, index|

            seconds = 0
            if dt = DateTime.parse(d[target]) rescue false 
              seconds = dt.hour * 3600 + dt.min * 60 + dt.sec #=> 37800
            end

            timestamp = 0
            if dt = DateTime.parse(d['queue_time']) rescue false
              timestamp = dt.to_time.to_i
            end

            data << [seconds, timestamp]
          end
          
          datapoints << { :target => target, :datapoints => data }
        end
        puts datapoints
        datapoints
      end
    end
  end
end
