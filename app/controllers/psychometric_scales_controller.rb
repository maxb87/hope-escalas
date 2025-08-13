class PsychometricScalesController < ApplicationController
  before_action :set_psychometric_scale, only: [ :show ]

  def index
    @psychometric_scales = policy_scope(PsychometricScale).active.ordered
    flash.now[:notice] = I18n.t("psychometric_scales.index.notice") if params[:n]
  end

  def show
    authorize @psychometric_scale
  end

  private

  def set_psychometric_scale
    @psychometric_scale = PsychometricScale.find(params[:id])
  end
end
