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
            allow(http_double).to receive(:open_timeout=)   # add this
            allow(http_double).to receive(:read_timeout=)   # add this
            allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
            allow(request_double).to receive(:[]=).with("accept", "application/json")
            allow(request_double).to receive(:[]=).with("Authorization", "Bearer " + api_key)

            response_double = instance_double(Net::HTTPResponse, body: '{"id":123,"title":"Titanic"}', code: "200")
            allow(http_double).to receive(:request).with(request_double).and_return(response_double)

            service = described_class.new
            result = service.send(:tmdb_request, "movie/550")

            expect(result).to eq({ "id" => 123, "title" => "Titanic" })
        end

        it "raises JSON Parse error if the response is not in correct format" do
            http_double = instance_double(Net::HTTP)
            request_double = instance_double(Net::HTTP::Get)

            allow(Net::HTTP).to receive(:new).with(url.host, url.port).and_return(http_double)
            allow(http_double).to receive(:use_ssl=).and_return(true)
            allow(http_double).to receive(:open_timeout=)
            allow(http_double).to receive(:read_timeout=)
            allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
            allow(request_double).to receive(:[]=)

            response_double = instance_double(Net::HTTPResponse, body: "Invalid JSON", code: "200")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "invalid") }
                .to raise_error(TmdbService::TmdbError, /Invalid JSON response/)
        end
    end

    context "3rd party API calls" do
        let(:service) { described_class.new }

        describe "#search_by_name" do
            let(:query) { "Avatar" }
            let(:type) { "movie" }
            let(:expected_response) {  { 'results' => [ { 'id' => 603, 'title' => 'The Matrix' } ] } }

            before do
                allow(service).to receive(:tmdb_request).and_return(expected_response)
            end

            it 'calls tmdb_request with correct parameters' do
                service.search_by_name(query, type)
                expect(service).to have_received(:tmdb_request).with("search/#{type}?query=#{query}")
            end

            it 'returns the API response' do
                response = service.search_by_name(query, type)
                expect(response).to eq(expected_response)
            end

            context 'with different search types' do
                %w[movie tv person].each do |search_type|
                    it "works with #{search_type} type" do
                        service.search_by_name(query, search_type)
                        expect(service).to have_received(:tmdb_request).with("search/#{search_type}?query=#{query}")
                    end
                end
            end

            context 'with special characters in query' do
                let(:query_with_spaces) { 'The Dark Knight' }
                let(:query_with_symbols) { 'Spider-Man: No Way Home' }

                it "handles queries with spaces" do
                    service.search_by_name(query_with_spaces, type)
                    expect(service).to have_received(:tmdb_request).with("search/#{type}?query=#{query_with_spaces}")
                end

                it "handles queries with special characters" do
                    service.search_by_name(query_with_symbols, type)
                    expect(service).to have_received(:tmdb_request).with("search/#{type}?query=#{query_with_symbols}")
                end

              # it "rejects queries with invalid characters" do
              # end
            end
        end

        describe "#search_by_id" do
            let(:id) { "Office" }
            let(:type) { "tv" }
            let(:expected_response) {  { 'results' => [ { 'id' => 1169, 'title' => 'The Office' } ] } }

            before do
                allow(service).to receive(:tmdb_request).and_return(expected_response)
            end

            it 'calls tmdb_request with correct parameters' do
                service.search_by_id(id, type)
                expect(service).to have_received(:tmdb_request).with("#{type}/#{id}")
            end

            it 'returns the API response' do
                response = service.search_by_id(id, type)
                expect(response).to eq(expected_response)
            end

            context 'with different search types' do
                %w[movie tv person].each do |search_type|
                    it "works with #{search_type} type" do
                        service.search_by_id(id, search_type)
                        expect(service).to have_received(:tmdb_request).with("#{search_type}/#{id}")
                    end
                end
            end

            context 'with types of id' do
                let(:numeric_id) { 550 }

                it "works with numeric id" do
                    service.search_by_id(numeric_id, type)
                    expect(service).to have_received(:tmdb_request).with("#{type}/#{numeric_id}")
                end

                it "works with string id" do
                    string_id = numeric_id.to_s
                    service.search_by_id(string_id, type)
                    expect(service).to have_received(:tmdb_request).with("#{type}/#{string_id}")
                end
            end
        end

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
    end

    describe "error handling" do
        let(:http_double) { instance_double(Net::HTTP) }
        let(:request_double) { instance_double(Net::HTTP::Get) }

        before do
            allow(Net::HTTP).to receive(:new).and_return(http_double)
            allow(http_double).to receive(:use_ssl=).and_return(true)
            allow(http_double).to receive(:open_timeout=)
            allow(http_double).to receive(:read_timeout=)
            allow(Net::HTTP::Get).to receive(:new).and_return(request_double)
            allow(request_double).to receive(:[]=)
        end

        it "raises AuthenticationError on 401 response" do
            response_double = double("response", code: "401", body: "Unauthorized")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "movie/550") }
            .to raise_error(TmdbService::AuthenticationError, /Invalid API key/)
        end

        it "raises NotFoundError on 404 response" do
            response_double = double("response", code: "404", body: "Not Found")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "movie/999") }
            .to raise_error(TmdbService::NotFoundError, /Resource not found/)
        end

        it "raises RateLimitError on 429 response" do
            response_double = double("response", code: "429", body: "Too Many Requests")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "search/movie?query=test") }
            .to raise_error(TmdbService::RateLimitError, /Rate limit exceeded/)
        end

        it "raises ServerError on 500 response" do
            response_double = double("response", code: "500", body: "Internal Server Error")
            allow(http_double).to receive(:request).and_return(response_double)

            service = described_class.new
            expect { service.send(:tmdb_request, "trending") }
            .to raise_error(TmdbService::ServerError, /TMDB server error/)
        end

        it "raises TmdbError on network timeout (OpenTimeout)" do
            allow(http_double).to receive(:request).and_raise(Net::OpenTimeout.new("execution expired"))

            service = described_class.new
            expect { service.send(:tmdb_request, "movie/550") }
            .to raise_error(TmdbService::TmdbError, /Network timeout/)
        end

        it "raises TmdbError on network timeout (ReadTimeout)" do
            allow(http_double).to receive(:request).and_raise(Net::ReadTimeout.new("execution expired"))

            service = described_class.new
            expect { service.send(:tmdb_request, "movie/550") }
            .to raise_error(TmdbService::TmdbError, /Network timeout/)
        end

        it "raises TmdbError on socket error" do
            allow(http_double).to receive(:request).and_raise(Errno::ECONNREFUSED.new)

            service = described_class.new
            expect { service.send(:tmdb_request, "movie/550") }
            .to raise_error(TmdbService::TmdbError, /Network error/)
        end
    end
end
