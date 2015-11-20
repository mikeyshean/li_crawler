class UsersController < ApplicationController

  def create
    user = User.new(email: params[:user][:email])
    existing_user = User.find_by(email: user.email)

    if existing_user
      user = existing_user
    else
      user.save
    end

    if user.generate_connections(params[:user][:password])
      render :show
    else
      render json: "Fail"
      # render json: @user.errors.full_messages, status: 422
    end
  end

  def show
    render json: "Success"
  end
end
