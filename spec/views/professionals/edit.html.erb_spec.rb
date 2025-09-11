require 'rails_helper'

RSpec.describe "professionals/edit", type: :view do
  let(:professional) {
    Professional.create!(
      full_name: "MyString",
             gender: "male",
       email: "MyString",
      cpf: "MyString",
      rg: "MyString",
      current_address: 1,
      current_phone: 1,
      professional_id: "MyString"
    )
  }

  before(:each) do
    assign(:professional, professional)
  end

  it "renders the edit professional form" do
    render

    assert_select "form[action=?][method=?]", professional_path(professional), "post" do
      assert_select "input[name=?]", "professional[full_name]"

      assert_select "select[name=?]", "professional[gender]"


      assert_select "input[name=?]", "professional[email]"

      assert_select "input[name=?]", "professional[cpf]"

      assert_select "input[name=?]", "professional[rg]"

      assert_select "input[name=?]", "professional[current_address]"

      assert_select "input[name=?]", "professional[current_phone]"

      assert_select "input[name=?]", "professional[professional_id]"
    end
  end
end
