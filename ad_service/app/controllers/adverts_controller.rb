class AdvertsController < ApplicationController
  before_action :user

  def index; end

  def show
    @advert = Advert.find(params[:id])
    authorize @advert
  end

  def new
    @advert = @user.adverts.build
    authorize Advert
  end

  def edit
    @advert = Advert.find(params[:id])
    @statuses = statuses_for_select
    authorize @advert
  end

  def create
    @advert = @user.adverts.new(advert_params)
    respond_to do |format|
      if @advert.save
        create_images

        format.html { redirect_to @user, notice: 'Advert was succesfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    @advert = Advert.find(params[:id])
    prev_status = @advert.status
    if @advert.update(advert_params) && @advert.valid?
      @advert.refresh! if prev_status == advert_params[:status]
      redirect_to [@user, @advert]
    else
      @statuses = statuses_for_select
      render action: 'edit'
    end
  end

  private

  def user
    @user = User.find(params[:user_id])
  end

  def create_images
    return if params[:images].nil?
    params[:images]['body'].each do |a|
      @advert.images.create!(body: a)
    end
  end

  def statuses_for_select
    statuses = @advert.aasm.states(permitted: true).map(&:name)
    statuses -= [:published, :canceled] unless @user.admin?
    statuses -= [:recent]
    statuses << @advert.status
    statuses
  end

  def advert_params
    params.require(:advert).permit(
      :title,
      :body,
      :price,
      :status,
      :category,
      image_attributes: [:id, :body, :advert_id]
    )
  end
end
