namespace :test_data do
  desc "Importa pacientes de arquivo CSV para o banco de testes"
  task import_patients: :environment do
    require "csv"

    # Verificar se estamos no ambiente de teste
    unless Rails.env.test?
      puts "⚠️  AVISO: Esta task deve ser executada apenas no ambiente de teste!"
      puts "Execute com: RAILS_ENV=test rake test_data:import_patients"
      exit 1
    end

    # Caminho do arquivo CSV
    csv_file = ENV["CSV_FILE"] || "test/fixtures/patients_test_data.csv"

    unless File.exist?(csv_file)
      puts "❌ Arquivo CSV não encontrado: #{csv_file}"
      puts "Crie o arquivo ou especifique o caminho com: CSV_FILE=caminho/do/arquivo.csv"
      exit 1
    end

    puts "📁 Importando pacientes de: #{csv_file}"
    puts "🗄️  Ambiente: #{Rails.env}"
    puts "─" * 50

    imported_count = 0
    error_count = 0

    # Desabilitar validações para importação mais rápida (opcional)
    Patient.skip_callback(:create, :after, :create_user)

    CSV.foreach(csv_file, headers: true) do |row|
      begin
        patient_data = {
          full_name: row["full_name"] || row["nome_completo"],
          email: row["email"],
          cpf: row["cpf"],
          birthday: row["birthday"] || row["data_nascimento"],
          phone: row["phone"] || row["telefone"]
        }

        # Remover campos vazios
        patient_data.compact!

        # Verificar se paciente já existe
        patient = Patient.find_or_initialize_by(
          cpf: patient_data[:cpf]
        )

        if patient.new_record?
          patient.assign_attributes(patient_data)
          if patient.save
            imported_count += 1
            print "✅"
          else
            error_count += 1
            puts "\n❌ Erro ao importar #{patient_data[:full_name]}: #{patient.errors.full_messages.join(', ')}"
          end
        else
          print "⏭️"
        end

      rescue => e
        error_count += 1
        puts "\n💥 Erro na linha #{$.}: #{e.message}"
      end
    end

    # Reabilitar callbacks
    Patient.set_callback(:create, :after, :create_user)

    puts "\n─" * 50
    puts "📊 Relatório de Importação:"
    puts "✅ Importados: #{imported_count}"
    puts "❌ Erros: #{error_count}"
    puts "📈 Total processado: #{imported_count + error_count}"
  end

  desc "Remove todos os pacientes de teste (mantém apenas os do seed principal)"
  task clean_test_patients: :environment do
    unless Rails.env.test?
      puts "⚠️  AVISO: Esta task deve ser executada apenas no ambiente de teste!"
      exit 1
    end

    # Contar antes da remoção
    total_before = Patient.count

    # Remover apenas pacientes que não têm user associado ou são de teste
    # Ajuste esta lógica conforme necessário
    Patient.where("email LIKE ?", "%test%").destroy_all

    total_after = Patient.count

    puts "🧹 Limpeza concluída:"
    puts "📊 Removidos: #{total_before - total_after}"
    puts "📈 Restantes: #{total_after}"
  end
end
