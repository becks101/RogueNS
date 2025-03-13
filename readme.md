# Documentação Completa do Jogo Rhythm Game

## Visão Geral

Rhythm Game é um jogo musical desenvolvido em Lua usando o framework LÖVE2D. O jogador controla um círculo que deve capturar blocos coloridos que caem em trilhas ao ritmo da música. O jogo conta com uma arquitetura modular, implementando funcionalidades como sistema de menus, cutscenes narrativas, galeria de conteúdo, e um sistema de gameplay baseado em ritmo.

## Estrutura de Diretórios

```
/
|-- assets/
|   |-- backgrounds/    # Imagens de fundo
|   |-- icons/          # Ícones para galeria e UI
|   |-- portraits/      # Retratos de personagens para cutscenes
|   |-- sprites/        # Sprites de personagens e efeitos
|
|-- cutscenes/
|   |-- intro.lua       # Cutscene introdutória
|   |-- chapter1.lua    # Capítulo 1 da história
|
|-- levels/
|   |-- tutorial.lua    # Fase tutorial
|   |-- exemploDeFase01.lua # Primeira fase principal
|
|-- stages/
|   |-- mast_branch01.lua # Stage scene para galeria
|   |-- ss_mast01.lua     # Stage scene para galeria
|
|-- button.lua         # Sistema de UI e botões
|-- config.lua         # Configurações do jogo
|-- cutscenes.lua      # Sistema de cutscenes
|-- flagsSystem.lua    # Sistema de flags e achievements
|-- galeryManager.lua  # Gerenciador de galeria
|-- game.lua           # Gerenciador central do gameplay
|-- gameplay.lua       # Mecanismos de jogabilidade do ritmo
|-- main.lua           # Ponto de entrada do jogo
|-- menu.lua           # Sistema de menus
|-- save.lua           # Sistema de salvamento
|-- stagescenes.lua    # Sistema de exibição de cenas de fase
|-- readme.md          # Documentação básica do projeto
```

## Módulos Principais

### 1. `main.lua`

O ponto de entrada da aplicação, configura callbacks do framework LÖVE2D e inicializa o jogo.

**Funções Principais:**
- `love.load()`: Inicializa configurações, cria a janela e instancia o menu.
- `love.update(dt)`: Atualiza o jogo frame a frame.
- `love.draw()`: Renderiza os elementos na tela.
- `love.resize(w, h)`: Adapta o jogo a mudanças no tamanho da janela.

### 2. `menu.lua`

Gerencia a navegação entre os diferentes estados e menus do jogo.

**Funções Principais:**
- `Menu.new()`: Cria uma nova instância do sistema de menus.
- `Menu:loadMainMenu()`: Carrega o menu principal.
- `Menu:loadGalleryMenu()`: Carrega o menu da galeria.
- `Menu:loadSettingsMenu()`: Carrega o menu de configurações.
- `Menu:update(dt)`: Atualiza o estado do menu atual.
- `Menu:draw()`: Renderiza o menu atual.
- `Menu:mousepressed(x, y, button)`: Gerencia cliques nos elementos do menu.
- `Menu:keypressed(key)`: Processa entrada do teclado.

### 3. `game.lua`

Gerencia o estado de jogo e a lógica de nível.

**Funções Principais:**
- `Game.new()`: Cria uma nova instância do gerenciador de jogo.
- `Game:loadLevel(levelModule)`: Carrega uma fase a partir de seu módulo.
- `Game:update(dt)`: Atualiza o estado do jogo.
- `Game:draw()`: Renderiza o jogo com stage scene e gameplay.
- `Game:keypressed(key)`: Processa entrada do teclado para o jogo.
- `Game:resize(w, h)`: Adapta o jogo a mudanças no tamanho da janela.
- `Game.newLevelCreator()`: Cria um gerador de níveis.
- `Game.newPhaseGenerator()`: Cria um gerador de fases com seeds.
- `Game.formatSeed()`: Formata uma seed para apresentação visual.

### 4. `gameplay.lua` (Atualizado)

Implementa a mecânica central do jogo de ritmo com blocos que caem em trilhas.

**Funções Principais:**
- `gameplay.setDimensoes(width, height)`: Define as dimensões da área de gameplay.
- `gameplay.setOffset(x, y)`: Posiciona a área de gameplay na tela.
- `gameplay.carregar(fase)`: Carrega uma fase no sistema de gameplay.
- `gameplay.atualizar(dt, anguloEscudoInput)`: Atualiza o estado do gameplay.
- `gameplay.desenhar(desenharUI)`: Renderiza o gameplay com trilhas, blocos e jogador.
- `gameplay.keypressed(key)`: Processa entrada de teclado para movimentação.
- `gameplay.getPontuacao()`: Obtém a pontuação atual.
- `gameplay.getCombo()`: Obtém o combo atual.
- `gameplay.getMultiplicador()`: Obtém o multiplicador atual.

### 5. `cutscenes.lua`

Sistema para exibir sequências narrativas interativas.

**Funções Principais:**
- `Cutscenes.new(cutsceneFile)`: Cria uma nova instância de cutscene.
- `Cutscenes:load()`: Carrega os dados da cutscene.
- `Cutscenes:processCurrentStep()`: Processa o passo atual da cutscene.
- `Cutscenes:update(dt)`: Atualiza o estado da cutscene.
- `Cutscenes:draw()`: Renderiza a cutscene.
- `Cutscenes:mousepressed(x, y, button)`: Processa cliques do mouse.
- `Cutscenes:keypressed(key)`: Processa entrada do teclado.
- `Cutscenes:complete()`: Finaliza a cutscene.

### 6. `button.lua`

Implementa os componentes de UI usados em todo o jogo.

**Classes Implementadas:**
- `Button`: Botão padrão clicável.
- `Selector`: Botão que mantém estado de seleção.
- `Tab`: Botão específico para navegação entre abas.
- `VolumeSlider`: Controle deslizante para ajuste de volume.
- `GaleryIcons`: Ícones interativos para a galeria.

### 7. `galeryManager.lua`

Sistema para visualização de conteúdo desbloqueado pelo jogador.

**Funções Principais:**
- `GaleryManager.new()`: Cria nova instância do gerenciador de galeria.
- `GaleryManager:refreshIcons()`: Atualiza os ícones com base na aba atual.
- `GaleryManager:update(dt)`: Atualiza o estado da galeria.
- `GaleryManager:draw()`: Renderiza a galeria.
- `GaleryManager:mousepressed(x, y, button)`: Processa interações do mouse.
- `GaleryManager:keypressed(key)`: Processa entrada do teclado.

### 8. `flagsSystem.lua`

Sistema para gerenciar flags, achievements e recompensas.

**Funções Principais:**
- `FlagsSystem.updateRhythmGameData(gameplay)`: Atualiza dados do jogo.
- `FlagsSystem.resetRhythmGameData(level)`: Reseta dados para nova fase.
- `FlagsSystem.checkAchievement(achievement)`: Verifica um achievement específico.
- `FlagsSystem.checkAllAchievements(fase)`: Verifica todos os achievements.
- `FlagsSystem.finalizeFase(reason)`: Finaliza a fase atual.
- `FlagsSystem.saveState()`: Salva o estado das flags.
- `FlagsSystem.loadState()`: Carrega o estado salvo.
- `FlagsSystem.setFlag(flagName, value)`: Define uma flag.
- `FlagsSystem.getFlag(flagName)`: Obtém o valor de uma flag.

## Novo Sistema de Gameplay (Atualizado)

O sistema de gameplay foi completamente reformulado, substituindo o anterior baseado em escudo e lasers por um novo baseado em trilhas e blocos:

### Mecânica Principal

1. **Estrutura Visual:**
   - O gameplay é exibido como um painel semitransparente à direita da tela
   - A área de gameplay tem largura fixa entre 160-200 pixels, com altura proporcional
   - A stage scene é mostrada em tela completa como plano de fundo
   - O gameplay funciona como um overlay sobre a stage scene

2. **Elementos do Jogo:**
   - **Trilhas**: 4 caminhos verticais por onde os blocos caem
   - **Blocos**: Quadrados coloridos que caem nas trilhas em ritmo sincronizado com a música
   - **Jogador**: Círculo que se move entre as trilhas para capturar os blocos
   - **Pontuação**: Sistema de pontos baseado em acertos

3. **Controles:**
   - **Seta Esquerda**: Move o jogador para a trilha à esquerda
   - **Seta Direita**: Move o jogador para a trilha à direita

4. **Geração de Fases:**
   - Sistema de seed para geração procedural de fases
   - Cada fase tem um BPM (batidas por minuto) que determina a velocidade dos blocos
   - Configurações de dificuldade, velocidade e intervalo de blocos ajustáveis

5. **Adaptação a Diferentes Telas:**
   - Sistema de posicionamento absoluto em pixels para consistência visual
   - Funciona corretamente tanto em modo janela quanto em fullscreen
   - Cálculos de posição e tamanho arredondados para evitar problemas visuais

### Implementação Técnica

1. **Posicionamento:**
   - Área de gameplay sempre à direita da tela, com distância fixa da borda
   - Trilhas igualmente espaçadas dentro da área de gameplay
   - Blocos sempre centrados em suas trilhas
   - Jogador posicionado próximo ao fundo da área, com altura fixa

2. **Renderização:**
   - Fundo semitransparente com cantos arredondados
   - Trilhas com cores diferentes para a trilha ativa (onde está o jogador)
   - Blocos com cores diferentes e efeitos visuais (sombras, brilhos, cantos arredondados)
   - Interface do usuário mostrando pontuação e nível atual

3. **Colisões:**
   - Sistema de colisão entre o jogador (círculo) e os blocos (retângulos)
   - Quando há colisão, o bloco é removido e o jogador ganha pontos
   - Blocos que saem da tela sem serem capturados são removidos sem pontuação

## Estrutura de Arquivos de Dados

### 1. Formato de Arquivo de Fase (levels/...)

```lua
local fase = {
    nome = "Nome da Fase",
    bpm = 90,               -- Batidas por minuto
    duracao = 60,           -- Duração em segundos
    fase_seed = 13312212,   -- Seed para geração procedural
    
    -- Parâmetros específicos de gameplay
    velocidade = 180,       -- Velocidade de queda dos blocos
    intervalo = 0.7,        -- Intervalo entre blocos em segundos
    dificuldade = 1,        -- Nível de dificuldade
    
    -- Cores customizadas (opcional)
    cores = {
        {0.92, 0.7, 0.85},  -- Rosa pastel
        {0.7, 0.9, 0.8},    -- Verde mint
        {0.7, 0.8, 0.95},   -- Azul céu
        {0.97, 0.9, 0.7}    -- Amarelo pastel
    },
    
    -- Stage scene para introdução
    animation = "stages/nome_da_animacao",
    
    -- Achievements da fase
    achievements = {
        {
            id = "ID_Achievement",
            condition = "combo_maximo",
            value = 10,
            reward_type = "fase",
            reward_value = "proxima_fase"
        },
        -- Mais achievements...
    }
}
```

### 2. Formato de Arquivo de Cutscene (cutscenes/...)

```lua
local cutsceneData = {
    nome = "Nome da Cutscene",
    IconeLarge = "assets/icons/icone.png",
    background = "assets/backgrounds/fundo.jpg",
    
    -- Personagens
    characters = {
        personagem1 = {
            name = "Nome Exibido",
            portrait = "assets/portraits/retrato.png"
        },
        -- Mais personagens...
    },
    
    -- Passos da cutscene
    steps = {
        {
            text = "Texto do diálogo",
            speaker = "personagem1",
            sprites = {
                {
                    image = "assets/sprites/sprite.png",
                    x = 0.7,    -- Posição horizontal relativa
                    y = 0.5,    -- Posição vertical relativa
                    scale = 1.0 -- Escala
                },
                -- Mais sprites...
            }
        },
        -- Mais passos...
    }
}
```

## Fluxo de Execução do Jogo

1. **Inicialização**: 
   - `main.lua` carrega configurações com `Config.load()`
   - Cria instância de `Menu` com `Menu.new()`

2. **Menu Principal**:
   - Jogador seleciona "Novo Jogo"
   - Menu cria instância de `Cutscenes` carregando a cutscene introdutória
   - Altera estado para `"cutscene"`

3. **Cutscene**:
   - Reproduz a cutscene exibindo diálogos e sprites
   - Jogador interage avançando diálogos e fazendo escolhas
   - Ao selecionar um caminho, a cutscene define `levelToLoad`
   - Ao finalizar, envia o nível para ser carregado

4. **Carregamento de Fase**:
   - Menu cria instância de `Game` com `Game.new()`
   - Carrega nível com `Game:loadLevel(levelPath)`
   - Inicia fase com animação se especificada

5. **Gameplay**:
   - Jogador controla o círculo para capturar blocos
   - `Game:update()` atualiza a cena com entrada do jogador
   - `FlagsSystem` monitora condições para achievements
   - `Gameplay` gerencia a lógica dos blocos, trilhas e colisões

6. **Conclusão de Fase**:
   - Ao completar fase, `Gameplay` retorna "fase_concluida"
   - `FlagsSystem` verifica achievements
   - Carrega próxima fase ou retorna ao menu principal

## Sistema de Interação

### Controles Padrão
- **Setas Esquerda/Direita**: Movem o jogador entre as trilhas
- **Espaço/Enter**: Avança o diálogo em cutscenes
- **Mouse**: Seleciona opções nos menus e cutscenes
- **Escape**: Sai da fase atual para o menu principal
- **Alt+Enter/F11**: Alterna modo tela cheia

## Progressão de Jogo

O jogo implementa um sistema de progressão completo através do `flagsSystem.lua`:

1. **Achievements e Recompensas**:
   - Achievements são verificados durante o gameplay
   - Tipos de recompensas:
     - `fase`: Desbloqueia novas fases
     - `stage_scene`: Desbloqueia cenas para a galeria
     - `cutscene`: Desbloqueia cutscenes para a galeria

2. **Persistência de Dados**:
   - Utiliza `save.lua` para salvar progresso
   - Armazena configurações, flags, achievements e itens coletados

3. **Sistema de Seed**:
   - Fases são geradas proceduralmente com base em seeds
   - Cada fase tem uma seed única que determina o padrão de blocos
   - Uma "run seed" global pode ser combinada com a seed da fase para criar variações

## Conclusão

Esta documentação reflete o estado atual do jogo Rhythm Game, incluindo o novo sistema de gameplay baseado em trilhas e blocos que substituiu o antigo sistema de escudo e lasers. O jogo mantém sua arquitetura modular e extensibilidade, permitindo adicionar facilmente novas fases, cutscenes e conteúdo para a galeria.