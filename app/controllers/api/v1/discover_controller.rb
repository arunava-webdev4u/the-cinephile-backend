# app/controllers/api/v1/discover_controller.rb
class Api::V1::DiscoverController < Api::V1::BaseController
  before_action :initialize_tmdb_service

  def trending
    result = @tmdb_service.trending(discover_params[:type], discover_params[:time_window])
    render json: result, status: :ok
  end

  def popular
    result = @tmdb_service.popular(discover_params[:type])
    render json: result, status: :ok
  end

  def available_today
    result = @tmdb_service.available_today(discover_params[:type])
    render json: result, status: :ok
  end

  def upcoming
    result = @tmdb_service.upcoming(discover_params[:type])
    render json: result, status: :ok
  end

  private

  def discover_params
    params.permit(:time_window, :type, :format)
  end

  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end
end