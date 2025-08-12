class ProfessionalsController < ApplicationController
  before_action :set_professional, only: %i[ show edit update destroy ]

  # GET /professionals or /professionals.json
  def index
    @professionals = Professional.all
  end

  # GET /professionals/1 or /professionals/1.json
  def show
  end

  # GET /professionals/new
  def new
    @professional = Professional.new
  end

  # GET /professionals/1/edit
  def edit
  end

  # POST /professionals or /professionals.json
  def create
    @professional = Professional.new(professional_params)

    ActiveRecord::Base.transaction do
      if @professional.save
        generated_password = SecureRandom.alphanumeric(6)
        @professional.create_user!(
          email: @professional.email,
          password: generated_password,
          password_confirmation: generated_password,
          force_password_reset: true
        )

        notice_message = I18n.t("professionals.notices.created")
        if Rails.env.development?
          notice_message = "#{notice_message} #{I18n.t('professionals.notices.dev_password', password: generated_password)}"
        end

        respond_to do |format|
          format.html { redirect_to @professional, notice: notice_message }
          format.json { render :show, status: :created, location: @professional }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @professional.errors, status: :unprocessable_entity }
        end
        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /professionals/1 or /professionals/1.json
  def update
    respond_to do |format|
      if @professional.update(professional_params)
        format.html { redirect_to @professional, notice: I18n.t("professionals.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @professional }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @professional.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /professionals/1 or /professionals/1.json
  def destroy
    @professional.destroy!

    respond_to do |format|
      format.html { redirect_to professionals_path, notice: I18n.t("professionals.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_professional
      @professional = Professional.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def professional_params
      params.expect(professional: [ :full_name, :sex, :birthday, :started_at, :email, :cpf, :rg, :current_address, :current_phone, :professional_id ])
    end
end
