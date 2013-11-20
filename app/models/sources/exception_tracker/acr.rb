require 'httparty'
require 'json'

module Sources
  module ExceptionTracker
    class Acr < Sources::ExceptionTracker::Base
      @@cache = {}

      def cached_get(key, invalidation_timeout)
        return yield if Rails.env.test?

        time = Time.now.to_i
        if entry = @@cache[key]
          if entry[:time] > invalidation_timeout.minutes.ago.to_i
            Rails.logger.info("Sources::Datapoints - CACHE HIT for #{key}")
            return entry[:value]
          end
        end

        value = yield
        @@cache[key] = { :time => time, :value => value }
        value
      end

      def custom_fields
        [
          { :name => "days", :title => "Last () Days", :mandatory => true },
        ]
      end

      def get(options = {})
        widget = Widget.find(options.fetch(:widget_id))
        days = widget.settings.fetch(:days)
        url = "http://acr.rd.tandberg.com/getCrashData.php?filtering%5Bdays%5D=#{days}&filtering%5Bsw_build_type%5D%5B%5D=rc%2Freleased&filtering%5Bsw_build_type%5D%5B%5D=official+beta&filtering%5Bsw_build_type%5D%5B%5D=official+alpha&filtering%5Bsw_build_type%5D%5B%5D=matchbox&filtering%5Bsw_build_type%5D%5B%5D=git+clean&filtering%5Bsw_build_type%5D%5B%5D=git+dirty&filtering%5Bsw_build_type%5D%5B%5D=svn&filtering%5Bsw_build_type%5D%5B%5D=Unknown&filtering%5Border%5D=submitted"
        response = cached_get("crashes_#{days}", 10) do
            HTTParty.get(url).body
        end
        data = JSON.parse(response)
        ncrashes = data['ncrashes'].to_i
        last_error_time = nil
        if ncrashes > 0
            last_error_time = data['crashes'][-1]['23']
        end
        {
          :label             => "Crashes",
          :last_error_time   => last_error_time,
          :unresolved_errors => ncrashes
        }
      end

    end
  end
end
