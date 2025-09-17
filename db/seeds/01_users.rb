# frozen_string_literal: true

puts "👤 Seeding: Usuários básicos..."

require "active_record"
require "date"

def set_password_and_flags!(user, password)
  user.password = password
  user.password_confirmation = password
  if user.respond_to?(:force_password_reset)
    user.force_password_reset = false
  end
  user.save!
end

def generate_password_from_cpf(cpf)
  # Extrair os primeiros 6 dígitos do CPF
  cpf.gsub(/\D/, '')[0, 6]
end

ActiveRecord::Base.transaction do
  puts "  🔧 Criando admin user..."
  admin_email = "admin@admin.com"
  admin = User.find_or_initialize_by(email: admin_email)
  admin.account = nil
  set_password_and_flags!(admin, "20G@^wD&jX9LnU")  # Admin mantém senha especial
  puts "     ✓ Admin user: #{admin.email} (senha: 20G@^wD&jX9LnU)"

  puts "  🔧 Criando profissionais..."
  professionals = [
    { full_name: "Francielly Maziero", email: "francielly.maziero@gmail.com", cpf: "84857560020", birthday: Date.new(1999, 8, 9), gender: "female" },
    { full_name: "Luis Souza Motta", email: "luismotta@hopeneuropsiquiatria.com.br", cpf: "00566791064", birthday: Date.new(1987, 8, 13), gender: "male" }
  ]

  professionals.each do |attrs|
    prof = Professional.find_or_initialize_by(cpf: attrs[:cpf])
    prof.full_name = attrs[:full_name]
    prof.email     = attrs[:email]
    prof.birthday  = attrs[:birthday]
    prof.gender    = attrs[:gender]
    prof.save!

    # Gerar senha baseada no CPF
    password = generate_password_from_cpf(attrs[:cpf])

    if prof.user
      prof.user.email = attrs[:email]
      set_password_and_flags!(prof.user, password)
    else
      prof.create_user!(
        email: attrs[:email],
        password: password,
        password_confirmation: password,
        force_password_reset: false
      )
    end

    puts "     ✓ Professional: #{prof.full_name} (senha: #{password})"
  end

  puts "  🔧 Criando pacientes..."
  patients = [
    { full_name: "Pac1 Teste", email: "pac1.teste@hope.local", cpf: "20000100001", birthday: Date.new(1986, 6, 3), gender: "male" },
    { full_name: "Pac2 Teste", email: "pac2.teste@hope.local", cpf: "20000200002", birthday: Date.new(1981, 8, 8), gender: "male" },
    { full_name: "Pac3 Teste", email: "pac3.teste@hope.local", cpf: "20000300003", birthday: Date.new(1987, 5, 22), gender: "male" }
  ]

  patients.each do |attrs|
    pat = Patient.find_or_initialize_by(cpf: attrs[:cpf])
    pat.full_name = attrs[:full_name]
    pat.email     = attrs[:email]
    pat.birthday  = attrs[:birthday]
    pat.gender    = attrs[:gender]
    pat.save!

    # Gerar senha baseada no CPF
    password = generate_password_from_cpf(attrs[:cpf])

    if pat.user
      pat.user.email = attrs[:email]
      set_password_and_flags!(pat.user, password)
    else
      pat.create_user!(
        email: attrs[:email],
        password: password,
        password_confirmation: password,
        force_password_reset: false
      )
    end

    puts "     ✓ Patient: #{pat.full_name} (senha: #{password})"
  end

  # Create admin professional
  admin_professional = Professional.find_or_create_by!(email: "admin@admin.com") do |professional|
    professional.full_name = "Administrador"
    professional.cpf = "00000000000"
    professional.birthday = Date.new(1987, 1, 1)
    professional.gender = "male"
  end

  # Associate admin user with admin professional
  admin.update!(account: admin_professional) unless admin.account.present?
  puts "     ✓ Admin professional: #{admin_professional.full_name}"
end

puts "  ✅ Usuários criados com sucesso!"
puts ""
puts "  📋 Credenciais de acesso:"
puts "     🔑 Admin: admin@admin.com (senha: 20G@^wD&jX9LnU)"
puts "     👨‍⚕️ Profissionais:"
puts "        - francielly.maziero@gmail.com (senha: 848575)"
puts "        - luismotta@hopeneuropsiquiatria.com.br (senha: 005667)"
puts "     🏃‍♂️ Pacientes:"
puts "        - pac1.teste@hope.local (senha: 200001)"
puts "        - pac2.teste@hope.local (senha: 200002)"
puts "        - pac3.teste@hope.local (senha: 200003)"
