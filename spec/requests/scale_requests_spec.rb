require 'rails_helper'

RSpec.describe "ScaleRequests", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/scale_requests/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/scale_requests/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/scale_requests/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/scale_requests/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/scale_requests/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
