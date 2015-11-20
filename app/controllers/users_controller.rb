class UsersController < ApplicationController

  def create
    user = User.new(email: params[:user][:email])
    existing_user = User.find_by(email: user.email)

    if existing_user && params[:scrape] == "true"
      existing_user.scrape_first_connections(params[:user][:password])
      existing_user.scrape_second_connections(params[:user][:password])
      redirect_to user_url(existing_user)
    elsif existing_user && params[:scrape] == "false"
      redirect_to user_url(existing_user)
    else
      user.save
      user.scrape_first_connections(params[:user][:password])
      user.scrape_second_connections(params[:user][:password])
      redirect_to user_url(user)
    end
  end

  def show
    @user = User.where(id: params[:id]).first
    if @user
      render :show
    else
      render json: "Fail"
    end
  end

  def first
    @user = User.where(id: params[:id]).first
    if @user
      @contacts = @user.first_degree_contacts
      render :first
    else
      render json: "Fail"
    end
  end

  def second
    @user = User.where(id: params[:id]).first
    if @user
      @contacts = @user.second_degree_contacts
      render :second
    else
      render json: "Fail"
    end
  end
end
