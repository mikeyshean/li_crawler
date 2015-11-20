class UsersController < ApplicationController

  def create
    user = User.new(email: params[:user][:email])
    existing_user = User.find_by(email: user.email)

    if existing_user
      user = existing_user
    else
      user.save
    end

    if user.scrape_second_connections(params[:user][:password])
      redirect_to user_url(user)
    else
      render json: "Fail"
    end
  end

  def show
    @user = User.where(id: params[:id]).first
    if @user
      @contacts = @user.first_degree_contacts
      render :show
    else
      render json: "Fail"
    end
  end
end
