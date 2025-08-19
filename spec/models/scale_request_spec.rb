require 'rails_helper'

RSpec.describe ScaleRequest, type: :model do
  let(:patient) { FactoryBot.create(:patient) }
  let(:professional) { FactoryBot.create(:professional) }
  let(:bdi_scale) { FactoryBot.create(:psychometric_scale, name: "Inventário de Depressão de Beck", code: "BDI") }

  describe 'validations' do
    context 'unique active request per patient and scale' do
      it 'allows creating a scale request when none exists' do
        scale_request = FactoryBot.build(:scale_request,
                             patient: patient,
                             professional: professional,
                             psychometric_scale: bdi_scale)

        expect(scale_request).to be_valid
      end

      it 'prevents creating duplicate pending requests for same patient and scale' do
        # Criar primeira solicitação pendente
        FactoryBot.create(:scale_request,
               patient: patient,
               professional: professional,
               psychometric_scale: bdi_scale,
               status: :pending)

        # Tentar criar segunda solicitação pendente para mesma escala e paciente
        duplicate_request = FactoryBot.build(:scale_request,
                                 patient: patient,
                                 professional: professional,
                                 psychometric_scale: bdi_scale,
                                 status: :pending)

        expect(duplicate_request).not_to be_valid
        expect(duplicate_request.errors[:base]).to include(
          "Já existe uma solicitação pendente da escala 'Inventário de Depressão de Beck' para #{patient.full_name}. Cancele a solicitação anterior ou aguarde sua conclusão antes de criar uma nova."
        )
      end

      it 'allows creating new request when previous is completed' do
        # Criar primeira solicitação completa
        FactoryBot.create(:scale_request,
               patient: patient,
               professional: professional,
               psychometric_scale: bdi_scale,
               status: :completed)

        # Criar segunda solicitação deve ser permitido
        new_request = FactoryBot.build(:scale_request,
                           patient: patient,
                           professional: professional,
                           psychometric_scale: bdi_scale,
                           status: :pending)

        expect(new_request).to be_valid
      end

      it 'allows creating new request when previous is cancelled' do
        # Criar primeira solicitação cancelada
        FactoryBot.create(:scale_request,
               patient: patient,
               professional: professional,
               psychometric_scale: bdi_scale,
               status: :cancelled)

        # Criar segunda solicitação deve ser permitido
        new_request = FactoryBot.build(:scale_request,
                           patient: patient,
                           professional: professional,
                           psychometric_scale: bdi_scale,
                           status: :pending)

        expect(new_request).to be_valid
      end

      it 'allows creating request for different scale for same patient' do
        bai_scale = FactoryBot.create(:psychometric_scale, name: "Inventário de Ansiedade de Beck", code: "BAI")

        # Criar solicitação para BDI
        FactoryBot.create(:scale_request,
               patient: patient,
               professional: professional,
               psychometric_scale: bdi_scale,
               status: :pending)

        # Criar solicitação para BAI deve ser permitido
        bai_request = FactoryBot.build(:scale_request,
                           patient: patient,
                           professional: professional,
                           psychometric_scale: bai_scale,
                           status: :pending)

        expect(bai_request).to be_valid
      end

      it 'allows creating request for same scale for different patient' do
        other_patient = FactoryBot.create(:patient)

        # Criar solicitação para primeiro paciente
        FactoryBot.create(:scale_request,
               patient: patient,
               professional: professional,
               psychometric_scale: bdi_scale,
               status: :pending)

        # Criar solicitação para segundo paciente deve ser permitido
        other_request = FactoryBot.build(:scale_request,
                             patient: other_patient,
                             professional: professional,
                             psychometric_scale: bdi_scale,
                             status: :pending)

        expect(other_request).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:pending_request) { FactoryBot.create(:scale_request, status: :pending) }
    let!(:completed_request) { FactoryBot.create(:scale_request, status: :completed) }
    let!(:cancelled_request) { FactoryBot.create(:scale_request, status: :cancelled) }

    it 'returns only pending requests with active scope' do
      expect(ScaleRequest.active).to include(pending_request)
      expect(ScaleRequest.active).not_to include(completed_request)
      expect(ScaleRequest.active).not_to include(cancelled_request)
    end
  end
end
