require 'rails_helper'

RSpec.describe "professionals/index", type: :view do
  before(:each) do
    assign(:professionals, [
      Professional.create!(
        full_name: "Full Name",
        sex: 2,
        birthplace: "Birthplace",
        email: "Email",
        cpf: "Cpf",
        rg: "Rg",
        current_address: 3,
        current_phone: 4,
        professional_id: "Professional"
      ),
      Professional.create!(
        full_name: "Full Name",
        sex: 2,
        birthplace: "Birthplace",
        email: "Email",
        cpf: "Cpf",
        rg: "Rg",
        current_address: 3,
        current_phone: 4,
        professional_id: "Professional"
      )
    ])
  end

  it "renders a list of professionals" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Full Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Birthplace".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Cpf".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Rg".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Professional".to_s), count: 2
  end
end
