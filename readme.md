# Documentação Completa do Jogo Rhythm Shield

## Visão Geral

Rhythm Shield é um jogo musical desenvolvido em Lua usando o framework LÖVE2D. O jogador deve posicionar um escudo para proteger um círculo central de lasers que seguem o ritmo da música. Com uma arquitetura modular, o jogo implementa funcionalidades como sistema de menus, cutscenes narrativas, galeria de conteúdo, e um sistema central de gameplay baseado em ritmo.

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
- `love.setGameCirclePosition(ratioX, ratioY)`: Define a posição relativa dos círculos de gameplay.

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

Gerencia o estado de jogo e a lógica de gameplay.

**Funções Principais:**
- `Game.new()`: Cria uma nova instância do gerenciador de jogo.
- `Game:loadLevel(levelModule)`: Carrega uma fase a partir de seu módulo.
- `Game:setCirclePosition(ratioX, ratioY)`: Define posição dos círculos do jogo.
- `Game:updateGameplayDimensions()`: Ajusta dimensões do gameplay baseado na tela.
- `Game:update(dt)`: Atualiza o estado do jogo.
- `Game:draw()`: Renderiza o jogo.
- `Game:keypressed(key)`: Processa entrada do teclado.
- `Game:pause()` e `Game:resume()`: Gerencia pausas do jogo.
- `Game:resize(w, h)`: Adapta o jogo a mudanças no tamanho da janela.

### 4. `gameplay.lua`

Implementa a mecânica central do jogo de ritmo.

**Funções Principais:**
- `gameplay.carregar(fase)`: Carrega uma fase no sistema de gameplay.
- `gameplay.atualizar(dt, anguloEscudoInput)`: Atualiza o estado do gameplay.
- `gameplay.desenhar(desenharUI)`: Renderiza o gameplay.
- `gameplay.setCentro(x, y)`: Define o centro dos círculos.
- `gameplay.setRaioCentral(raio)`: Define o raio do círculo central.
- `gameplay.setRaioExterno(raio)`: Define o raio do círculo externo.
- `gameplay.setDistanciaOrigem(dist)`: Define a distância da origem do laser.
- `gameplay.setForcaGravitacional(forca)`: Define a força gravitacional.
- `gameplay.setVelocidadeLaser(velocidade)`: Define a velocidade do laser.
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

**Métodos Comuns:**
- `new(...)`: Cria uma nova instância do elemento.
- `updateHover(mx, my)`: Verifica se o mouse está sobre o elemento.
- `draw()`: Renderiza o elemento.
- `mousepressed(x, y, button)`: Processa cliques no elemento.
- `mousereleased(x, y, button)`: Processa soltura do botão do mouse (para sliders).

### 7. `galeryManager.lua`

Sistema para visualização de conteúdo desbloqueado pelo jogador.

**Funções Principais:**
- `GaleryManager.new()`: Cria nova instância do gerenciador de galeria.
- `GaleryManager:refreshIcons()`: Atualiza os ícones com base na aba atual.
- `GaleryManager:update(dt)`: Atualiza o estado da galeria.
- `GaleryManager:draw()`: Renderiza a galeria.
- `GaleryManager:mousepressed(x, y, button)`: Processa interações do mouse.
- `GaleryManager:keypressed(key)`: Processa entrada do teclado.

### 8. `stagescenes.lua`

Sistema para exibir cenas especiais relacionadas às fases.

**Funções Principais:**
- `StageScene.new(stageSceneModule)`: Cria nova instância de cena de fase.
- `StageScene:load()`: Carrega os recursos da cena.
- `StageScene:update(dt)`: Atualiza as animações da cena.
- `StageScene:draw()`: Renderiza a cena.
- `StageScene:selectRandomSpritesheet()`: Seleciona uma spritesheet aleatória para animação.

### 9. `flagsSystem.lua`

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
- `FlagsSystem.addItem(itemId, quantidade)`: Adiciona um item à coleção do jogador.
- `FlagsSystem.hasItem(itemId, quantidade)`: Verifica se o jogador tem um item.

### 10. `config.lua`

Gerencia as configurações do jogo.

**Funções Principais:**
- `Config.setFullscreen(value)`: Define modo tela cheia.
- `Config.setVolume(value)`: Define volume do jogo.
- `Config.load()`: Carrega configurações salvas.

### 11. `save.lua`

Sistema para salvar e carregar dados do jogo.

**Funções Principais:**
- `Save.saveConfig(config)`: Salva configurações do jogo.
- `Save.loadConfig()`: Carrega configurações salvas.
- `Save.saveFlags(flagsData)`: Salva o estado de flags e achievements.
- `Save.loadFlags()`: Carrega o estado de flags e achievements.
- `Save.saveGameProgress(data)`: Salva progresso completo do jogo.
- `Save.loadGameProgress()`: Carrega progresso completo do jogo.
- `Save.clearAllData()`: Apaga todos os dados salvos.

## Estrutura de Arquivos de Dados

### 1. Formato de Arquivo de Fase (levels/...)

```lua
local fase = {
    nome = "Nome da Fase",
    bpm = 90,               -- Batidas por minuto
    duracao = 60,           -- Duração em segundos
    
    -- Definição dos ângulos
    angs = {
        A = 180, B = 195, C = 210, ...
    },
    
    -- Ângulos de alvo do laser
    tangAng = { "A", "B", "C", ... },
    
    -- Ângulos de origem do laser
    originAng = { "G", "F", "G", ... },
    
    -- Sequência de beats
    beats = { "n", "c", "n", ... },
    
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
        ...
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
        ...
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
                ...
            }
        },
        
        -- Passo com escolhas
        {
            text = "Escolha uma opção:",
            speaker = "personagem1",
            choices = {
                {
                    text = "Opção 1",
                    action = "startLevel",
                    levelPath = "levels/fase1",
                    nextStep = 7
                },
                ...
            }
        },
        ...
    }
}
```

### 3. Formato de Arquivo de Stage Scene (stages/...)

```lua
local stageSceneData = {
    nome = "Nome da Stage Scene",
    IconeLarge = "assets/icons/icone.png",
    
    -- Efeitos visuais
    Efeitos = {
        efeito1 = {
            background = "assets/backgrounds/fundo.png",
            intro = "assets/sprites/intro_spritesheet.png",
            loopSprite = {
                "assets/sprites/loop1.png",
                "assets/sprites/loop2.png"
            },
            x = 0.5,              -- Posição horizontal relativa
            y = 0.5,              -- Posição vertical relativa
            size = 1.0,           -- Escala
            animationSpeed = 0.05 -- Velocidade da animação
        }
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
   - Define posição dos círculos com `Game:setCirclePosition()`
   - Carrega nível com `Game:loadLevel(levelPath)`
   - Inicia fase com animação se especificada

5. **Gameplay**:
   - Jogador controla o escudo para desviar lasers
   - `Game:update()` atualiza o jogo com entrada do jogador
   - `FlagsSystem` monitora condições para achievements
   - `Gameplay` gerencia a lógica da fase

6. **Conclusão de Fase**:
   - Ao completar fase, `Gameplay` retorna "fase_concluida"
   - `FlagsSystem` verifica achievements
   - Carrega próxima fase ou retorna ao menu principal

## Sistema de Interação

### Controles Padrão
- **Setas Esquerda/Direita**: Movem o escudo durante o gameplay
- **Espaço/Enter**: Avança o diálogo em cutscenes
- **Mouse**: Seleciona opções nos menus e cutscenes
- **Escape**: Sai da fase atual para o menu principal
- **Alt+Enter/F11**: Alterna modo tela cheia

### Fluxo de Eventos de Input
1. `main.lua` recebe eventos do LÖVE2D
2. Eventos são enviados para módulo apropriado:
   - Para `menu.lua` quando no menu
   - Para `cutscenes.lua` quando em cutscene
   - Para `game.lua` quando em gameplay

### Sistema de UI
Todos os elementos de UI são implementados em `button.lua` e seguem processo de interação:
1. Detecção de hover com `updateHover(mx, my)`
2. Processamento de clique com `mousepressed(x, y, button)`
3. Execução de callback de interação
4. Renderização com `draw()`

## Considerações Técnicas

### Sistema de Suavização de Movimento
- Implementado no módulo `gameplay.lua`
- Utiliza interpolação linear para suavizar transições entre ângulos
- Emprega sistema de previsão para iniciar transições antes das batidas

### Sistema de Trajetória do Laser
- Simula campo gravitacional para criar trajetórias curvas
- Implementa física de partículas para renderizar o laser em tempo real
- Detecta colisões precisas para verificar acertos do jogador

### Dimensionamento e Posicionamento Responsivo
- Todo o jogo adapta-se a diferentes tamanhos de tela
- Utiliza posicionamento relativo (0.0 a 1.0) para escalabilidade
- Recalcula dimensões e posições durante redimensionamento

### Tratamento de Erros UTF-8
- Implementa `pcall()` para capturar erros de decodificação UTF-8
- Fornece fallbacks seguros para cálculos de largura de texto
- Sanitiza textos para evitar problemas de renderização

## Progressão de Jogo e Desbloqueio de Conteúdo

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
   - Implementa formato JSON para armazenamento

3. **Acesso a Conteúdo Desbloqueado**:
   - Galeria exibe conteúdo desbloqueado por categoria
   - Menu principal habilita acesso a novas fases
   - Cutscenes podem ser revistas após desbloqueio

## Error Handling & Resource Management

The game implements comprehensive error handling to ensure stability even when resource files are missing or corrupted:

### Robust Resource Loading

- **Image Loading**: All image loading operations use `pcall()` to catch errors from missing or corrupted files
- **Fallback Resources**: Default placeholder images are generated when requested resources cannot be loaded
- **Visual Error Indicators**: When resources fail to load, visual indicators are shown instead of crashing
- **Defensive Programming**: All methods validate their inputs and check for nil values before attempting operations

### Error Recovery Mechanisms

- **StageScene Resilience**: The StageScene system can operate even with partially loaded resources
- **Gallery Error Prevention**: The GaleryManager prevents cascading failures when individual items fail to load
- **UI Element Timers**: UI interactions use frame-based timers instead of callbacks to avoid timing-related errors

### Debugging Assistance

- **Descriptive Error Messages**: Detailed error messages are logged to the console to facilitate debugging
- **Error Visualization**: Visual indicators show where resources failed to load
- **Graceful Degradation**: Features degrade gracefully rather than crashing when resources are unavailable

### Asset Management Recommendations

- Always place assets in the proper directories: `assets/backgrounds/`, `assets/sprites/`, etc.
- Use the provided fallback mechanisms when creating new content modules
- Test your additions with the `-debug` flag to see detailed resource loading information

## Expansão do Jogo

Para continuar o desenvolvimento, considere as seguintes melhorias:

1. **Sistema de Áudio**:
   - Implementar reprodução de música sincronizada com o gameplay
   - Adicionar efeitos sonoros para feedback ao jogador
   - Implementar sistema de mixagem para balancear volume

2. **Interface do Usuário Avançada**:
   - Adicionar efeitos visuais e transições entre menus
   - Implementar telas de pausa e configurações dentro do jogo
   - Adicionar gráficos de desempenho e estatísticas do jogador

3. **Conteúdo Adicional**:
   - Implementar mais fases com diferentes padrões rítmicos
   - Expandir a narrativa com novas cutscenes e personagens
   - Adicionar novos elementos de gameplay como power-ups

4. **Otimizações**:
   - Implementar carregamento assíncrono para recursos grandes
   - Otimizar renderização para melhor desempenho em dispositivos de baixo poder
   - Aprimorar o gerenciamento de memória para cenas complexas

---

Esta documentação reflete o estado atual do jogo Rhythm Shield. À medida que novas funcionalidades forem implementadas, a documentação deverá ser atualizada para manter-se como referência completa e atual do projeto.