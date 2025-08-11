require 'rails_helper'

RSpec.describe "patients/new", type: :view do
  before(:each) do
    assign(:patient, Patient.new(
      full_name: "MyString",
      sex: 1,
      birthplace: "MyString",
      email: "MyString",
      cpf: "MyString",
      rg: "MyString",
      current_address: 1,
      current_phone: 1
    ))
  end

  it "renders new patient form" do
    render

    assert_select "form[action=?][method=?]", patients_path, "post" do

      assert_select "input[name=?]", "patient[full_name]"

      assert_select "input[name=?]", "patient[sex]"

      assert_select "input[name=?]", "patient[birthplace]"

      assert_select "input[name=?]", "patient[email]"

      assert_select "input[name=?]", "patient[cpf]"

      assert_select "input[name=?]", "patient[rg]"

      assert_select "input[name=?]", "patient[current_address]"

      assert_select "input[name=?]", "patient[current_phone]"
    end
  end
end
