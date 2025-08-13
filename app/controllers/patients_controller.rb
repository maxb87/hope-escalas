class PatientsController < ApplicationController
  before_action :set_patient, only: %i[ show edit update destroy ]
  before_action :set_patient_with_deleted, only: %i[ restore ]

  # GET /patients or /patients.json
  def index
    @patients = policy_scope(Patient)
  end

  # GET /patients/1 or /patients/1.json
  def show
    authorize @patient
  end

  # GET /patients/new
  def new
    @patient = Patient.new
    authorize @patient
  end

  # GET /patients/1/edit
  def edit
    authorize @patient
  end

  # POST /patients or /patients.json
  def create
    @patient = Patient.new(patient_params)
    authorize @patient

    ActiveRecord::Base.transaction do
      if @patient.save
        # generated_password = SecureRandom.alphanumeric(6)
        generated_password = @patient.cpf.to_s.first(6) # MVP: will implement a better password generation later
        @patient.create_user!(
          email: @patient.email,
          password: generated_password,
          password_confirmation: generated_password,
          # force_password_reset: true
          force_password_reset: false # MVP: will implement forced password reset later
        )

        notice_message = I18n.t("patients.notices.created")
        if Rails.env.development?
          notice_message = "#{notice_message} #{I18n.t('patients.notices.dev_password', password: generated_password)}"
        end

        respond_to do |format|
          format.html { redirect_to @patient, notice: notice_message }
          format.json { render :show, status: :created, location: @patient }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @patient.errors, status: :unprocessable_entity }
        end
        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /patients/1 or /patients/1.json
  def update
    authorize @patient
    respond_to do |format|
      if @patient.update(patient_params)
        format.html { redirect_to @patient, notice: I18n.t("patients.notices.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @patient }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patients/1 or /patients/1.json
  def destroy
    authorize @patient
    @patient.destroy!

    respond_to do |format|
      format.html { redirect_to patients_path, notice: I18n.t("patients.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  # PATCH /patients/:id/restore
  def restore
    authorize @patient, :update?
    @patient.restore
    respond_to do |format|
      format.html { redirect_to @patient, notice: "Paciente restaurado com sucesso.", status: :see_other }
      format.json { render :show, status: :ok, location: @patient }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_patient
      @patient = Patient.find(params.expect(:id))
    end

    def set_patient_with_deleted
      @patient = Patient.with_deleted.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def patient_params
      params.expect(patient: [ :full_name, :sex, :birthday, :started_at, :email, :cpf, :rg, :current_address, :current_phone ])
    end
end
