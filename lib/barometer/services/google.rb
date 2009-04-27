module Barometer
  #
  # NOTE: Google does not have an official API
  #
  # Google Weather
  # www.google.com
  #
  # key required: NO
  # registration required: NO
  # supported countries: ALL
  #
  # performs geo coding
  # city: YES (except postalcode)
  # coordinates: NO
  #
  # timezone info
  # provides zone: NO
  #
  # API: http://unknown
  #
  # Possible queries:
  #
  # where query can be:
  #
  #    * zipcode (US or Canadian)
  #    * city state; city, state
  #    * city
  #    * state
  #    * country
  #
  class Google < Service
    
    def self.accepted_formats
      [:zipcode, :postalcode, :geocode]
    end
    
    def self.source_name
      :google
    end
    
    def self._measure(measurement, query, metric=true)
      raise ArgumentError unless measurement.is_a?(Barometer::Measurement)
      raise ArgumentError unless query.is_a?(Barometer::Query)
      measurement.source = self.source_name
    
      # get measurement
      result = self.get_all(query.preferred, metric)
      
      # build current
      current_measurement = self.build_current(result, metric)
      # TODO: this next line has no test
      measurement.success! if
        (current_measurement.temperature && !current_measurement.temperature.c.nil?)
      measurement.current = current_measurement
      
      # build forecast
      forecast_measurements = self.build_forecast(result, metric)
      measurement.forecast = forecast_measurements
      
      # build extra data
      measurement.location = self.build_location(query.geo)
      #measurement.timezone = self.build_timezone(forecast_result)

      measurement
    end

    def self.build_current(current_result, metric=true)
      raise ArgumentError unless current_result.is_a?(Hash)
      
      current = CurrentMeasurement.new
      
      if current_result && current_result['forecast_information'] &&
         current_result['forecast_information']['current_date_time']
        current.time = current_result['forecast_information']['current_date_time']['data']
      end
      
      current_result = current_result['current_conditions'] if current_result['current_conditions']

      begin
        current.humidity = current_result['humidity']['data'].match(/[\d]+/)[0].to_i
      rescue
      end
      
      if current_result['icon']
        current.icon = current_result['icon']['data']
      end
      #current.condition = current_result['condition']['data']
      
      temp = Temperature.new(metric)
      if metric
        temp.c = current_result['temp_c']['data'].to_f if current_result['temp_c']
      else
        temp.f = current_result['temp_f']['data'].to_f if current_result['temp_f']
      end
      current.temperature = temp
    
      begin
        wind = Speed.new(metric)
        if metric
          wind.kph = current_result['wind_condition']['data'].match(/[\d]+/)[0].to_i
        else
          wind.mph = current_result['wind_condition']['data'].match(/[\d]+/)[0].to_i
        end
        wind.direction = current_result['wind_condition']['data'].match(/Wind:.*?([\w]+).*?at/)[1]
        current.wind = wind
      rescue
      end

      current
    end
    
    def self.build_forecast(forecast_result, metric=true)
      raise ArgumentError unless forecast_result.is_a?(Hash)

      forecasts = []
      return forecasts unless forecast_result && forecast_result['forecast_information'] &&
                              forecast_result['forecast_information']['forecast_date']
      start_date = Date.parse(forecast_result['forecast_information']['forecast_date']['data'])
      forecast_result = forecast_result['forecast_conditions'] if forecast_result['forecast_conditions']

      # go through each forecast and create an instance
      d = 0
      forecast_result.each do |forecast|
        forecast_measurement = ForecastMeasurement.new

        forecast_measurement.icon = forecast['icon']['data']

        if (start_date + d).strftime("%a").downcase == forecast['day_of_week']['data'].downcase
          forecast_measurement.date = start_date + d
        end

        high = Temperature.new(metric)
        if metric
          high.c = forecast['high']['data'].to_f
        else
          high.f = forecast['high']['data'].to_f
        end
        forecast_measurement.high = high

        low = Temperature.new(metric)
        if metric
          low.c = forecast['low']['data'].to_f
        else
          low.f = forecast['low']['data'].to_f
        end
        forecast_measurement.low = low
        
        #forecast_measurement.condition = forecast['condition']['data']

        forecasts << forecast_measurement
        d += 1
      end

      forecasts
    end
    
    def self.build_location(geo=nil)
      raise ArgumentError unless (geo.nil? || geo.is_a?(Barometer::Geo))
      
      location = Location.new
      if geo
        location.city = geo.locality
        location.state_code = geo.region
        location.country = geo.country
        location.country_code = geo.country_code
        location.latitude = geo.latitude
        location.longitude = geo.longitude
      end
      
      location
    end
    
    # def self.build_timezone(timezone_result)
    #   raise ArgumentError unless timezone_result.is_a?(Hash)
    #   
    #   timezone = nil
    #   if timezone_result && timezone_result['simpleforecast'] &&
    #      timezone_result['simpleforecast']['forecastday'] &&
    #      timezone_result['simpleforecast']['forecastday'].first &&
    #      timezone_result['simpleforecast']['forecastday'].first['date']
    #     timezone = Barometer::Zone.new(Time.now.utc,timezone_result['simpleforecast']['forecastday'].first['date']['tz_long'])
    #   end
    #   timezone
    # end
    
    # use HTTParty to get the current weather
    def self.get_all(query, metric=true)
      Barometer::Google.get(
        "http://google.com/ig/api",
        :query => {:weather => query, :hl => (metric ? "en-GB" : "en-US")},
        :format => :xml
      )['xml_api_reply']['weather']
    end
    
  end
end