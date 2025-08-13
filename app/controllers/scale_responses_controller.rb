class ScaleResponsesController < ApplicationController
  before_action :set_scale_response, only: [ :show ]

  def new
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    @scale_response = ScaleResponse.new
    @scale_response.scale_request = @scale_request
    @scale_response.patient = current_user.account
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    @scale_items = @scale_request.psychometric_scale.scale_items.ordered
    authorize @scale_response
  end

  def create
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    @scale_response = ScaleResponse.new(scale_response_params)
    @scale_response.scale_request = @scale_request
    @scale_response.patient = current_user.account
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    authorize @scale_response

    if @scale_response.save
      @scale_request.complete!
      redirect_to @scale_response, notice: "Escala preenchida com sucesso."
    else
      @scale_items = @scale_request.psychometric_scale.scale_items.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @scale_response
  end

  private

  def set_scale_response
    @scale_response = ScaleResponse.find(params[:id])
  end

  def scale_response_params
    # Permitir respostas para todos os itens (item_1, item_2, etc.)
    permitted_params = params.require(:scale_response).permit(:answers)

    # Converter answers para o formato esperado se necessário
    if permitted_params[:answers].present?
      answers = {}
      permitted_params[:answers].each do |key, value|
        if key.match?(/\Aitem_\d+\z/) && value.present?
          answers[key] = value.to_i
        end
      end
      permitted_params[:answers] = answers
    end

    permitted_params
  end
end
