class ImagesController < ApplicationController
  before_action :set_location, except: [:download]
  before_action :require_admin!, only: [:destroy]
  before_action :authenticate_user!, except: [:show, :index, :download]
  before_action :set_image, only: [:show, :edit, :update, :destroy]
  # GET /images
  # GET /images.json
  def index
    @reconstruction = Reconstruction.friendly.find(params[:reconstruction_slug]) if params[:reconstruction_slug]
    if params[:show] == "all"
      @images = @location.images.exclude_in_reconstruction(@reconstruction).paginate(page: params[:page])
      @all = true
    elsif params[:show] == "reconstruction"
      @images = @reconstruction.images.paginate(page: params[:page], per_page: 12)
    else
      @images = @location.images.unassigned_to_reconstruction.paginate(page: params[:page])
    end
    @image = @location.images.new
    respond_to do |format|
      format.html # index.html.erb
      format.json
    end
  end

  # GET /images/1
  # GET /images/1.json
  def show
    @previous = @image.previous
    @next = @image.next
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @image }
    end
  end

  # GET /images/new
  # GET /images/new.json
  def new
    @image = @location.image.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @image }
    end
  end

  # POST /images
  # POST /images.json
  def create
    if params[:flickr_url]
      @image = @location.images.new
      @image.image_remote_url = params[:flickr_url]
      @image.metadata = params[:flickr_metadata].to_json
      if params[:reconstruction_slug]
        @reconstruction = Reconstruction.friendly.find(params[:reconstruction_slug])
      end
    else
      @image = @location.images.build(image_params)
    end

    if @image.save
      @image.reconstructions << @reconstruction if @reconstruction
      # send success header
      render json: { message: 'success', photo: {square_url: @image.image.url(:square), id: @image.id} }, status: 200
    else
      #  you need to send an error header, otherwise Dropzone
      #  will not interpret the response as an error:
      render json: { error: @image.errors.full_messages.join(',') }, status: 400
    end
  end

  # PUT /images/1
  # PUT /images/1.json
  def update
    respond_to do |format|
      if @image.update_attributes(image_params)
        format.html do
          redirect_to [@location,@image], notice: 'Image was successfully updated.'
        end
        # format.json { head :no_content }
        format.json do
          render json: { files: [@image.to_jq_upload] },
                 status: :created, location: @image
        end
      else
        format.html { render action: 'edit' }
        format.json do
          render json: @image.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.json
  def destroy
    @image.destroy

    respond_to do |format|
      format.html { redirect_to images_url }
      format.json { head :no_content }
    end
  end

  private
  def set_location
    @location = Location.friendly.find(params[:location_id])
  end

  def set_image
    @image = @location.images.find(params[:id])
  end

  def image_params
    if params[:reconstruction_id]
      @reconstruction = Reconstruction.find(params[:reconstruction_id])
    end
    params.require(:image).permit(:image) unless params[:flickr_url].present?
  end
end
