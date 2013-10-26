require 'virtus'

module Barometer
  module Data
    class Geo
      include Virtus.model

      attribute :latitude, Float
      attribute :longitude, Float
      attribute :query, String
      attribute :address, String
      attribute :locality, String
      attribute :region, String
      attribute :country, String
      attribute :country_code, String
      attribute :postal_code, String

      def coordinates
        [latitude, longitude].join(',')
      end

      def to_s
        [address, locality, region, country || country_code].
          compact.reject(&:empty?).join(', ')
      end

      def merge(other_geo)
        return unless other_geo.is_a?(Data::Geo)
        Data::Geo.new(merged_attributes(other_geo))
      end

      private

      def merged_attributes(other_geo)
        attributes.merge(other_geo.attributes) do |key, oldval, newval|
          oldval || newval
        end
      end
    end
  end
end
