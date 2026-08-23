require "rails_helper"

RSpec.describe ErrorSanitizer do
  describe ".sanitize" do
    context "when the error is intentional (safe: true)" do
      it "returns the real message" do
        error = TmdbService::ClientError.new("Invalid type 'album'. Valid types: movie, tv, person")

        expect(described_class.sanitize(error, safe: true)).to eq(error.message)
      end

      it "still masks messages containing unsafe patterns" do
        error = Errors::BadRequestError.new("Failed with api_key=abc123")

        expect(described_class.sanitize(error, safe: true)).to eq(ErrorSanitizer::GENERIC_DETAIL)
      end
    end

    context "when the error is unexpected (safe: false)" do
      let(:error) { StandardError.new("PG::ConnectionBad: could not connect to server") }

      it "masks the message when the request is not local" do
        expect(described_class.sanitize(error, safe: false, local_request: false))
          .to eq("Internal server error")
      end

      it "shows the message for local requests" do
        expect(described_class.sanitize(error, safe: false, local_request: true))
          .to eq(error.message)
      end

      it "masks even for local requests when the message contains unsafe patterns" do
        error = StandardError.new("NoMethodError: undefined method for token=xyz")

        expect(described_class.sanitize(error, safe: false, local_request: true))
          .to eq("Internal server error")
      end
    end
  end
end
