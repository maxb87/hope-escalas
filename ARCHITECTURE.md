# Arquitetura de Interpretação de Escalas

## Visão Geral

A arquitetura de interpretação foi projetada para ser **genérica**, **extensível** e seguir os **padrões RESTful do Rails**.

## Rota Principal

Existe apenas **uma rota** para interpretação:

```
GET /scale_responses/:id/interpretation
```

Esta rota é RESTful e funciona para qualquer tipo de escala que suporte interpretação.

## Componentes da Arquitetura

### 1. Factory Pattern - `InterpretationServiceFactory`

O factory é responsável por:

- Identificar qual serviço usar baseado no código da escala
- Verificar se uma escala suporta interpretação
- Delegar a geração de interpretação para o serviço apropriado

### 2. Serviços Específicos por Escala

Cada tipo de escala tem seu próprio serviço:

- `Srs2InterpretationService` - Para escalas SRS-2
- `Srs2ResponseAdapter` - Adapter para respostas SRS-2

### 3. Controller Genérico

O `ScaleResponsesController#interpretation` é genérico e:

- Verifica se a escala suporta interpretação
- Usa o factory para gerar interpretação
- Delega dados específicos baseado no tipo de escala

## Como Adicionar uma Nova Escala

### Passo 1: Criar o Serviço de Interpretação

```ruby
# app/services/interpretation/nova_escala_interpretation_service.rb
module Interpretation
  class NovaEscalaInterpretationService
    def self.adapter_for(scale_response)
      NovaEscalaResponseAdapter.new(scale_response)
    end

    def self.generate_interpretation(scale_response)
      # Lógica específica da nova escala
    end
  end
end
```

### Passo 2: Criar o Adapter (se necessário)

```ruby
# app/services/interpretation/nova_escala_response_adapter.rb
module Interpretation
  class NovaEscalaResponseAdapter
    delegate :patient, :results, to: :@scale_response

    def initialize(scale_response)
      @scale_response = scale_response
    end

    # Métodos específicos da nova escala
  end
end
```

### Passo 3: Registrar no Factory

```ruby
# Em app/services/interpretation/interpretation_service_factory.rb
SCALE_SERVICES = {
  "SRS2SR" => Interpretation::Srs2InterpretationService,
  "SRS2HR" => Interpretation::Srs2InterpretationService,
  "NOVA_ESCALA" => Interpretation::NovaEscalaInterpretationService  # <- Adicionar aqui
}.freeze
```

### Passo 4: Adicionar Lógica no Factory

```ruby
# No método generate_interpretation
case scale_response.psychometric_scale.code
when "SRS2SR", "SRS2HR"
  generate_srs2_interpretation(scale_response, service_class)
when "NOVA_ESCALA"  # <- Adicionar aqui
  generate_nova_escala_interpretation(scale_response, service_class)
end
```

### Passo 5: Adicionar Dados Específicos (se necessário)

```ruby
# No controller, método generate_scale_specific_data
case @scale_type
when :srs2
  generate_srs2_chart_data
when :nova_escala  # <- Adicionar aqui
  generate_nova_escala_data
end
```

## Vantagens da Arquitetura

1. **Single Responsibility**: Cada serviço cuida apenas de sua escala
2. **Open/Closed Principle**: Fácil adicionar novas escalas sem modificar código existente
3. **RESTful**: Uma única rota que funciona para todas as escalas
4. **Type Safety**: Factory previne erros de escalas não suportadas
5. **Consistência**: Estrutura padronizada para todas as escalas
6. **Testabilidade**: Cada componente pode ser testado isoladamente

## Escalas Atualmente Suportadas

- **SRS2SR**: Autorrelato SRS-2
- **SRS2HR**: Heterorrelato SRS-2

## Exemplos de Uso

### Verificar se uma escala suporta interpretação:

```ruby
Interpretation::InterpretationServiceFactory.supports_interpretation?(scale_response)
```

### Gerar interpretação:

```ruby
interpretation_data = Interpretation::InterpretationServiceFactory.generate_interpretation(scale_response)
```

### Listar escalas suportadas:

```ruby
Interpretation::InterpretationServiceFactory.supported_scales
# => ["SRS2SR", "SRS2HR"]
```
