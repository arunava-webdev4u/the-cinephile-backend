class Api::V1::SearchController < Api::V1::BaseController
  before_action :initialize_tmdb_service

  def name
    results = @tmdb_service.search_by_name(params[:query], params[:type])
    render json: results, status: :ok
  end

  def id
    result = @tmdb_service.search_by_id(params[:tmdb_id], params[:type])
    render json: result, status: :ok
  end

  def multi
    result = @tmdb_service.multi_search(params[:query])
    render json: result, status: :ok
  end

  private
  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end

  def search_params
    params.permit(:query, :tmdb_id, :type, :format)
  end
end
