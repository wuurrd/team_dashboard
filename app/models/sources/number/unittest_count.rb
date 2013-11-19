require 'httparty'
require 'json'

module Sources
  module Number

    # Gives you the score for a user in the Jenkins CI game.
    # See https://wiki.jenkins-ci.org/display/JENKINS/The+Continuous+Integration+Game+plugin
    # for the Jenkins plugin
    #
    # The following parameters must be provided:
    # * url - URL of the game's leaderboard
    # * user_name - user name for the user whose score you want to show
    class UnittestCount < Sources::Number::Base

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
          { :name => "url", :title => "URL", :mandatory => true },
          { :name => "project", :title => "Project", :mandatory => true },
        ]
      end

      def get(options = {})
        widget = Widget.find(options.fetch(:widget_id))
        url = widget.settings.fetch(:url)
        project = widget.settings.fetch(:project)
        url  = "#{url}/job/#{project}/api/json"
        response = HTTParty.get(url)

        doc = JSON.parse(response.body)
        coverage = doc['healthReport'].to_s
        cov_pattern = /out of a total of (.*) tests/
        value = coverage.match(cov_pattern)[1].gsub(',', '').to_f
        { :value => value }
      end
    end
  end
end
