require 'rails_helper'

RSpec.describe Professional, type: :model do
  describe 'Paranoia soft delete' do
    let!(:professional) { create(:professional) }

    it 'soft-deletes by setting deleted_at and hiding from default scope' do
      expect { professional.destroy }.to change { Professional.count }.by(-1)
      expect(professional.deleted_at).to be_present
      expect(Professional.only_deleted.find(professional.id)).to be_present
      expect { Professional.find(professional.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'restores a soft-deleted record' do
      professional.destroy
      expect(Professional.only_deleted.find(professional.id)).to be_present

      expect { professional.restore }.to change { Professional.count }.by(1)
      expect(professional.deleted_at).to be_nil
      expect(Professional.find(professional.id)).to be_present
    end

    it 'destroys dependent user on soft-delete' do
      user = create(:user, account: professional)
      expect { professional.destroy }.to change { User.exists?(user.id) }.from(true).to(false)
    end
  end
end
