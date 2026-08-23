class Errors::UnauthorizedError < Errors::ApplicationError
  def initialize(message = "Unauthorized")
    super(message, status: 401)
  end
end
