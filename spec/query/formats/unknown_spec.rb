require_relative '../../spec_helper'

module Barometer::Query
  RSpec.describe Format::Unknown do
    describe '.is?' do
      it 'returns true' do
        expect( Format::Unknown.is?('New York, NY') ).to be true
      end
    end
  end
end
