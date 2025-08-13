# frozen_string_literal: true

# Seeds para ambiente de desenvolvimento
# - Admin (sem associação) com email admin@admin.com
# - 5 Professionals (técnicos de tênis) com Users associados
# - 5 Patients (tenistas famosos, incluindo Rafael Nadal) com Users associados
# MVP: Senha inicial = 6 primeiros dígitos do CPF (sem necessidade de reset)
# FUTURO: Voltar a usar senha aleatória + force_password_reset = true

require "active_record"
require "date"

# MVP: Senha padrão para admin (não tem CPF)
SEED_PASSWORD = "123456"

def set_password_and_flags!(user, password)
  user.password = password
  user.password_confirmation = password

  # MVP: Sempre false - senha inicial é CPF
  # FUTURO: Voltar a usar force_password_reset = true para senhas aleatórias
  if user.respond_to?(:force_password_reset)
    user.force_password_reset = false
  end
  user.save!
end

def generate_initial_password(cpf)
  # MVP: 6 primeiros dígitos do CPF
  # FUTURO: Voltar a usar SecureRandom.alphanumeric(6)
  cpf.to_s[0..5]
end

ActiveRecord::Base.transaction do
  puts "Seeding: Admin user"
  admin_email = "admin@admin.com"
  admin = User.find_or_initialize_by(email: admin_email)
  admin.account = nil
  set_password_and_flags!(admin, SEED_PASSWORD)
  puts "  ✓ Admin user ensured: #{admin.email}"

  puts "Seeding: Professionals (coaches)"
  coaches = [
    { full_name: "Nick Bollettieri", email: "nick.bollettieri@hope.local", cpf: "10000000001", birthday: Date.new(1941, 7, 31) },
    { full_name: "Toni Nadal",        email: "toni.nadal@hope.local",        cpf: "10000000002", birthday: Date.new(1961, 2, 20) },
    { full_name: "Ivan Lendl",        email: "ivan.lendl@hope.local",        cpf: "10000000003", birthday: Date.new(1960, 3, 7) },
    { full_name: "Patrick Mouratoglou", email: "patrick.mouratoglou@hope.local", cpf: "10000000004", birthday: Date.new(1970, 6, 8) },
    { full_name: "Darren Cahill",     email: "darren.cahill@hope.local",     cpf: "10000000005", birthday: Date.new(1965, 10, 2) }
  ]

  coaches.each do |attrs|
    prof = Professional.find_or_initialize_by(cpf: attrs[:cpf])
    prof.full_name = attrs[:full_name]
    prof.email     = attrs[:email]
    prof.birthday  = attrs[:birthday]
    prof.save!

    # MVP: Senha = 6 primeiros dígitos do CPF
    initial_password = generate_initial_password(attrs[:cpf])

    if prof.user
      prof.user.email = attrs[:email]
      set_password_and_flags!(prof.user, initial_password)
    else
      prof.create_user!(email: attrs[:email], password: initial_password, password_confirmation: initial_password, force_password_reset: false)
    end

    puts "  ✓ Professional ensured: #{prof.full_name} (#{prof.email}) - Senha: #{initial_password}"
  end

  puts "Seeding: Patients (players)"
  players = [
    { full_name: "Rafael Nadal",     email: "rafael.nadal@hope.local",     cpf: "20000000001", birthday: Date.new(1986, 6, 3) },
    { full_name: "Roger Federer",    email: "roger.federer@hope.local",    cpf: "20000000002", birthday: Date.new(1981, 8, 8) },
    { full_name: "Novak Djokovic",   email: "novak.djokovic@hope.local",   cpf: "20000000003", birthday: Date.new(1987, 5, 22) },
    { full_name: "Serena Williams",  email: "serena.williams@hope.local",  cpf: "20000000004", birthday: Date.new(1981, 9, 26) },
    { full_name: "Andy Murray",      email: "andy.murray@hope.local",      cpf: "20000000005", birthday: Date.new(1987, 5, 15) }
  ]

  players.each do |attrs|
    pat = Patient.find_or_initialize_by(cpf: attrs[:cpf])
    pat.full_name = attrs[:full_name]
    pat.email     = attrs[:email]
    pat.birthday  = attrs[:birthday]
    pat.save!

    # MVP: Senha = 6 primeiros dígitos do CPF
    initial_password = generate_initial_password(attrs[:cpf])

    if pat.user
      pat.user.email = attrs[:email]
      set_password_and_flags!(pat.user, initial_password)
    else
      pat.create_user!(email: attrs[:email], password: initial_password, password_confirmation: initial_password, force_password_reset: false)
    end

    puts "  ✓ Patient ensured: #{pat.full_name} (#{pat.email}) - Senha: #{initial_password}"
  end
end

puts "Seeds concluídos."
