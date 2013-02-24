$:.unshift(File.dirname(__FILE__))
require 'parsers/weather_bug'
require 'requesters/weather_bug'

module Barometer
  class WeatherService::WeatherBug
    def self.accepted_formats
      [:short_zipcode, :coordinates]
    end

    def self.call(query, config={})
      WeatherService::WeatherBug.new(query, config).measure!
    end

    def initialize(query, config={})
      @query = query
      @converted_query = nil
      @measurement = Measurement.new

      if config[:keys]
        @api_code = config[:keys][:code]
      end
    end

    def measure!
      validate_key!
      validate_query!

      fetch_and_parse_current
      fetch_and_parse_forecast

      @measurement
    end

    private

    def validate_key!
      unless @api_code && !@api_code.empty?
        raise Barometer::WeatherService::KeyRequired
      end
    end

    def validate_query!
      @converted_query = @query.convert!(self.class.accepted_formats)

      if @converted_query && self.class.accepted_formats.include?(@converted_query.format)
        @measurement.query = @converted_query.q
        @measurement.format = @converted_query.format
      else
        raise Barometer::Query::ConversionNotPossible
      end
    end

    def fetch_and_parse_current
      payload = Barometer::Requester::WeatherBug.get_current(@converted_query, @api_code)
      parser = Barometer::Parser::WeatherBug.new(@measurement, @converted_query)
      parser.parse_current(payload)
    end

    def fetch_and_parse_forecast
      payload = Barometer::Requester::WeatherBug.get_forecast(@converted_query, @api_code)
      parser = Barometer::Parser::WeatherBug.new(@measurement, @converted_query)
      parser.parse_forecast(payload)
    end
  end
end

Barometer::WeatherService.register(:weather_bug, Barometer::WeatherService::WeatherBug)
