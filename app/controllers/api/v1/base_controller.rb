class Api::V1::BaseController < Api::V1::ApplicationController
    def tmdb_service
        @tmdb_service ||= TmdbService.new
    end
end
