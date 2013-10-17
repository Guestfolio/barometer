require 'barometer/weather_services/forecast_io/query'

module Barometer
  module WeatherService
    class ForecastIo
      class Api < Api
        def initialize(query, api_code)
          @query = ForecastIo::Query.new(query)
          @api_code = api_code
        end

        def format
          :json
        end

        def url
          "https://api.forecast.io/forecast/#{@api_code}/#{@query.to_param}"
        end

        def params
          @query.units_param
        end
      end
    end
  end
end