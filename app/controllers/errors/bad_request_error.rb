class Errors::BadRequestError < Errors::ApplicationError
    def initialize(message = "Bad Request")
        super(message, status: 400)
    end
end
