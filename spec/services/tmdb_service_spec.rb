require 'rails_helper'

RSpec.describe TmdbService, type: :service do
    let(:api_key) { "api_key" }

    before do
        allow(ENV).to receive(:[]).with("TMDB_API_READ_ACCESS_TOKEN").and_return(api_key)
    end

    describe "#initialize" do
        it "raises error if the API token is missing" do
            allow(ENV).to receive(:[]).with("TMDB_API_READ_ACCESS_TOKEN").and_return(nil)
            expect { TmdbService.new }.to raise_error(TmdbService::AuthenticationError, "TMDB API token not found")
        end

        it "initializes with the API token" do
            service = TmdbService.new
            expect(service.instance_variable_get(:@api_token)).to eq(api_key)
        end
    end

    describe "#tmdb_request" do
        BASE_URL_V3 = "https://api.themoviedb.org/3"
        url = URI("#{BASE_URL_V3}/resource_path")

        it "makes a GET request to the TMDB API and parses the JSON response" do
            http_double = instance_double(Net::HTTP)
            request_double = instance_double(Net::HTTP::Get)

            allow(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(http_double)
            allow(http_double).to receive(:use_ssl=).and_return(true)
            allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
            allow(request_double).to receive(:[]=).with("accept", "application/json")
            allow(request_double).to receive(:[]=).with("Authorization", "Bearer " + api_key)

            response_double = instance_double(Net::HTTPResponse, body: '{"id":123,"title":"Titanic"}')
            allow(http_double).to receive(:request).with(request_double).and_return(response_double)

            service = described_class.new
            result = service.send(:tmdb_request, "movie/550")

            expect(result).to eq({ "id" => 123, "title" => "Titanic" })
        end

        it "raises JSON Parse error if the response in not in correct format" do
            http_double = instance_double(Net::HTTP)
            request_double = instance_double(Net::HTTP::Get)

            allow(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(http_double)
            allow(http_double).to receive(:use_ssl=).and_return(true)
            allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
            allow(request_double).to receive(:[]=)

            response_double = instance_double(Net::HTTPResponse, body: "Invalid JSON")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "invalid") }.to raise_error(JSON::ParserError)
        end
    end

  # context "3rd party API calls" do
  # search_by_name
  # search_by_id
  # discover
  # genre
  # lists
  # trending
  # credits
  # images
  # images
  # external_ids
  # recommendations
  # watch_providers
  # videos
  # end
end
