class HomepageController < ApplicationController
  def index
    @version = ActiveRecord::Base.connection.execute("SELECT version();").first['version']
    p @version
    render json: { message: "Welcome to The Cinephile API. PG version: #{@version}" }
  end
end
