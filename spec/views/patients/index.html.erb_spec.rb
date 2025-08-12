require 'rails_helper'

RSpec.describe "patients/index", type: :view do
  before(:each) do
    assign(:patients, [
      Patient.create!(
        full_name: "Full Name",
        sex: 2,
        email: "Email",
        cpf: "Cpf",
        rg: "Rg",
        current_address: 3,
        current_phone: 4
      ),
      Patient.create!(
        full_name: "Full Name",
        sex: 2,
        email: "Email",
        cpf: "Cpf",
        rg: "Rg",
        current_address: 3,
        current_phone: 4
      )
    ])
  end

  it "renders a list of patients" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Full Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Cpf".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Rg".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
