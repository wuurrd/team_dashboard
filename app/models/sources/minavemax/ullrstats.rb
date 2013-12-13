require 'httparty'
require 'json'

module Sources
  module Minavemax
    class Ullrstats < Sources::Minavemax::Base
      @@cache = {}

      def cached_get(key)
        return yield if Rails.env.test?

        time = Time.now.to_i
        if entry = @@cache[key]
          if entry[:time] > 5.minutes.ago.to_i
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

      def custom_fields
        [
          { :name => "product", :title => "Product", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
          { :name => "url", :title => "Url", :mandatory => true }
        ]
      end

      def get(options = {})
        widget = Widget.find(options.fetch(:widget_id))
        product = widget.settings.fetch(:product)
        branch = widget.settings.fetch(:branch)
        base_url = widget.settings.fetch(:url)
        label = widget.settings.fetch(:label)

        request_url = "#{base_url}?product=#{product}&branch=#{branch}"

        # field = widget.settings.fetch(:field).to_i
        cached_result = cached_get("ullr-#{label}") do
           HTTParty.get(request_url).body
        end
        response = JSON.parse(cached_result)
        puts response
        { 
          :total => response["data"][0]["total"], 
          :min => response["data"][0]["min"],
          :ave => response["data"][0]["ave"],
          :max => response["data"][0]["max"]
        }
      end

    end
  end
end
