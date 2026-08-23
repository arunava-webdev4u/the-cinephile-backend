class Api::V1::BaseController < Api::V1::ApplicationController
    before_action :set_default_format

    private
    def set_default_format
        request.format = :json if request.format.html?
    end
end
