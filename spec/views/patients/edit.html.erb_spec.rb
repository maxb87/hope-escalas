require 'rails_helper'

RSpec.describe "patients/edit", type: :view do
  let(:patient) {
    Patient.create!(
      full_name: "MyString",
             sex: 1,
       email: "MyString",
      cpf: "MyString",
      rg: "MyString",
      current_address: 1,
      current_phone: 1
    )
  }

  before(:each) do
    assign(:patient, patient)
  end

  it "renders the edit patient form" do
    render

    assert_select "form[action=?][method=?]", patient_path(patient), "post" do
      assert_select "input[name=?]", "patient[full_name]"

      assert_select "input[name=?]", "patient[sex]"


      assert_select "input[name=?]", "patient[email]"

      assert_select "input[name=?]", "patient[cpf]"

      assert_select "input[name=?]", "patient[rg]"

      assert_select "input[name=?]", "patient[current_address]"

      assert_select "input[name=?]", "patient[current_phone]"
    end
  end
end
