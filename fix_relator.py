#!/usr/bin/env python3

# Ler o arquivo
with open('app/views/scale_responses/show.html.erb', 'r') as f:
    lines = f.readlines()

# Encontrar e substituir as linhas
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Se encontrar a linha do relator, substituir
    if '<strong>Relator:</strong>' in line:
        # Adicionar a linha anterior (Preenchido em)
        new_lines.append(lines[i-1])
        # Adicionar as novas linhas condicionais
        new_lines.append('  <% if @scale_response.hetero_report? && @scale_response.relator_name.present? %>\n')
        new_lines.append('    <br/><strong>Relator:</strong> <%= @scale_response.relator_name %> (<%= @scale_response.relator_relationship %>)\n')
        new_lines.append('  <% end %>\n')
        # Pular a linha original do relator
        i += 1
    else:
        new_lines.append(line)
        i += 1

# Escrever o arquivo corrigido
with open('app/views/scale_responses/show.html.erb', 'w') as f:
    f.writelines(new_lines)

print('Arquivo corrigido com sucesso!')
