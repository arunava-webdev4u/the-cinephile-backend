class Errors::NotFoundError < Errors::ApplicationError
  def initialize(message = "Resource not found")
    super(message, status: 404)
  end
end
