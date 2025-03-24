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
|-- screen_utils.lua   # Utilitários para gestão de tela e responsividade
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
- `love.resize(w, h)`: Adapta o jogo a mudanças no tamanho da janela, utilizando ScreenUtils.

### 2. `screen_utils.lua` (Novo)

Um módulo central para gerenciar dimensões de tela, escalas e posicionamento responsivo em todo o jogo.

**Funções Principais:**
- `ScreenUtils.init()`: Inicializa as dimensões iniciais.
- `ScreenUtils.updateDimensions(width, height)`: Atualiza dimensões quando a tela muda de tamanho.
- `ScreenUtils.relativeToScreen(percentX, percentY)`: Converte porcentagens em coordenadas de tela.
- `ScreenUtils.scaleValue(value)`: Escala um valor com base no tamanho da tela.
- `ScreenUtils.scaleFontSize(baseSize)`: Calcula tamanho de fonte que escala com a tela.
- `ScreenUtils.centerElement(width, height)`: Calcula posição centralizada para elementos.
- `ScreenUtils.anchoredPosition(width, height, anchor)`: Posiciona elementos com diferentes ancoragens.
- `ScreenUtils.gridPosition(column, row, itemWidth, itemHeight)`: Calcula posições em grid para galerias.

### 3. `menu.lua`

Gerencia a navegação entre os diferentes estados e menus do jogo, agora com layout responsivo.

**Funções Principais:**
- `Menu.new()`: Cria uma nova instância do sistema de menus.
- `Menu:loadMainMenu()`: Carrega o menu principal com posicionamento responsivo.
- `Menu:loadGalleryMenu()`: Carrega o menu da galeria.
- `Menu:loadSettingsMenu()`: Carrega o menu de configurações.
- `Menu:update(dt)`: Atualiza o estado do menu atual.
- `Menu:draw()`: Renderiza o menu atual.
- `Menu:resize(w, h)`: Adapta os menus quando a janela é redimensionada.

### 4. `config.lua`

Gerencia as configurações do jogo, com manipulação robusta do modo fullscreen.

**Funções Principais:**
- `Config.setFullscreen(value)`: Alterna entre modo janela e tela cheia com preservação de estado.
- `Config.setVolume(value)`: Define o nível de volume.
- `Config.load()`: Carrega configurações salvas.
- `Config.getScreenInfo()`: Retorna informações do modo de tela atual.
- `Config.centerWindow()`: Centraliza a janela na tela quando não está em fullscreen.

### 5. `game.lua`

Gerencia o estado de jogo e a lógica de nível, com integração ao sistema de responsividade.

**Funções Principais:**
- `Game.new()`: Cria uma nova instância do gerenciador de jogo.
- `Game:calculateDimensions()`: Recalcula dimensões do jogo com base no tamanho da tela.
- `Game:loadLevel(levelModule)`: Carrega uma fase a partir de seu módulo.
- `Game:update(dt)`: Atualiza o estado do jogo.
- `Game:draw()`: Renderiza o jogo com stage scene e gameplay.
- `Game:resize(w, h)`: Adapta o jogo a mudanças no tamanho da janela.

### 6. `gameplay.lua`

Implementa a mecânica central do jogo de ritmo com blocos que caem em trilhas.

**Funções Principais:**
- `gameplay.setDimensoes(width, height)`: Define as dimensões da área de gameplay.
- `gameplay.setOffset(x, y)`: Posiciona a área de gameplay na tela.
- `gameplay.carregar(fase)`: Carrega uma fase no sistema de gameplay.
- `gameplay.atualizar(dt)`: Atualiza o estado do gameplay.
- `gameplay.desenhar(desenharUI)`: Renderiza o gameplay com adaptação ao tamanho da tela.
- `gameplay.onResize()`: Manipula eventos de redimensionamento.
- `gameplay.init()`: Inicializa ou reinicializa dimensões e posicionamento.

### 7. `cutscenes.lua`

Sistema para exibir sequências narrativas interativas, agora com layout totalmente responsivo.

**Funções Principais:**
- `Cutscenes.new(cutsceneFile)`: Cria uma nova instância de cutscene.
- `Cutscenes:updateScaledDimensions()`: Atualiza dimensões de UI com base no tamanho da tela.
- `Cutscenes:load()`: Carrega os dados da cutscene.
- `Cutscenes:draw()`: Renderiza a cutscene com elementos adaptados à tela.
- `Cutscenes:resize(width, height)`: Adapta a cutscene quando a janela é redimensionada.

### 8. `galeryManager.lua`

Sistema para visualização de conteúdo desbloqueado pelo jogador, agora com layout responsivo.

**Funções Principais:**
- `GaleryManager.new()`: Cria nova instância do gerenciador de galeria.
- `GaleryManager:refreshIcons()`: Atualiza os ícones com posicionamento adaptado à tela.
- `GaleryManager:resize(w, h)`: Adapta a galeria quando a janela é redimensionada.

### 9. `stagescenes.lua`

Sistema para apresentação de cenas de fundo animadas, corrigido para funcionar em todas as resoluções.

**Funções Principais:**
- `StageScene.new(stageSceneModule)`: Cria uma nova instância de cena de palco.
- `StageScene:load()`: Carrega recursos da cena.
- `StageScene:draw()`: Renderiza a cena adaptada ao tamanho da tela.
- `StageScene:resize(width, height)`: Adapta a cena quando a janela é redimensionada.

## Sistema de Responsividade

O jogo agora implementa um sistema completo de responsividade que garante funcionamento consistente em modo janela e tela cheia:

### 1. Arquitetura Centralizada
- O módulo `screen_utils.lua` centraliza o gerenciamento de dimensões da tela
- Todos os módulos utilizam funções deste utilitário para calcular posições e escalas
- Eventos de redimensionamento são propagados para todos os componentes relevantes

### 2. UI Adaptativa
- Os elementos de UI agora escalam proporcionalmente ao tamanho da tela
- Botões, textos e ícones mantêm proporções consistentes em qualquer resolução
- Menus são reposicionados automaticamente para funcionar bem em qualquer tamanho de tela

### 3. Gerenciamento de Tela Cheia
- Transição suave entre modo janela e tela cheia
- Preservação de estado e dimensões ao alternar entre modos
- Controle de proporções para evitar distorções visuais

### 4. Escalabilidade de Fontes
- Tamanhos de fonte adaptativos que escalam com a resolução 
- Limites mínimos para garantir legibilidade em qualquer tamanho de tela
- Consistência visual entre diferentes resoluções

### 5. Posicionamento Relativo
- Sistema de posicionamento baseado em porcentagens da tela
- Funções auxiliares para ancorar elementos em diferentes pontos da tela
- Sistema de grid para organização de elementos em galerias e menus

## Gameplay Responsivo

### Área de Jogo
- Dimensões calculadas com base em porcentagem da tela e limites fixos
- Posicionamento consistente mesmo com mudanças de resolução
- Escalabilidade de todos os elementos visuais

### Renderização
- Sistema de trilhas que se adapta a diferentes alturas de tela
- Blocos com tamanho proporcional à largura da área de jogo
- Interface de usuário que escala automaticamente

### Interação
- Zonas de clique que se ajustam ao tamanho da tela
- Consistência de controles em qualquer resolução
- Feedback visual que funciona bem em todas as escalas

## Correções e Melhorias

### Correções de Bugs
- Corrigido erro ao chamar `getWidth()` em quads no módulo `stagescenes.lua`
- Corrigido posicionamento incorreto em resoluções altas
- Corrigido problemas de sobreposição em modo tela cheia
- Corrigidos erros de syntax em várias funções

### Melhorias de Desempenho
- Otimização do cálculo de dimensões para minimizar recálculos desnecessários
- Uso mais eficiente de memória com reutilização de recursos
- Melhor tratamento de eventos de redimensionamento

### Melhorias Visuais
- Maior consistência visual entre diferentes resoluções
- Melhor escalabilidade de elementos gráficos
- Transições mais suaves entre diferentes estados do jogo

## Conclusão

Com as melhorias implementadas, o Rhythm Game agora oferece uma experiência consistente e responsiva tanto em modo janela quanto em tela cheia. O sistema centralizado de gerenciamento de tela proporciona uma base sólida para expansões futuras, enquanto a arquitetura modular existente foi mantida e aprimorada.