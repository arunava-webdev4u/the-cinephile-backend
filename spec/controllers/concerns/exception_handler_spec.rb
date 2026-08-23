require "rails_helper"

RSpec.describe ExceptionHandler, type: :controller do
  # Anonymous controller that includes the concern (via ApplicationController).
  # Each example tells it which error to raise via the @error_class/@error_message
  # instance variables set in a before block.
  controller(Api::V1::ApplicationController) do
    skip_before_action :authenticate_user!

    def index
      instance_exec(&@error_class) if @error_class

      render json: { message: "success" }
    end
  end

  before do
    path = controller.controller_path
    routes.draw { get "index" => "#{path}#index" }
  end

  # Helper: configure the anonymous controller to raise `klass` on GET index.
  # Accepts either a class (+message+) or a pre-built exception instance.
  def stub_error(klass_or_exception, message = "boom")
    exception =
      if klass_or_exception.is_a?(Exception)
        klass_or_exception
      else
        klass_or_exception.new(message)
      end

    controller.instance_variable_set(:@error_class, -> { raise exception })
    controller.instance_variable_set(:@error_message, message)
  end

  shared_examples "a problem+json response" do |status:, title:, detail_includes: nil, detail_eq: nil|
    it "returns HTTP #{status}" do
      get :index
      expect(response).to have_http_status(status)
    end

    it "sets content_type to application/problem+json" do
      get :index
      expect(response.media_type).to eq("application/problem+json")
    end

    it "renders RFC 9457 fields" do
      get :index
      body = JSON.parse(response.body)

      expect(body["type"]).to eq("about:blank")
      expect(body["title"]).to eq(title)
      expect(body["status"]).to eq(status)
      expect(body["instance"]).to be_present
      expect(body).to have_key("detail")
    end

    if detail_eq
      it "renders detail #{detail_eq.inspect}" do
        get :index
        expect(JSON.parse(response.body)["detail"]).to eq(detail_eq)
      end
    elsif detail_includes
      it "includes #{detail_includes.inspect} in detail" do
        get :index
        expect(JSON.parse(response.body)["detail"]).to include(detail_includes)
      end
    end
  end

  describe "StandardError (catch-all)" do
    before { stub_error(StandardError, "PG::ConnectionBad could not connect") }

    include_examples "a problem+json response",
      status: 500,
      title: "Internal Server Error",
      detail_eq: "PG::ConnectionBad could not connect" # test env is 'local'
  end

  describe "Errors::ApplicationError subclasses" do
    context "with Errors::BadRequestError" do
      before { stub_error(Errors::BadRequestError, "Invalid input") }

      include_examples "a problem+json response",
        status: 400,
        title: "Bad Request",
        detail_eq: "Invalid input"
    end

    context "with Errors::UnauthorizedError" do
      before { stub_error(Errors::UnauthorizedError, "Authentication failed") }

      include_examples "a problem+json response",
        status: 401,
        title: "Unauthorized",
        detail_eq: "Authentication failed"
    end

    context "with Errors::NotFoundError" do
      before { stub_error(Errors::NotFoundError, "Resource not found") }

      include_examples "a problem+json response",
        status: 404,
        title: "Not Found",
        detail_eq: "Resource not found"
    end

    context "with Errors::ForbiddenError" do
      before { stub_error(Errors::ForbiddenError, "Not allowed") }

      include_examples "a problem+json response",
        status: 403,
        title: "Forbidden",
        detail_eq: "Not allowed"
    end
  end

  describe "TmdbService errors" do
    context "with TmdbService::ClientError" do
      before { stub_error(TmdbService::ClientError, "Invalid type 'album'") }

      include_examples "a problem+json response",
        status: 400,
        title: "Bad Request",
        detail_eq: "Invalid type 'album'"
    end

    context "with TmdbService::NotFoundError" do
      before { stub_error(TmdbService::NotFoundError, "No results") }

      include_examples "a problem+json response",
        status: 404,
        title: "Not Found",
        detail_eq: "No results"
    end

    context "with TmdbService::RateLimitError" do
      before { stub_error(TmdbService::RateLimitError, "Rate limit exceeded") }

      include_examples "a problem+json response",
        status: 429,
        title: "Too Many Requests",
        detail_eq: "Rate limit exceeded"
    end

    context "with TmdbService::ServerError" do
      before { stub_error(TmdbService::ServerError, "TMDB server error") }

      include_examples "a problem+json response",
        status: 503,
        title: "Service Unavailable",
        detail_includes: "External service unavailable"
    end

    context "with base TmdbService::TmdbError" do
      before { stub_error(TmdbService::TmdbError, "Network timeout") }

      include_examples "a problem+json response",
        status: 503,
        title: "Service Unavailable",
        detail_includes: "External service unavailable"
    end
  end

  describe "Framework errors" do
    context "with ActionController::ParameterMissing" do
      before { stub_error(ActionController::ParameterMissing.new(:user)) }

      include_examples "a problem+json response",
        status: 400,
        title: "Bad Request",
        detail_eq: "Missing required parameter: user"
    end

    context "with ActiveRecord::RecordNotFound" do
      before { stub_error(ActiveRecord::RecordNotFound, "Couldn't find User with 'id'=999") }

      include_examples "a problem+json response",
        status: 404,
        title: "Not Found",
        detail_eq: "Couldn't find User with 'id'=999"
    end

    context "with ActiveRecord::RecordInvalid" do
      let(:user) { create(:user) }
      let(:invalid_user) { build(:user, email: user.email) }

      before do
        invalid_user.valid? # populate errors
        stub_error(ActiveRecord::RecordInvalid, invalid_user)
      end

      include_examples "a problem+json response",
        status: 422,
        title: "Validation Failed"

      it "includes field-level errors as extensions" do
        get :index
        body = JSON.parse(response.body)

        expect(body["errors"]).to have_key("email")
      end
    end
  end

  describe "handler precedence (registration order)" do
    # ClientError < TmdbError; the specific handler must win over the base one.
    it "routes ClientError to 400, not the TmdbError 503 handler" do
      stub_error(TmdbService::ClientError, "bad type")

      get :index

      expect(response).to have_http_status(:bad_request)
    end

    # ApplicationError must not fall through to the StandardError catch-all.
    it "routes BadRequestError to 400, not the StandardError 500 handler" do
      stub_error(Errors::BadRequestError, "nope")

      get :index

      expect(response).to have_http_status(:bad_request)
    end

    # RecordNotFound must not hit the StandardError catch-all.
    it "routes RecordNotFound to 404, not the StandardError 500 handler" do
      stub_error(ActiveRecord::RecordNotFound, "gone")

      get :index

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "ErrorSanitizer integration" do
    it "masks unsafe messages even from safe errors" do
      stub_error(Errors::BadRequestError, "auth failed with token=supersecret")

      get :index

      expect(JSON.parse(response.body)["detail"]).to eq(ErrorSanitizer::GENERIC_DETAIL)
    end
  end
end
