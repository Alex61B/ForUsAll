class Api::V1::BaseController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery with: :null_session
  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def authenticate_user!
    unless current_user
      render json: {
        errors: [ { title: "Unauthorized", detail: "You must be signed in." } ]
      }, status: :unauthorized
    end
  end

  def current_user
    warden.authenticate(scope: :user)
  end

  def user_not_authorized
    render json: {
      errors: [ { title: "Forbidden", detail: "You are not authorized." } ]
    }, status: :forbidden
  end

  def record_not_found
    render json: {
      errors: [ { title: "Not Found", detail: "The requested resource was not found." } ]
    }, status: :not_found
  end

  def jsonapi_content_type
    response.set_header("Content-Type", "application/vnd.api+json")
  end

  def render_jsonapi(serializer_class, resource, options = {})
    jsonapi_content_type
    render json: serializer_class.new(resource, options).serializable_hash,
           status: options.fetch(:status, :ok)
  end

  def render_jsonapi_errors(resource, status: :unprocessable_entity)
    jsonapi_content_type
    errors = resource.errors.map do |error|
      { title: error.attribute.to_s.humanize, detail: error.full_message, source: { pointer: "/data/attributes/#{error.attribute}" } }
    end
    render json: { errors: errors }, status: status
  end
end
