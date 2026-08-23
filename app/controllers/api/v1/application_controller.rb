# app/controllers/api/v1/application_controller.rb
class Api::V1::ApplicationController < ActionController::API
    include ExceptionHandler
    include Authenticable
end
