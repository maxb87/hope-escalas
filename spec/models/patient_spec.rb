require 'rails_helper'

RSpec.describe Patient, type: :model do
  describe 'Paranoia soft delete' do
    let!(:patient) { create(:patient) }

    it 'soft-deletes by setting deleted_at and hiding from default scope' do
      expect { patient.destroy }.to change { Patient.count }.by(-1)
      expect(patient.deleted_at).to be_present
      expect(Patient.only_deleted.find(patient.id)).to be_present
      expect { Patient.find(patient.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'restores a soft-deleted record' do
      patient.destroy
      expect(Patient.only_deleted.find(patient.id)).to be_present

      expect { patient.restore }.to change { Patient.count }.by(1)
      expect(patient.deleted_at).to be_nil
      expect(Patient.find(patient.id)).to be_present
    end

    it 'destroys dependent user on soft-delete' do
      user = create(:user, account: patient)
      expect { patient.destroy }.to change { User.exists?(user.id) }.from(true).to(false)
    end
  end
end
