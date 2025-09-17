# Script para criar todos os 65 itens SRS-2

# Buscar as escalas
# Criar as escalas SRS-2 se não existirem
srs2_self = PsychometricScale.find_or_create_by(code: 'SRS2SR') do |scale|
  scale.name = 'SRS-2 Autorrelato'
  scale.description = 'Escala de Responsividade Social - Segunda Edição (Autorrelato)'
  scale.version = '2.0'
  scale.is_active = true
end

srs2_hetero = PsychometricScale.find_or_create_by(code: 'SRS2HR') do |scale|
  scale.name = 'SRS-2 Heterorrelato'
  scale.description = 'Escala de Responsividade Social - Segunda Edição (Heterorrelato)'
  scale.version = '2.0'
  scale.is_active = true
end

puts "Escalas SRS-2 criadas/encontradas:"
puts "  - #{srs2_self.code}: #{srs2_self.name}"
puts "  - #{srs2_hetero.code}: #{srs2_hetero.name}"

# Lista completa de 65 itens SRS-2 Heterorelato
srs2_hetero_items = [
  { item_number: 1, question_text: "Parece muito mais desconfortável em situações sociais do que quando está sozinha" },
  { item_number: 2, question_text: "As expressões em seu rosto não combinam com o que está dizendo" },
  { item_number: 3, question_text: "Parece confiante (ou segura) quando está interagindo com outras pessoas" },
  { item_number: 4, question_text: "Quando há sobrecarga de estímulos, apresenta padrões rígidos e inflexíveis de comportamento, aparentemente estranhos" },
  { item_number: 5, question_text: "Não percebe quando os outros estão tentando tirar vantagem dela" },
  { item_number: 6, question_text: "Prefere estar sozinha do que com os outros" },
  { item_number: 7, question_text: "Demonstra perceber o que os outros estão pensando ou sentindo" },
  { item_number: 8, question_text: "Se comporta de maneira estranha ou bizarra" },
  { item_number: 9, question_text: "Precisa da ajuda de outras pessoas para satisfazer suas necessidades básicas" },
  { item_number: 10, question_text: "Leva as coisas muito \"ao pé da letra\" e não compreende o real significado de uma conversa" },
  { item_number: 11, question_text: "É autoconfiante" },
  { item_number: 12, question_text: "É capaz de comunicar seus sentimentos para as outras pessoas" },
  { item_number: 13, question_text: "É estranha na \"tomada de vez\" das interações com seus colegas (por exemplo, não parece entender a reciprocidade de uma conversa)" },
  { item_number: 14, question_text: "Não tem boa coordenação" },
  { item_number: 15, question_text: "Reconhece e responde de forma apropriada às mudanças no tom de voz e expressões faciais de outras pessoas" },
  { item_number: 16, question_text: "Evita o contato visual ou tem contato visual diferente" },
  { item_number: 17, question_text: "Reconhece quando algo é injusto" },
  { item_number: 18, question_text: "Tem dificuldade em fazer amigos, mesmo tentando dar o melhor de si" },
  { item_number: 19, question_text: "Fica frustrada tentando expressar suas ideias em uma conversa" },
  { item_number: 20, question_text: "Mostra interesses sensoriais incomuns (por exemplo, cheirar seus dedos com frequência) ou estranhos, chacoalha repetidamente pequenos itens" },
  { item_number: 21, question_text: "É capaz de imitar ações e comportamento de outras pessoas quando é socialmente apropriado fazê-lo" },
  { item_number: 22, question_text: "Interage apropriadamente com outros adultos" },
  { item_number: 23, question_text: "Não participa de atividades em grupo e eventos sociais a menos que seja convidada a fazê-lo" },
  { item_number: 24, question_text: "Tem mais dificuldade do que outras pessoas com mudanças em sua rotina" },
  { item_number: 25, question_text: "Não parece se importar em estar fora de sintonia ou em um \"mundo\" diferente dos outros" },
  { item_number: 26, question_text: "Oferece conforto para os outros quando estão tristes" },
  { item_number: 27, question_text: "Evita iniciar interações sociais com outros adultos" },
  { item_number: 28, question_text: "Pensa ou fala sobre a mesma coisa repetidamente" },
  { item_number: 29, question_text: "É considerada estranha ou esquisita pelas outras pessoas" },
  { item_number: 30, question_text: "Fica perturbada em uma situação com muitas coisas acontecendo" },
  { item_number: 31, question_text: "Não consegue tirar algo da sua mente uma vez que começa a pensar sobre isso" },
  { item_number: 32, question_text: "Tem boa higiene pessoal" },
  { item_number: 33, question_text: "É socialmente desajeitada, mesmo quando tenta ser educada" },
  { item_number: 34, question_text: "Evita pessoas que querem se aproximar dela por meio de contato afetivo" },
  { item_number: 35, question_text: "Tem dificuldade em acompanhar o fluxo de uma conversa normal" },
  { item_number: 36, question_text: "Tem dificuldade em se relacionar com os membros da família" },
  { item_number: 37, question_text: "Responde adequadamente às mudanças de humor das outras pessoas (por exemplo, quando o humor de um amigo muda de feliz para triste)" },
  { item_number: 38, question_text: "Tem dificuldade em se relacionar com adultos" },
  { item_number: 39, question_text: "Tem uma variedade de interesses extraordinariamente incomuns" },
  { item_number: 40, question_text: "É imaginativa sem perder contato com a realidade" },
  { item_number: 41, question_text: "Muda de uma atividade para outra sem objetivo aparente" },
  { item_number: 42, question_text: "Parece excessivamente sensível aos sons, texturas ou cheiros" },
  { item_number: 43, question_text: "Gosta de se mostrar \"boa de conversa\" (conversa informal com os outros)" },
  { item_number: 44, question_text: "Não entende como os acontecimentos estão relacionados entre si (causa e efeito), da mesma forma que outros adultos" },
  { item_number: 45, question_text: "Geralmente fica interessada no que as pessoas próximas estão prestando atenção" },
  { item_number: 46, question_text: "Tem expressão facial excessivamente séria" },
  { item_number: 47, question_text: "Ri em momentos inapropriados" },
  { item_number: 48, question_text: "Tem senso de humor e entende as piadas" },
  { item_number: 49, question_text: "É extremamente hábil em tarefas intelectuais ou computacionais, mas não consegue fazer tão bem a maioria das outras tarefas" },
  { item_number: 50, question_text: "Têm comportamentos estranhos e repetitivos" },
  { item_number: 51, question_text: "Tem dificuldade em responder perguntas diretamente e acaba falando em torno do assunto" },
  { item_number: 52, question_text: "Sabe quando está falando muito alto ou fazendo muito barulho" },
  { item_number: 53, question_text: "Fala com as pessoas com um tom de voz incomum (por exemplo, fala como um robô ou como se estivesse dando uma palestra)" },
  { item_number: 54, question_text: "Parece agir com as pessoas como se elas fossem objetos" },
  { item_number: 55, question_text: "Sabe quando está muito próxima ou invadindo o espaço de alguém" },
  { item_number: 56, question_text: "Caminha entre duas pessoas que estão conversando" },
  { item_number: 57, question_text: "Isolada; tende a não deixar sua casa" },
  { item_number: 58, question_text: "Concentra-se demais em partes das coisas ao invés de ver o todo" },
  { item_number: 59, question_text: "É excessivamente desconfiada" },
  { item_number: 60, question_text: "É emocionalmente distante, não demonstrando seus sentimentos" },
  { item_number: 61, question_text: "É inflexível e tem dificuldade para mudar de ideia" },
  { item_number: 62, question_text: "Dá explicações incomuns ou ilógicas do porquê de fazer as coisas" },
  { item_number: 63, question_text: "Toca ou cumprimenta os outros de uma maneira incomum" },
  { item_number: 64, question_text: "Fica muito agitada em situações sociais" },
  { item_number: 65, question_text: "Fica com olhar perdido ou olha fixamente para o nada" }
]

srs2_auto_items = [
  {
    item_number: 1,
    question_text: "Eu fico muito mais desconfortável em situações sociais do que quando estou sozinho."
  },
  {
    item_number: 2,
    question_text: "Minhas expressões faciais passam uma mensagem errada aos outros sobre como eu realmente me sinto."
  },
  {
    item_number: 3,
    question_text: "Eu me sinto confiante (ou seguro) quando estou interagindo com os outros."
  },
  {
    item_number: 4,
    question_text: "Quando estou sob estresse, tenho um comportamento rígido e inflexível que parece estranho para os outros."
  },
  {
    item_number: 5,
    question_text: "Eu não reconheço quando os outros estão tentando tirar vantagem sobre mim."
  },
  {
    item_number: 6,
    question_text: "Eu preferia estar sozinho do que com os outros."
  },
  {
    item_number: 7,
    question_text: "Normalmente eu consigo perceber como os outros estão se sentindo."
  },
  {
    item_number: 8,
    question_text: "Eu me comporto de maneiras que parecem estranhas ou esquisitas aos outros."
  },
  {
    item_number: 9,
    question_text: "Eu sou excessivamente dependente dos outros para me ajudar entender às minhas necessidades diárias."
  },
  {
    item_number: 10,
    question_text: "Eu levo as coisas muito \"ao pé da letra\", e por causa disso, eu interpreto mal o significado pretendido de partes de uma conversa."
  },
  {
    item_number: 11,
    question_text: "Eu sou autoconfiante."
  },
  {
    item_number: 12,
    question_text: "Eu sou capaz de comunicar meus sentimentos aos outros."
  },
  {
    item_number: 13,
    question_text: "Eu fico estranho nas interações com os colegas (por exemplo, eu levo um tempo acompanhando o vai e vem da conversa)."
  },
  {
    item_number: 14,
    question_text: "Eu não sou bem coordenado."
  },
  {
    item_number: 15,
    question_text: "Quando as pessoas mudam seu tom ou expressão facial, eu normalmente entendo o que isso significa."
  },
  {
    item_number: 16,
    question_text: "Eu evito contato visual ou me dizem que eu tenho contato visual diferente."
  },
  {
    item_number: 17,
    question_text: "Eu reconheço quando algo é injusto."
  },
  {
    item_number: 18,
    question_text: "Eu tenho dificuldade em fazer amigos, mesmo quando eu tento dar o melhor de mim."
  },
  {
    item_number: 19,
    question_text: "Eu fico frustrado tentando expressar minhas ideias em uma conversa."
  },
  {
    item_number: 20,
    question_text: "Eu tenho interesses sensoriais que os outros acham diferentes (por exemplo, cheirar ou olhar para as coisas de um jeito especial)."
  },
  {
    item_number: 21,
    question_text: "Eu sou capaz de imitar a ação e expressão dos outros quando é socialmente apropriado."
  },
  {
    item_number: 22,
    question_text: "Eu interajo apropriadamente com os outros adultos."
  },
  {
    item_number: 23,
    question_text: "Eu não participo de atividades em grupo ou eventos sociais a menos que seja obrigado a fazê-lo."
  },
  {
    item_number: 24,
    question_text: "Eu tenho mais dificuldade que os outros com mudanças na minha rotina."
  },
  {
    item_number: 25,
    question_text: "Eu não me importo de não estar \"na mesma onda\" ou fora de sintonia com os outros."
  },
  {
    item_number: 26,
    question_text: "Eu ofereço conforto aos outros quando eles estão tristes."
  },
  {
    item_number: 27,
    question_text: "Eu evito iniciar interações sociais com outros adultos."
  },
  {
    item_number: 28,
    question_text: "Eu penso ou falo sobre a mesma coisa repetidamente."
  },
  {
    item_number: 29,
    question_text: "Eu sou considerado pelos outros como estranho ou esquisito."
  },
  {
    item_number: 30,
    question_text: "Eu fico perturbado em situações com muitas coisas acontecendo."
  },
  {
    item_number: 31,
    question_text: "Eu não consigo tirar algo da minha mente uma vez que começo a pensar sobre aquilo."
  },
  {
    item_number: 32,
    question_text: "Eu tenho boa higiene pessoal."
  },
  {
    item_number: 33,
    question_text: "Meu comportamento é socialmente desajeitado, mesmo quando eu estou tentando ser educado."
  },
  {
    item_number: 34,
    question_text: "Eu evito pessoas que querem ser emocionalmente próximas a mim."
  },
  {
    item_number: 35,
    question_text: "Eu tenho dificuldade em acompanhar o fluxo de uma conversa normal."
  },
  {
    item_number: 36,
    question_text: "Eu tenho dificuldade em me relacionar com os membros da minha família."
  },
  {
    item_number: 37,
    question_text: "Eu respondo adequadamente às mudanças de humor das outras pessoas (por exemplo, quando o humor de um amigo muda de feliz para triste)."
  },
  {
    item_number: 38,
    question_text: "Eu tenho dificuldade em me relacionar com pessoas que não são da minha família."
  },
  {
    item_number: 39,
    question_text: "As pessoas me acham muito interessado em poucos assuntos, ou que eu me \"deixo levar\" por esses assuntos."
  },
  {
    item_number: 40,
    question_text: "Eu sou imaginativo."
  },
  {
    item_number: 41,
    question_text: "Eu às vezes mudo de uma atividade para outra sem nenhuma razão."
  },
  {
    item_number: 42,
    question_text: "Eu sou excessivamente sensível a certos sons, texturas ou cheiros."
  },
  {
    item_number: 43,
    question_text: "Eu gosto de conversas (conversas casuais com os outros)."
  },
  {
    item_number: 44,
    question_text: "Eu tenho mais problema do que a maioria das pessoas com o entendimento da causalidade (em outras palavras, como os eventos estão relacionados uns com os outros)."
  },
  {
    item_number: 45,
    question_text: "Quando os outros ao redor de mim estão prestando atenção em algo, eu fico interessado no que eles estão atentos."
  },
  {
    item_number: 46,
    question_text: "Os outros sentem que eu tenho expressões faciais excessivamente sérias."
  },
  {
    item_number: 47,
    question_text: "Eu dou risadas em momentos inapropriados."
  },
  {
    item_number: 48,
    question_text: "Eu tenho um bom senso de humor e consigo entender piadas."
  },
  {
    item_number: 49,
    question_text: "Eu sou extremamente bom em certos tipos de tarefas intelectuais, mas não sou tão bom na maioria das outras tarefas."
  },
  {
    item_number: 50,
    question_text: "Eu tenho comportamentos repetitivos que as outras pessoas consideram estranhos."
  },
  {
    item_number: 51,
    question_text: "Eu tenho dificuldade de responder perguntas diretamente e acabo discursando sobre o assunto."
  },
  {
    item_number: 52,
    question_text: "Eu falo muito alto sem perceber."
  },
  {
    item_number: 53,
    question_text: "Eu tenho tendência a falar com uma voz monótona (em outras palavras, menor inflexão da voz que a maioria das pessoas demonstra)."
  },
  {
    item_number: 54,
    question_text: "Eu tenho uma tendência a pensar sobre as pessoas do mesmo jeito que eu faço com os objetos."
  },
  {
    item_number: 55,
    question_text: "Eu fico muito perto dos outros ou invado o espaço pessoal deles sem perceber."
  },
  {
    item_number: 56,
    question_text: "Às vezes eu cometo o erro de andar entre duas pessoas que estão tentando conversar uma com a outra."
  },
  {
    item_number: 57,
    question_text: "Eu tenho uma tendência a me isolar."
  },
  {
    item_number: 58,
    question_text: "Eu me concentro demais nas partes das coisas ao invés de ver a figura como um todo."
  },
  {
    item_number: 59,
    question_text: "Eu sou mais desconfiado que a maioria das pessoas."
  },
  {
    item_number: 60,
    question_text: "As outras pessoas me acham emocionalmente distante e que não demonstro meus sentimentos."
  },
  {
    item_number: 61,
    question_text: "Eu tenho uma tendência a ser inflexível."
  },
  {
    item_number: 62,
    question_text: "Quando eu conto a alguém a minha razão para fazer alguma coisa, a pessoa acha que é incomum, sem lógica."
  },
  {
    item_number: 63,
    question_text: "Meu jeito de cumprimentar uma outra pessoa é incomum."
  },
  {
    item_number: 64,
    question_text: "Eu sou muito mais tenso em situações sociais do que quando eu estou sozinho."
  },
  {
    item_number: 65,
    question_text: "Eu me pego olhando fixo para o espaço."
  }
]

# Opções padrão para todos os itens
options = {
  '1' => 'Nunca é verdade',
  '2' => 'Raramente é verdade',
  '3' => 'Às vezes é verdade',
  '4' => 'Frequentemente é verdade'
}

# Criar itens para SRS-2 Heterorrelato
puts "Criando #{srs2_hetero_items.count} itens para: #{srs2_hetero.name}"
srs2_hetero_items.each do |item_data|
  PsychometricScaleItem.find_or_create_by!(
    psychometric_scale: srs2_hetero,
    item_number: item_data[:item_number]
  ) do |item|
    item.question_text = item_data[:question_text]
    item.options = options
    item.is_required = true
  end
end

# Criar itens para SRS-2 Autorrelato
puts "Criando #{srs2_auto_items.count} itens para: #{srs2_self.name}"
srs2_auto_items.each do |item_data|
  PsychometricScaleItem.find_or_create_by!(
    psychometric_scale: srs2_self,
    item_number: item_data[:item_number]
  ) do |item|
    item.question_text = item_data[:question_text]
    item.options = options
    item.is_required = true
  end
end

puts "✅ Todos os 65 itens SRS-2 criados com sucesso!"
