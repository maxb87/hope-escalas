require 'rails_helper'

RSpec.describe "professionals/new", type: :view do
  before(:each) do
    assign(:professional, Professional.new(
      full_name: "MyString",
      sex: 1,
      birthplace: "MyString",
      email: "MyString",
      cpf: "MyString",
      rg: "MyString",
      current_address: 1,
      current_phone: 1,
      professional_id: "MyString"
    ))
  end

  it "renders new professional form" do
    render

    assert_select "form[action=?][method=?]", professionals_path, "post" do

      assert_select "input[name=?]", "professional[full_name]"

      assert_select "input[name=?]", "professional[sex]"

      assert_select "input[name=?]", "professional[birthplace]"

      assert_select "input[name=?]", "professional[email]"

      assert_select "input[name=?]", "professional[cpf]"

      assert_select "input[name=?]", "professional[rg]"

      assert_select "input[name=?]", "professional[current_address]"

      assert_select "input[name=?]", "professional[current_phone]"

      assert_select "input[name=?]", "professional[professional_id]"
    end
  end
end
