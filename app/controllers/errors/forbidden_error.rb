class Errors::ForbiddenError < Errors::ApplicationError
  def initialize(message = "Forbidden")
    super(message, status: 403)
  end
end
