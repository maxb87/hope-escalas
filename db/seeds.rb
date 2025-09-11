# frozen_string_literal: true

# Seeds para ambiente de desenvolvimento
# - Admin (sem associação) com email admin@admin.com
# - 5 Professionals (técnicos de tênis) com Users associados
# - 5 Patients (tenistas famosos, incluindo Rafael Nadal) com Users associados
# Todos com senha 123456 e sem necessidade de reset de senha no primeiro login

require "active_record"
require "date"

SEED_PASSWORD = "123456"

def set_password_and_flags!(user, password)
  user.password = password
  user.password_confirmation = password
  if user.respond_to?(:force_password_reset)
    user.force_password_reset = false
  end
  user.save!
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
    { full_name: "Nick Bollettieri", email: "nick.bollettieri@hope.local", cpf: "10000000001", birthday: Date.new(1941, 7, 31), gender: "male" },
    { full_name: "Toni Nadal",        email: "toni.nadal@hope.local",        cpf: "10000000002", birthday: Date.new(1961, 2, 20), gender: "male" },
    { full_name: "Ivan Lendl",        email: "ivan.lendl@hope.local",        cpf: "10000000003", birthday: Date.new(1960, 3, 7), gender: "male" },
    { full_name: "Patrick Mouratoglou", email: "patrick.mouratoglou@hope.local", cpf: "10000000004", birthday: Date.new(1970, 6, 8), gender: "male" },
    { full_name: "Darren Cahill",     email: "darren.cahill@hope.local",     cpf: "10000000005", birthday: Date.new(1965, 10, 2), gender: "male" }
  ]

  coaches.each do |attrs|
    prof = Professional.find_or_initialize_by(cpf: attrs[:cpf])
    prof.full_name = attrs[:full_name]
    prof.email     = attrs[:email]
    prof.birthday  = attrs[:birthday]
    prof.gender    = attrs[:gender]
    prof.save!

    if prof.user
      prof.user.email = attrs[:email]
      set_password_and_flags!(prof.user, SEED_PASSWORD)
    else
      prof.create_user!(email: attrs[:email], password: SEED_PASSWORD, password_confirmation: SEED_PASSWORD, force_password_reset: false)
    end

    puts "  ✓ Professional ensured: #{prof.full_name} (#{prof.email})"
  end

  puts "Seeding: Patients (players)"
  players = [
    { full_name: "Rafael Nadal",     email: "rafael.nadal@hope.local",     cpf: "20000000001", birthday: Date.new(1986, 6, 3), gender: "male" },
    { full_name: "Roger Federer",    email: "roger.federer@hope.local",    cpf: "20000000002", birthday: Date.new(1981, 8, 8), gender: "male" },
    { full_name: "Novak Djokovic",   email: "novak.djokovic@hope.local",   cpf: "20000000003", birthday: Date.new(1987, 5, 22), gender: "male" },
    { full_name: "Serena Williams",  email: "serena.williams@hope.local",  cpf: "20000000004", birthday: Date.new(1981, 9, 26), gender: "female" },
    { full_name: "Andy Murray",      email: "andy.murray@hope.local",      cpf: "20000000005", birthday: Date.new(1987, 5, 15), gender: "male" }
  ]

  players.each do |attrs|
    pat = Patient.find_or_initialize_by(cpf: attrs[:cpf])
    pat.full_name = attrs[:full_name]
    pat.email     = attrs[:email]
    pat.birthday  = attrs[:birthday]
    pat.gender    = attrs[:gender]
    pat.save!

    if pat.user
      pat.user.email = attrs[:email]
      set_password_and_flags!(pat.user, SEED_PASSWORD)
    else
      pat.create_user!(email: attrs[:email], password: SEED_PASSWORD, password_confirmation: SEED_PASSWORD, force_password_reset: false)
    end

    puts "  ✓ Patient ensured: #{pat.full_name} (#{pat.email})"
  end

  # Create admin professional
  admin_professional = Professional.find_or_create_by!(email: "admin@admin.com") do |professional|
    professional.full_name = "Administrador"
    professional.cpf = "00000000000"
    professional.birthday = Date.new(1990, 1, 1)
    professional.gender = "male"
  end

  # Associate admin user with admin professional
  admin.update!(account: admin_professional) unless admin.account.present?

  puts "  ✓ Admin professional ensured: #{admin_professional.full_name} (#{admin_professional.email})"
end

puts "👥 Usuários criados:"
puts "   - Admin: admin@admin.com (senha: 123456)"
puts "   - Profissionais: nick.bollettieri@hope.local, toni.nadal@hope.local, ivan.lendl@hope.local, patrick.mouratoglou@hope.local, darren.cahill@hope.local (senha: 123456)"
puts "   - Pacientes: rafael.nadal@hope.local, roger.federer@hope.local, novak.djokovic@hope.local, serena.williams@hope.local, andy.murray@hope.local (senha: 123456)"
