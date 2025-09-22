namespace :fix do
  desc "Corrigir solicitações SRS-2 que têm respostas mas não foram marcadas como concluídas"
  task srs2_completion: :environment do
    puts "🔍 Verificando solicitações SRS-2 com respostas não concluídas..."

    # Encontrar solicitações SRS-2 pendentes que têm respostas
    srs2_requests = ScaleRequest.joins(:psychometric_scale, :scale_response)
      .where(psychometric_scales: { code: ['SRS2SR', 'SRS2HR'] })
      .where(status: :pending)

    puts "📊 Encontradas #{srs2_requests.count} solicitações SRS-2 pendentes com respostas:"

    srs2_requests.each do |request|
      response = request.scale_response
      puts "\n📋 Solicitação ID: #{request.id}"
      puts "   Paciente: #{request.patient.full_name}"
      puts "   Escala: #{request.psychometric_scale.name}"
      puts "   Status: #{request.status}"
      puts "   Resposta ID: #{response.id}"
      puts "   Pontuação: #{response.total_score}"
      puts "   Interpretação: #{response.interpretation}"
      puts "   Concluída em: #{response.completed_at}"
      
      # Verificar se a resposta é válida
      if response.valid?
        puts "   ✅ Resposta válida - marcando solicitação como concluída"
        request.complete!
        puts "   ✅ Solicitação marcada como concluída"
      else
        puts "   ❌ Resposta inválida:"
        response.errors.full_messages.each do |error|
          puts "      - #{error}"
        end
      end
    end

    puts "\n✅ Verificação concluída!"
  end
end
