# UC-02 Kelola Data Pengguna. Hanya Super Admin.
class UsersController < ApplicationController
  before_action :require_super_admin
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = User.order(:role, :name)
  end

  def new
    @user = User.new(role: :peserta)
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to users_path, notice: "Pengguna #{@user.name} berhasil ditambahkan."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    # Kata sandi hanya diganti bila kolomnya diisi.
    attributes = user_params
    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?

    if @user.update(attributes)
      redirect_to users_path, notice: "Data #{@user.name} berhasil diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "Akun yang sedang digunakan tidak dapat dihapus."
    else
      @user.destroy
      redirect_to users_path, notice: "Pengguna #{@user.name} berhasil dihapus."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :role, :password, :password_confirmation)
  end
end
