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

    if pat.user
      pat.user.email = attrs[:email]
      set_password_and_flags!(pat.user, SEED_PASSWORD)
    else
      pat.create_user!(email: attrs[:email], password: SEED_PASSWORD, password_confirmation: SEED_PASSWORD, force_password_reset: false)
    end

    puts "  ✓ Patient ensured: #{pat.full_name} (#{pat.email})"
  end
end

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# Create admin professional
admin_professional = Professional.find_or_create_by!(email: "admin@admin.com") do |professional|
  professional.full_name = "Administrador"
  professional.cpf = "00000000000"
  professional.birthday = Date.new(1990, 1, 1)
  professional.sex = 0
end

# Associate admin user with admin professional
admin_user.update!(account: admin_professional) unless admin_user.account.present?

# Create sample professionals
sample_professionals = [
  {
    full_name: "Dr. João Silva",
    email: "joao.silva@hope.local",
    cpf: "11111111111",
    birthday: Date.new(1985, 5, 15),
    sex: 0
  },
  {
    full_name: "Dra. Maria Santos",
    email: "maria.santos@hope.local",
    cpf: "22222222222",
    birthday: Date.new(1988, 8, 22),
    sex: 1
  }
]

sample_professionals.each do |professional_data|
  professional = Professional.find_or_create_by!(email: professional_data[:email]) do |p|
    p.full_name = professional_data[:full_name]
    p.cpf = professional_data[:cpf]
    p.birthday = professional_data[:birthday]
    p.sex = professional_data[:sex]
  end

  # Create user for professional
  user = User.find_or_create_by!(email: professional_data[:email]) do |u|
    u.password = "123456"
    u.password_confirmation = "123456"
    u.force_password_reset = true
  end

  user.update!(account: professional) unless user.account.present?
end

# Create sample patients
sample_patients = [
  {
    full_name: "Ana Oliveira",
    email: "ana.oliveira@hope.local",
    cpf: "33333333333",
    birthday: Date.new(1992, 3, 10),
    sex: 1
  },
  {
    full_name: "Carlos Ferreira",
    email: "carlos.ferreira@hope.local",
    cpf: "44444444444",
    birthday: Date.new(1987, 12, 5),
    sex: 0
  },
  {
    full_name: "Lucia Costa",
    email: "lucia.costa@hope.local",
    cpf: "55555555555",
    birthday: Date.new(1995, 7, 18),
    sex: 1
  }
]

sample_patients.each do |patient_data|
  patient = Patient.find_or_create_by!(email: patient_data[:email]) do |p|
    p.full_name = patient_data[:full_name]
    p.cpf = patient_data[:cpf]
    p.birthday = patient_data[:birthday]
    p.sex = patient_data[:sex]
  end

  # Create user for patient
  user = User.find_or_create_by!(email: patient_data[:email]) do |u|
    u.password = "123456"
    u.password_confirmation = "123456"
    u.force_password_reset = true
  end

  user.update!(account: patient) unless user.account.present?
end

# Create BDI (Beck Depression Inventory) scale
bdi_scale = PsychometricScale.find_or_create_by!(code: "BDI") do |scale|
  scale.name = "Inventário de Depressão de Beck"
  scale.description = "Escala de 21 itens para avaliar sintomas de depressão"
  scale.version = "1.0"
  scale.is_active = true
end

# BDI items
bdi_items = [
  {
    item_number: 1,
    question_text: "Tristeza",
    options: {
      "0" => "Não me sinto triste",
      "1" => "Sinto-me triste",
      "2" => "Estou sempre triste e não consigo sair disso",
      "3" => "Estou tão triste ou infeliz que não posso suportar"
    }
  },
  {
    item_number: 2,
    question_text: "Pessimismo",
    options: {
      "0" => "Não estou desencorajado quanto ao meu futuro",
      "1" => "Sinto-me mais desencorajado quanto ao meu futuro do que costumava estar",
      "2" => "Não espero que as coisas funcionem para mim",
      "3" => "Sinto que não há esperança no futuro e que as coisas não podem melhorar"
    }
  },
  {
    item_number: 3,
    question_text: "Falha",
    options: {
      "0" => "Não me sinto como um falhado",
      "1" => "Sinto que falhei mais do que a maioria das pessoas",
      "2" => "Quando olho para a minha vida, vejo muitas falhas",
      "3" => "Sinto-me como uma pessoa completamente falhada"
    }
  },
  {
    item_number: 4,
    question_text: "Perda de prazer",
    options: {
      "0" => "Tenho tanto prazer nas coisas como antes",
      "1" => "Não tenho tanto prazer nas coisas como antes",
      "2" => "Já não tenho muito prazer nas coisas",
      "3" => "Não tenho prazer em nada"
    }
  },
  {
    item_number: 5,
    question_text: "Sentimentos de culpa",
    options: {
      "0" => "Não me sinto particularmente culpado",
      "1" => "Sinto-me culpado por muitas coisas que fiz ou que deveria ter feito",
      "2" => "Sinto-me culpado pela maior parte do tempo",
      "3" => "Sinto-me sempre culpado"
    }
  },
  {
    item_number: 6,
    question_text: "Sentimentos de punição",
    options: {
      "0" => "Não sinto que estou sendo punido",
      "1" => "Sinto que posso estar sendo punido",
      "2" => "Espero ser punido",
      "3" => "Sinto que estou sendo punido"
    }
  },
  {
    item_number: 7,
    question_text: "Insatisfação consigo mesmo",
    options: {
      "0" => "Não me sinto desapontado comigo mesmo",
      "1" => "Estou desapontado comigo mesmo",
      "2" => "Estou enojado comigo mesmo",
      "3" => "Odeio-me"
    }
  },
  {
    item_number: 8,
    question_text: "Auto-crítica",
    options: {
      "0" => "Não me sinto pior do que qualquer outra pessoa",
      "1" => "Sou crítico de mim mesmo por fraquezas ou erros",
      "2" => "Sempre me culpo pelos meus problemas",
      "3" => "Sempre me culpo por tudo de mal que acontece"
    }
  },
  {
    item_number: 9,
    question_text: "Pensamentos suicidas",
    options: {
      "0" => "Não tenho pensamentos de me matar",
      "1" => "Tenho pensamentos de me matar, mas não os executaria",
      "2" => "Gostaria de me matar",
      "3" => "Matar-me-ia se tivesse oportunidade"
    }
  },
  {
    item_number: 10,
    question_text: "Choro",
    options: {
      "0" => "Não choro mais do que costumava",
      "1" => "Choro mais agora do que costumava",
      "2" => "Choro agora por qualquer coisa",
      "3" => "Gostaria de chorar, mas não consigo"
    }
  },
  {
    item_number: 11,
    question_text: "Irritabilidade",
    options: {
      "0" => "Não estou mais irritado do que costumava estar",
      "1" => "Fico irritado mais facilmente do que costumava",
      "2" => "Agora fico irritado por qualquer coisa",
      "3" => "Gostaria de ficar irritado, mas não consigo"
    }
  },
  {
    item_number: 12,
    question_text: "Perda de interesse",
    options: {
      "0" => "Não perdi o interesse por outras pessoas",
      "1" => "Estou menos interessado por outras pessoas do que costumava estar",
      "2" => "Perdi a maior parte do meu interesse por outras pessoas",
      "3" => "Não tenho interesse por outras pessoas"
    }
  },
  {
    item_number: 13,
    question_text: "Indecisão",
    options: {
      "0" => "Tomar decisões não é mais difícil do que costumava ser",
      "1" => "Adio tomar decisões mais do que costumava",
      "2" => "Tenho dificuldade em tomar decisões",
      "3" => "Não consigo tomar decisões"
    }
  },
  {
    item_number: 14,
    question_text: "Desvalorização",
    options: {
      "0" => "Não me sinto diferente do que costumava",
      "1" => "Não me sinto tão atraente como costumava",
      "2" => "Estou preocupado com o facto de parecer feio ou pouco atraente",
      "3" => "Sinto que sou feio"
    }
  },
  {
    item_number: 15,
    question_text: "Perda de energia",
    options: {
      "0" => "Posso trabalhar tão bem como antes",
      "1" => "Não consigo trabalhar tão bem como antes",
      "2" => "Tenho de me esforçar muito para fazer qualquer coisa",
      "3" => "Não consigo fazer qualquer trabalho"
    }
  },
  {
    item_number: 16,
    question_text: "Mudanças no padrão de sono",
    options: {
      "0" => "Posso dormir tão bem como costumava",
      "1" => "Não durmo tão bem como costumava",
      "2" => "Acordo 1-2 horas mais cedo do que costumava e tenho dificuldade em voltar a dormir",
      "3" => "Acordo muito mais cedo do que costumava e não consigo voltar a dormir"
    }
  },
  {
    item_number: 17,
    question_text: "Fadiga",
    options: {
      "0" => "Não me sinto mais cansado do que costumava",
      "1" => "Canso-me mais facilmente do que costumava",
      "2" => "Canso-me com qualquer coisa que faço",
      "3" => "Estou demasiado cansado para fazer qualquer coisa"
    }
  },
  {
    item_number: 18,
    question_text: "Mudanças no apetite",
    options: {
      "0" => "O meu apetite não é pior do que costumava ser",
      "1" => "O meu apetite não é tão bom como costumava ser",
      "2" => "O meu apetite é muito pior agora",
      "3" => "Não tenho apetite de todo"
    }
  },
  {
    item_number: 19,
    question_text: "Perda de peso",
    options: {
      "0" => "Não perdi muito peso, se é que perdi algum",
      "1" => "Perdi mais de 2 kg",
      "2" => "Perdi mais de 5 kg",
      "3" => "Perdi mais de 7 kg"
    }
  },
  {
    item_number: 20,
    question_text: "Preocupação com a saúde",
    options: {
      "0" => "Não estou mais preocupado com a minha saúde do que costumava estar",
      "1" => "Estou preocupado com problemas físicos como dores, perturbações estomacais ou constipações",
      "2" => "Estou muito preocupado com problemas físicos e é difícil pensar noutra coisa",
      "3" => "Estou tão preocupado com os meus problemas físicos que não consigo pensar noutra coisa"
    }
  },
  {
    item_number: 21,
    question_text: "Perda de interesse sexual",
    options: {
      "0" => "Não notei qualquer mudança recente no meu interesse por sexo",
      "1" => "Estou menos interessado por sexo do que costumava estar",
      "2" => "Estou muito menos interessado por sexo agora",
      "3" => "Perdi completamente o interesse por sexo"
    }
  }
]

# Create BDI items
bdi_items.each do |item_data|
  PsychometricScaleItem.find_or_create_by!(
    psychometric_scale: bdi_scale,
    item_number: item_data[:item_number]
  ) do |item|
    item.question_text = item_data[:question_text]
    item.options = item_data[:options]
    item.is_required = true
  end
end

puts "✅ Seeds criados com sucesso!"
puts "👥 Usuários criados:"
puts "   - Admin: admin@admin.com (senha: admin123)"
puts "   - Profissionais: joao.silva@hope.local, maria.santos@hope.local (senha: 123456)"
puts "   - Pacientes: ana.oliveira@hope.local, carlos.ferreira@hope.local, lucia.costa@hope.local (senha: 123456)"
puts "📊 Escala BDI criada com 21 itens"
