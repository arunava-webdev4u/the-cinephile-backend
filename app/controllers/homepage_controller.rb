class HomepageController < ApplicationController
  def index
    render json: { message: "Welcome to The Cinephile API" }
  end
end
