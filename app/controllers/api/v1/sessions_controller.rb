class Api::V1::SessionsController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.find_by(email: params.dig(:user, :email)&.downcase)
    if user&.valid_password?(params.dig(:user, :password))
      sign_in(user)
      jsonapi_content_type
      render json: {
        data: {
          type: "users",
          id: user.id.to_s,
          attributes: {
            email: user.email,
            full_name: user.full_name,
            role: user.role
          }
        },
        meta: { message: "Signed in successfully." }
      }, status: :ok
    else
      jsonapi_content_type
      render json: {
        errors: [ { title: "Unauthorized", detail: "Invalid email or password." } ]
      }, status: :unauthorized
    end
  end

  def destroy
    sign_out(current_user)
    jsonapi_content_type
    render json: { meta: { message: "Signed out successfully." } }, status: :ok
  end
end
