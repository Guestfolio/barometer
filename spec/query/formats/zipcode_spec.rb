require_relative '../../spec_helper'

module Barometer::Query
  RSpec.describe Format::Zipcode do
    describe '.geo' do
      specify { expect( Format::Zipcode.geo(nil) ).to eq({country_code: 'US'}) }
      specify { expect( Format::Zipcode.geo('ignored') ).to eq({country_code: 'US'}) }
    end

    describe '.is?' do
      it 'recognizes a valid format' do
        expect( Format::Zipcode.is?('90210-5555') ).to be true
      end

      it 'recognizes non-valid format' do
        expect( Format::Zipcode.is?('invalid') ).to be false
      end
    end
  end
end
