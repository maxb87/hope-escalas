require 'rails_helper'

RSpec.describe "PsychometricScales", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/psychometric_scales/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/psychometric_scales/show"
      expect(response).to have_http_status(:success)
    end
  end

end
