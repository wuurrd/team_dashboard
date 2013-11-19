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
    class Coverage < Sources::Number::Base

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
        ]
      end

      def get(options = {})
        widget     = Widget.find(options.fetch(:widget_id))
        url = widget.settings.fetch(:url)

        response = HTTParty.get(url)

        redirected_url = response.request.last_uri.to_s[0..-3]
        cov_url = "#{redirected_url}/api/json?depth=2"
        doc = JSON.parse(HTTParty.get(cov_url).body)
        coverage = doc['results']['elements']
        for cov in coverage
            if cov['name'] == 'Lines'
                value = cov['ratio']
                break
            end
        end
        { :value => value }
      end

    end
  end
end
