# Script para criar a escala PSA - Perfil Sensorial do Adulto/Adolescente

# Criar a escala PSA se não existir
psa_scale = PsychometricScale.find_or_create_by(code: 'PSA') do |scale|
  scale.name = 'PSA - Perfil Sensorial do Adulto/Adolescente'
  scale.description = 'Perfil Sensorial do Adulto/Adolescente - Avaliação de processamento sensorial em 6 categorias'
  scale.version = '1.0'
  scale.is_active = true
end

puts "Escala PSA criada/encontrada:"
puts "  - #{psa_scale.code}: #{psa_scale.name}"

# Lista completa de 60 itens PSA organizados por categorias
psa_items = [
  # Item A: Processamento Tátil/Olfativo (itens 1-8)
  {
    item_number: 1,
    question_text: "Saio ou mudo para outra parte da loja (ex.: produtos para banho, velas, perfumes).",
    category: "A"
  },
  {
    item_number: 2,
    question_text: "Acrescento temperos na minha comida.",
    category: "A"
  },
  {
    item_number: 3,
    question_text: "Não sinto cheiros que outras pessoas sentem.",
    category: "A"
  },
  {
    item_number: 4,
    question_text: "Gosto de estar próxima a pessoas usando perfume.",
    category: "A"
  },
  {
    item_number: 5,
    question_text: "Só como comidas familiares.",
    category: "A"
  },
  {
    item_number: 6,
    question_text: "Muitas comidas parecem sem sabor para mim (em outras palavras, parece sem graça ou não tem muito sabor).",
    category: "A"
  },
  {
    item_number: 7,
    question_text: "Não gosto de balas de sabor muito forte (ex.: canela forte ou azedas).",
    category: "A"
  },
  {
    item_number: 8,
    question_text: "Vou cheirar flores frescas quando as vejo.",
    category: "A"
  },

  # Item B: Processamento Vestibular/Proprioceptivo (itens 9-16)
  {
    item_number: 9,
    question_text: "Tenho medo de alturas.",
    category: "B"
  },
  {
    item_number: 10,
    question_text: "Gosta da sensação de movimento (dançar, correr, por exemplo).",
    category: "B"
  },
  {
    item_number: 11,
    question_text: "Evito elevadores e escadas rolantes porque não gosto de movimento.",
    category: "B"
  },
  {
    item_number: 12,
    question_text: "Tropeço nas coisas.",
    category: "B"
  },
  {
    item_number: 13,
    question_text: "Não gosto do movimento de andar de carro.",
    category: "B"
  },
  {
    item_number: 14,
    question_text: "Escolho me envolver em atividades físicas.",
    category: "B"
  },
  {
    item_number: 15,
    question_text: "Não me sinto muito seguro quando descendo ou subindo escadas (ex.: tropeço, perco o equilíbrio, seguro no corrimão).",
    category: "B"
  },
  {
    item_number: 16,
    question_text: "Fico tonto facilmente (por ex.: após me curvar ou levantar muito rapidamente).",
    category: "B"
  },

  # Item C: Processamento Visual (itens 17-26)
  {
    item_number: 17,
    question_text: "Gosto de ir a lugares com iluminação brilhante e que são coloridos.",
    category: "C"
  },
  {
    item_number: 18,
    question_text: "Mantenho as persianas fechadas durante o dia.",
    category: "C"
  },
  {
    item_number: 19,
    question_text: "Gosto de usar roupa muito colorida.",
    category: "C"
  },
  {
    item_number: 20,
    question_text: "Fico frustrado quando tento encontrar alguma coisa em uma gaveta cheia ou sala bagunçada.",
    category: "C"
  },
  {
    item_number: 21,
    question_text: "Não vejo a rua, prédio ou placas de salas quando tento ir a um lugar novo.",
    category: "C"
  },
  {
    item_number: 22,
    question_text: "Imagens visuais que se movem rapidamente no cinema ou TV me incomodam.",
    category: "C"
  },
  {
    item_number: 23,
    question_text: "Não noto quando pessoas entram na sala.",
    category: "C"
  },
  {
    item_number: 24,
    question_text: "Escolho fazer compras em lojas menores porque me desoriento em lojas grandes.",
    category: "C"
  },
  {
    item_number: 25,
    question_text: "Me incomoda quando há muito movimento ao meu redor (ex.: shopping cheio, desfile, parquinho).",
    category: "C"
  },
  {
    item_number: 26,
    question_text: "Limito as distrações enquanto trabalho (por ex.: fecho a porta ou desligo a TV).",
    category: "C"
  },

  # Item D: Processamento Tátil (itens 27-39)
  {
    item_number: 27,
    question_text: "Não gosto que me esfreguem as costas.",
    category: "D"
  },
  {
    item_number: 28,
    question_text: "Gosto da sensação quando corto o cabelo.",
    category: "D"
  },
  {
    item_number: 29,
    question_text: "Evito ou uso luvas em atividades que vão sujar as minhas mãos.",
    category: "D"
  },
  {
    item_number: 30,
    question_text: "Toco outros enquanto falo (ex.: ponho minha mão em seus ombros ou sacudo suas mãos).",
    category: "D"
  },
  {
    item_number: 31,
    question_text: "Me incomoda o modo como sinto minha boca quando acordo.",
    category: "D"
  },
  {
    item_number: 32,
    question_text: "Gosto de andar descalço.",
    category: "D"
  },
  {
    item_number: 33,
    question_text: "Me sinto mal usando alguns tecidos (ex.: lã, seda, veludo cotelê, etiquetas em roupas).",
    category: "D"
  },
  {
    item_number: 34,
    question_text: "Não gosto de certas texturas de alimento (ex.: pêssegos com casca, purê de maçã, queijo cottage, pasta de amendoim crocante).",
    category: "D"
  },
  {
    item_number: 35,
    question_text: "Me afasto quando chegam muito perto de mim.",
    category: "D"
  },
  {
    item_number: 36,
    question_text: "Não pareço notar quando meu rosto e mãos estão sujos.",
    category: "D"
  },
  {
    item_number: 37,
    question_text: "Me arranho ou tenho marcas roxas mas não me lembro como fiz.",
    category: "D"
  },
  {
    item_number: 38,
    question_text: "Evito ficar em filas ou ficar próximo a outras pessoas porque não gosto de ficar próximo demais dos outros.",
    category: "D"
  },
  {
    item_number: 39,
    question_text: "Não pareço notar quando alguém toca meu braço ou costas.",
    category: "D"
  },

  # Item E: Nível de Atividade (itens 40-49)
  {
    item_number: 40,
    question_text: "Trabalho em duas ou mais tarefas ao mesmo tempo.",
    category: "E"
  },
  {
    item_number: 41,
    question_text: "Levo mais tempo que outras pessoas para acordar de manhã.",
    category: "E"
  },
  {
    item_number: 42,
    question_text: "Faço as coisas de improviso (em outras palavras, faço coisas sem planejar antes).",
    category: "E"
  },
  {
    item_number: 43,
    question_text: "Acho tempo para me afastar da minha vida ocupada e passar tempo sozinho.",
    category: "E"
  },
  {
    item_number: 44,
    question_text: "Pareço mais lenta que outros quando tento seguir uma atividade ou tarefa.",
    category: "E"
  },
  {
    item_number: 45,
    question_text: "Não pego piadas tão rapidamente quanto outros.",
    category: "E"
  },
  {
    item_number: 46,
    question_text: "Me afasto de multidões.",
    category: "E"
  },
  {
    item_number: 47,
    question_text: "Acho atividades para fazer em frente a outros (ex.: música, esportes, falar em público e responder perguntas em aula).",
    category: "E"
  },
  {
    item_number: 48,
    question_text: "Acho difícil me concentrar por todo o tempo em uma aula ou reunião longos.",
    category: "E"
  },
  {
    item_number: 49,
    question_text: "Evito situações em que possam acontecer coisas inesperadas (ex.: ir a lugares não familiares ou estar perto de pessoas que não conheço).",
    category: "E"
  },

  # Item F: Processamento Auditivo (itens 50-60)
  {
    item_number: 50,
    question_text: "Cantarolo, assobio, canto ou faço outros barulhos.",
    category: "F"
  },
  {
    item_number: 51,
    question_text: "Me assusto facilmente com sons altos ou inesperados (ex.: aspirador de pó, cachorro latindo, telefone tocando).",
    category: "F"
  },
  {
    item_number: 52,
    question_text: "Tenho dificuldade em seguir o que as pessoas estão falando quando falam rapidamente ou sobre assuntos não familiares.",
    category: "F"
  },
  {
    item_number: 53,
    question_text: "Saio da sala quando outros assistem TV ou peço a eles que desliguem.",
    category: "F"
  },
  {
    item_number: 54,
    question_text: "Me distraio se há muito barulho em volta.",
    category: "F"
  },
  {
    item_number: 55,
    question_text: "Não noto quando meu nome é chamado.",
    category: "F"
  },
  {
    item_number: 56,
    question_text: "Uso estratégias para abafar sons (ex.: fecho a porta, cubro os ouvidos, uso protetores de ouvido).",
    category: "F"
  },
  {
    item_number: 57,
    question_text: "Fico longe de ambientes barulhentos.",
    category: "F"
  },
  {
    item_number: 58,
    question_text: "Gosto de ir a lugares com muita música.",
    category: "F"
  },
  {
    item_number: 59,
    question_text: "Tenho de pedir a pessoas que repitam coisas.",
    category: "F"
  },
  {
    item_number: 60,
    question_text: "Acho difícil trabalhar com barulho de fundo (ex.: ventilador, rádio).",
    category: "F"
  }
]

# Opções de resposta para PSA (escala Likert de 5 pontos)
options = {
  '1' => 'Quase nunca',
  '2' => 'Raramente',
  '3' => 'Ocasionalmente',
  '4' => 'Frequentemente',
  '5' => 'Quase sempre'
}

# Mapeamento de categorias para nomes
category_names = {
  'A' => 'Processamento Tátil/Olfativo',
  'B' => 'Processamento Vestibular/Proprioceptivo',
  'C' => 'Processamento Visual',
  'D' => 'Processamento Tátil',
  'E' => 'Nível de Atividade',
  'F' => 'Processamento Auditivo'
}

# Criar itens para PSA
puts "Criando #{psa_items.count} itens para: #{psa_scale.name}"
psa_items.each do |item_data|
  item = PsychometricScaleItem.find_or_create_by!(
    psychometric_scale: psa_scale,
    item_number: item_data[:item_number]
  ) do |scale_item|
    scale_item.question_text = item_data[:question_text]
    scale_item.options = options
    scale_item.is_required = true
  end

  # Adicionar metadados da categoria no campo extra
  item.update!(extra: {
    category: item_data[:category],
    category_name: category_names[item_data[:category]]
  })
end

puts "✅ Todos os 60 itens PSA criados com sucesso!"
puts ""
puts "Categorias criadas:"
category_names.each do |code, name|
  count = psa_items.count { |item| item[:category] == code }
  puts "  - Item #{code}: #{name} (#{count} questões)"
end
