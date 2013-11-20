require 'httparty'
require 'json'

module Sources
  module Number
    class QastatusTestCount < Sources::Number::Base

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
          { :name => "project", :title => "Project", :mandatory => true },
          { :name => "branch", :title => "Branch", :mandatory => true },
        ]
      end

      def get(options = {})
        widget = Widget.find(options.fetch(:widget_id))
        branch = widget.settings.fetch(:branch)
        project = widget.settings.fetch(:project)
        url  = "http://qastatus.rd.tandberg.com/#{project}/#{branch}/tezts/live_search.json"
        response = HTTParty.get(url)

        doc = JSON.parse(response.body)
        { :value => doc["count"] }
      end
    end
  end
end
