require 'rails_helper'

RSpec.describe "patients/show", type: :view do
  before(:each) do
    assign(:patient, Patient.create!(
      full_name: "Full Name",
             gender: "male",
       email: "Email",
      cpf: "Cpf",
      rg: "Rg",
      current_address: 3,
      current_phone: 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Full Name/)
    expect(rendered).to match(/Masculino/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Cpf/)
    expect(rendered).to match(/Rg/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
  end
end
