# frozen_string_literal: true

puts "🌱 Iniciando seeding da aplicação Hope Escalas..."

# Lista de arquivos de seed em ordem de execução
seed_files = [
  'seeds/01_users.rb',              # Usuários básicos (admin, profissionais, pacientes)
  'seeds/10_srs2_complete.rb'      # Escala SRS-2 completa
  # 'seeds/11_beck_inventory.rb',   # Inventário de Beck (futuro)
  # 'seeds/12_other_scale.rb',      # Outras escalas (futuro)
  # 'seeds/99_sample_data.rb'       # Dados de exemplo (futuro)
]

# Executar cada arquivo de seed
seed_files.each do |seed_file|
  seed_path = Rails.root.join('db', seed_file)

  if File.exist?(seed_path)
    puts "\n📁 Carregando: #{seed_file}"
    begin
      load seed_path
      puts "   ✅ #{seed_file} carregado com sucesso!"
    rescue => e
      puts "   ❌ Erro ao carregar #{seed_file}: #{e.message}"
      raise e  # Re-raise para parar o seeding em caso de erro
    end
  else
    puts "   ⚠️  Arquivo não encontrado: #{seed_file} (pulando...)"
  end
end

puts "\n🎉 Seeding completo! Aplicação pronta para uso."
puts "\n📋 Credenciais de acesso:"
puts "   🔑 Admin: admin@admin.com (senha: 123456)"
puts "   👨‍⚕️ Profissionais: *.bollettieri@hope.local, *.nadal@hope.local, etc. (senha: 123456)"
puts "   🏃‍♂️ Pacientes: *.nadal@hope.local, *.federer@hope.local, etc. (senha: 123456)"
