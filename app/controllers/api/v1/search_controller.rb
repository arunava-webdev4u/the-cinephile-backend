class Api::V1::SearchController < Api::V1::BaseController
  before_action :initialize_tmdb_service
  before_action :validate_search_params, only: [ :name, :id ]

  rescue_from TmdbService::TmdbError, with: :handle_tmdb_error

  def name
    results = @tmdb_service.search_by_name(search_params[:query], search_params[:type])

    render json: results, status: :ok
  end

  def id
    result = @tmdb_service.search_by_id(search_params[:tmdb_id], search_params[:type])

    render json: result, status: :ok
  end

  def multi
    result =  @tmdb_service.multi_search(search_params[:query])

    render json: result, status: :ok
  end

  private
  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end

  def handle_tmdb_error(exception)
    Rails.logger.error "TMDB API error: #{exception.message}"
    render json: { error: "External service unavailable", details: exception.message },
           status: :service_unavailable
  end

  def search_params
    params.permit(:query, :tmdb_id, :type, :format)
  end

  def validate_search_params
    unless params[:type].present?
      render json: {
        success: false,
        error: "Type parameter is required",
        valid_types: TmdbService::VALID_SEARCH_TYPES
      }, status: :bad_request
      return
    end

    if params[:query].blank? && params[:tmdb_id].blank?
      render json: {
        success: false,
        error: "Either query or tmdb_id parameter is not present"
      }, status: :bad_request
      nil
    end
  end
end
