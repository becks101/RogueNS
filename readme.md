# Documentação do Jogo em LÖVE2D

## Visão Geral da Estrutura

Este projeto consiste em um jogo desenvolvido em Lua utilizando o framework LÖVE2D. A arquitetura do jogo implementa um sistema de menus, galeria de conteúdo e sistema de cutscenes para storytelling.

## Principais Módulos

### 1. Sistema de Interface (`button.lua`)

Este módulo fornece elementos de UI reutilizáveis para diferentes partes do jogo.

#### Classes Implementadas:
- **Button**: Implementação básica de botão interativo
- **Selector**: Botão que mantém estado de seleção
- **Tab**: Botão para navegação entre abas
- **VolumeSlider**: Controle deslizante para ajuste de volume
- **GaleryIcons**: Ícones clicáveis com efeitos de hover para a galeria

#### Funcionalidades:
- Sistema de hover (detecção de mouse sobre o elemento)
- Callbacks para interação com cliques
- Efeitos visuais para feedback ao usuário
- Suporte a diferentes estados visuais (normal, hover, selecionado)

### 2. Sistema de Cutscenes (`cutscenes.lua`)

Módulo para gerenciamento e exibição de sequências narrativas interativas.

#### Recursos:
- Exibição de diálogos com efeito de digitação
- Suporte a retratos de personagens
- Exibição de sprites de personagens na cena
- Suporte a escolhas e ramificações na narrativa
- Transições com efeito de fade
- Backgrounds para cada cena

#### Fluxo de uma Cutscene:
1. Carregamento dos dados da cutscene a partir de arquivo
2. Processamento sequencial dos passos da narrativa
3. Animação de texto e espera por input do usuário
4. Gerenciamento de escolhas (quando aplicável)
5. Transição para próximo passo ou finalização

### 3. Gerenciador da Galeria (`galeryManager.lua`)

Interface para visualização de conteúdo desbloqueado pelo jogador.

#### Categorias de Conteúdo:
- Cenas de Fase (Stage Scenes)
- Cutscenes
- Itens

#### Funcionalidades:
- Navegação entre diferentes categorias via sistema de abas
- Exibição de ícones clicáveis para cada item
- Visualização de conteúdo selecionado
- Controles para retornar à navegação da galeria

### 4. Sistema de Menu Principal (`menu.lua`)

Gerencia a interface principal do jogo e navegação entre diferentes telas.

#### Menus Implementados:
- Menu Principal: Acesso às principais funcionalidades do jogo
- Menu de Galeria: Visualização de conteúdo desbloqueado
- Menu de Configurações: Ajustes de fullscreen e volume

#### Controle de Estado:
- Gerenciamento do menu atual
- Posicionamento responsivo de elementos baseado na resolução da tela
- Manipulação de interações do usuário (mouse/teclado)

### 5. Entrada do Programa (`main.lua`)

Ponto de entrada do aplicativo LÖVE2D, configura callbacks do framework e inicializa o jogo.

#### Callbacks Implementados:
- `love.load()`: Inicialização do jogo
- `love.update()`: Atualização lógica por frame
- `love.draw()`: Renderização na tela
- `love.mousepressed()`, `love.mousereleased()`: Gerenciamento de input do mouse
- `love.keypressed()`: Gerenciamento de input do teclado
- `love.resize()`: Adaptação a mudanças de tamanho da janela

## Fluxo de Dados e Interação entre Módulos

1. `main.lua` inicializa o jogo e carrega o módulo `menu.lua`
2. `menu.lua` gerencia a navegação entre diferentes telas:
   - Quando o menu de galeria é selecionado, inicializa `galeryManager.lua`
   - `galeryManager.lua` carrega os ícones para a categoria selecionada
   - Quando um ícone é clicado, carrega o conteúdo apropriado (StageScene ou Cutscene)
   - Para cutscenes, utiliza o módulo `cutscenes.lua` para renderizar a sequência narrativa

3. Eventos de mouse e teclado são propagados da seguinte forma:
   - `main.lua` recebe os eventos do LÖVE2D
   - Passa para `menu.lua` que então:
     - Propaga para componentes de UI quando no menu
     - Propaga para `galeryManager.lua` quando na galeria
     - `galeryManager.lua` propaga para a cutscene ativa quando visualizando conteúdo

## Formato dos Arquivos de Conteúdo

### Arquivo de Cutscene
```lua
local cutsceneData = {
    nome = "Nome da Cutscene",       -- Nome exibido na galeria
    IconeLarge = "caminho/icone.png", -- Ícone para a galeria
    background = "caminho/bg.png",    -- Background inicial
    characters = {
        -- Definições de personagens
    },
    steps = {
        -- Sequência de passos da cutscene
    }
}
return cutsceneData
```

### Arquivo de Stage Scene
Segue estrutura similar, com especificações próprias para cenas de fase.

## Sistema de Interação

O jogo implementa um sistema completo de interação por mouse e teclado:

1. **Mouse**:
   - Hover sobre elementos interativos (botões, ícones)
   - Cliques para seleção e ativação
   - Arrastar para controles deslizantes (volume)

2. **Teclado**:
   - Navegação por cutscenes (Espaço/Enter para avançar)
   - Escape para pular cutscenes ou retornar a menus anteriores

## Considerações para o Desenvolvimento Futuro

1. **Sistema de Save/Load**: Persistência de progresso do jogador
2. **Gerenciamento de Áudio**: Implementação completa de música e efeitos sonoros
3. **Sistema de Conquistas**: Rastreamento de objetivos e desbloqueio de conteúdo
4. **Localização**: Suporte a múltiplos idiomas
5. **Otimização para Mobile**: Adaptação para telas sensíveis ao toque
