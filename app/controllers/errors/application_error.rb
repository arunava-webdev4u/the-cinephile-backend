class Errors::ApplicationError < StandardError
    attr_reader :status

    def initialize(message = nil, status: 500)
        super(message)      # Normal Ruby exception message
        @status = status    # But we ALSO remember the HTTP status (500, 400, 404, etc.)
    end
end
