module Authenticable
    extend ActiveSupport::Concern

    included do
        before_action :authenticate_user!
    end

    def authenticate_user!
        token = extract_token_from_header

        unless token
            render json: { error: "Authorization token is missing" }, status: :unauthorized
            return
        end

        decoded_token = Auth::JsonWebToken.decode(token)

        unless decoded_token
            render json: { error: "Invalid or expired token" }, status: :unauthorized
            return
        end

        @current_user = User.find_by(id: decoded_token[:user_id])

        if @current_user.nil? || @current_user.jti != decoded_token[:jti]
            render json: { error: "Invalid or expired token" }, status: :unauthorized
        end
    end

    private

    def extract_token_from_header
        header = request.headers["Authorization"]
        return nil unless header        # return invalid header

        # Expected format: "Bearer <token>"
        header.split(" ").last if header.start_with?("Bearer ")
    end
end
