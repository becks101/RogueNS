-- gameplay.lua
-- Módulo que contém toda a lógica do jogo de ritmo

local gameplay = {}

-- Variáveis locais do gameplay
local larguraTela, alturaTela
local jogador
local levelCreator, phaseGenerator
local nivel
local blocos = {}
local pontos = 0
local tempoUltimoBloco = 0
local offsetX = 0
local offsetY = 0 -- Offset para posicionamento na tela

-- Funções auxiliares
-------------------------
-- Cria um novo bloco baseado nas configurações do nível atual
local function criarBlocoDoNivel()
    local posicaoIndex = math.random(1, 4)
    local corIndex = math.random(1, 4)
    
    -- Tamanho fixo dos blocos para consistência visual
    local tamanhoMin = 12
    local tamanhoBloco = math.max(tamanhoMin, math.floor(larguraTela / 16))
    
    local bloco = {
        x = nivel.posicoesX[posicaoIndex],
        y = -tamanhoBloco,  -- Começa acima da tela com base no próprio tamanho
        largura = tamanhoBloco,
        altura = tamanhoBloco,
        cor = nivel.cores[corIndex],
        posicaoIndex = posicaoIndex, -- Armazena a posição para facilitar as colisões
        raioCantos = math.floor(tamanhoBloco * 0.2) -- Raio dos cantos arredondados (20% do tamanho)
    }
    
    table.insert(blocos, bloco)
end

-- Verifica colisão entre círculo e retângulo
local function verificarColisao(bloco, jogadorObj)
    -- Encontrar o ponto mais próximo do retângulo ao círculo
    local pontoMaisProximoX = math.max(bloco.x - bloco.largura/2, 
                                      math.min(jogadorObj.x, bloco.x + bloco.largura/2))
    local pontoMaisProximoY = math.max(bloco.y - bloco.altura/2, 
                                      math.min(jogadorObj.y, bloco.y + bloco.altura/2))
    
    -- Calcular a distância entre o ponto mais próximo e o centro do círculo
    local distanciaX = pontoMaisProximoX - jogadorObj.x
    local distanciaY = pontoMaisProximoY - jogadorObj.y
    local distanciaQuadrada = distanciaX * distanciaX + distanciaY * distanciaY
    
    -- Verificar se a distância é menor que o raio do círculo
    return distanciaQuadrada <= (jogadorObj.raio * jogadorObj.raio)
end

-- API Pública do módulo
-------------------------

-- Define o offset (posição) do gameplay na tela
function gameplay.setOffset(x, y)
    offsetX = x
    offsetY = y
end

-- Define o tamanho e dimensões da área de gameplay
function gameplay.setDimensoes(width, height)
    larguraTela = width
    alturaTela = height
    
    -- Se o jogador já existe, atualiza suas posições
    if jogador then
        -- Usa valores fixos de pixel para garantir consistência
        local numPositions = 4  -- Número de posições
        
        -- Calcula espaçamento entre as trilhas
        local spacing = math.floor(larguraTela / 5)
        
        -- Recria array de posições
        jogador.posicoesJogador = {}
        
        -- Distribuição uniforme das posições
        for i = 1, numPositions do
            jogador.posicoesJogador[i] = math.floor(i * spacing)
        end
        
        -- Ajusta posição X atual do jogador
        jogador.x = jogador.posicoesJogador[jogador.posicaoAtual]
        
        -- Define Y a uma distância fixa do fundo
        jogador.y = alturaTela - 40
        
        -- Ajusta raio para garantir tamanho visual consistente
        jogador.raio = math.max(8, math.floor(larguraTela / 20))
    end
    
    -- Se o nível existir, atualiza as posições dos blocos
    if nivel and nivel.posicoesX then
        local numPositions = 4  -- Número de posições
        local spacing = math.floor(larguraTela / 5)
        
        nivel.posicoesX = {}
        for i = 1, numPositions do
            nivel.posicoesX[i] = math.floor(i * spacing)
        end
    end
end

-- Funções para compatibilidade com a API antiga (não usadas, mas mantidas para compatibilidade)
function gameplay.setCentro(x, y) end -- Mantido para compatibilidade, não tem efeito
function gameplay.setRaioCentral(raio) end
function gameplay.setRaioExterno(raio) end
function gameplay.setDistanciaOrigem(dist) end
function gameplay.setVelocidadeSuavizacao(velocidade) end
function gameplay.setTempoAntecipacao(tempo) end
function gameplay.setForcaGravitacional(forca) end
function gameplay.setVelocidadeLaser(velocidade) end
function gameplay.setLarguraArcoEscudo(largura) end
function gameplay.setAnguloEscudo(angulo) end
function gameplay.getAnguloEscudo() return 0 end

-- Carrega uma fase
function gameplay.carregar(fase)
    -- Verifica se precisamos criar os generators
    if not levelCreator then
        local Game = require("game")
        levelCreator = Game.newLevelCreator(larguraTela, alturaTela)
        phaseGenerator = Game.newPhaseGenerator()
    end
    
    -- Configura o novo nível
    nivel = fase
    
    -- Configura as posições dos blocos com pixels fixos
    local numPositions = 4
    local spacing = math.floor(larguraTela / 5)
    
    nivel.posicoesX = {}
    for i = 1, numPositions do
        nivel.posicoesX[i] = math.floor(i * spacing)
    end
    
    -- Configura as cores dos blocos se não estiverem definidas
    if not nivel.cores then
        nivel.cores = {
            {0.92, 0.7, 0.85},  -- Rosa pastel suave
            {0.7, 0.9, 0.8},    -- Verde mint pastel
            {0.7, 0.8, 0.95},   -- Azul céu pastel
            {0.97, 0.9, 0.7}    -- Amarelo pastel suave
        }
    end
    
    -- Inicializa o jogador com posições calculadas com valores fixos
    -- Raio do jogador - tamanho consistente
    local raioJogador = math.max(8, math.floor(larguraTela / 20))
    
    -- Posição Y fixa em relação ao fundo da área de jogo
    local posY = alturaTela - 40
    
    jogador = {
        posicaoAtual = 2, -- Começa na posição 2 (de 1 a 4)
        posicoesJogador = {},
        x = 0, -- Será definido após calcular as posições
        y = posY,
        raio = raioJogador,
        cor = {0.9, 0.85, 0.95} -- Tom de rosa claro pastel
    }
    
    -- Calcula e preenche as posições do jogador
    for i = 1, numPositions do
        jogador.posicoesJogador[i] = math.floor(i * spacing)
    end
    
    -- Define a posição X inicial
    jogador.x = jogador.posicoesJogador[jogador.posicaoAtual]
    
    -- Reset das variáveis de estado
    blocos = {}
    pontos = 0
    tempoUltimoBloco = 0
end

-- Atualiza o estado do jogo
function gameplay.atualizar(dt, anguloEscudoInput)
    -- Ignora o anguloEscudoInput (mantido para compatibilidade)
    
    -- Atualiza a posição X do jogador para corresponder à sua posição atual
    jogador.x = jogador.posicoesJogador[jogador.posicaoAtual]
    
    -- Criar novos blocos baseado no nível
    tempoUltimoBloco = tempoUltimoBloco + dt
    if nivel and tempoUltimoBloco >= nivel.intervalo then
        criarBlocoDoNivel()
        tempoUltimoBloco = 0
    end
    
    -- Atualizar posição dos blocos
    for i = #blocos, 1, -1 do
        local bloco = blocos[i]
        bloco.y = bloco.y + nivel.velocidade * dt
        
        -- Verificar colisão com o jogador
        if verificarColisao(bloco, jogador) then
            table.remove(blocos, i)
            pontos = pontos + 10
        -- Remover blocos que saíram da tela
        elseif bloco.y > alturaTela + bloco.altura/2 then
            table.remove(blocos, i)
        end
    end
    
    -- Retorna nil para compatibilidade (significando que o jogo continua)
    -- Se a fase terminar por algum motivo, retornar "fase_concluida"
    return nil
end

-- Função principal de desenho
function gameplay.desenhar(desenharUI)
    -- Salva o estado atual de transformação
    love.graphics.push()
    
    -- Aplica a transformação para posicionar o gameplay
    love.graphics.translate(offsetX, offsetY)
    
    -- Use a altura passada ou a original
    local alturaReal = alturaTela
    
    -- Fundo semi-transparente para área de jogo (para overlay sobre stage scene)
    love.graphics.setColor(0.97, 0.89, 0.91, 0.85)
    -- Usa um retângulo com cantos arredondados claros
    love.graphics.rectangle("fill", 0, 0, larguraTela, alturaReal, 12, 12)
    
    -- Borda suave para área de jogo
    love.graphics.setColor(0.8, 0.75, 0.8, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 0, larguraTela, alturaReal, 12, 12)
    
    -- Título do jogo na parte superior
    love.graphics.setColor(0.6, 0.5, 0.7, 0.9)
    love.graphics.printf("Rhythm Game", 0, 10, larguraTela, "center")
    
    -- Desenhar "trilhas" para os blocos caírem
    for i, pos in ipairs(jogador.posicoesJogador) do
        -- Largura das trilhas proporcional mas com limites
        local larguraTrilha = math.min(math.max(larguraTela * 0.2, 15), 30)
        
        -- Cor da trilha ajustada para mostrar a posição atual do jogador (mais transparente para overlay)
        if i == jogador.posicaoAtual then
            love.graphics.setColor(0.95, 0.78, 0.85, 0.7) -- Trilha ativa mais brilhante
        else
            love.graphics.setColor(0.93, 0.83, 0.87, 0.5) -- Trilhas inativas
        end
        
        love.graphics.rectangle("fill", 
            pos - larguraTrilha/2, 
            0, 
            larguraTrilha, 
            alturaReal,
            8, 8) -- Trilhas com cantos arredondados
    end
    
    -- Desenhar linha de ação (onde o jogador deve acertar os blocos)
    love.graphics.setColor(0.7, 0.65, 0.75, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, jogador.y, larguraTela, jogador.y)
    
    -- Desenhar blocos com sombras e cantos arredondados
    for _, bloco in ipairs(blocos) do
        -- Desenhar sombra sutilmente deslocada
        love.graphics.setColor(0.7, 0.7, 0.8, 0.4)
        love.graphics.rectangle("fill", 
            bloco.x - bloco.largura/2 + 4, 
            bloco.y - bloco.altura/2 + 4, 
            bloco.largura, 
            bloco.altura,
            bloco.raioCantos, 
            bloco.raioCantos)
        
        -- Desenhar bloco principal com cantos arredondados
        love.graphics.setColor(bloco.cor)
        love.graphics.rectangle("fill", 
            bloco.x - bloco.largura/2, 
            bloco.y - bloco.altura/2, 
            bloco.largura, 
            bloco.altura,
            bloco.raioCantos, 
            bloco.raioCantos)
        
        -- Borda mais definida nos blocos
        love.graphics.setColor(0.6, 0.6, 0.7, 0.9)
        love.graphics.setLineWidth(2)  -- Linha mais espessa
        love.graphics.rectangle("line", 
            bloco.x - bloco.largura/2, 
            bloco.y - bloco.altura/2, 
            bloco.largura, 
            bloco.altura,
            bloco.raioCantos, 
            bloco.raioCantos)
        
        -- Pequeno brilho no canto superior esquerdo do bloco
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", 
            bloco.x - bloco.largura/2 + bloco.raioCantos, 
            bloco.y - bloco.altura/2 + bloco.raioCantos, 
            bloco.raioCantos * 0.5)
    end
    
    -- Desenhar jogador (círculo com efeito de brilho)
    -- Primeiro desenha um círculo maior para o efeito de brilho
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", jogador.x, jogador.y, jogador.raio * 1.2)
    
    -- Círculo principal do jogador
    love.graphics.setColor(0.9, 0.85, 0.95)
    love.graphics.circle("fill", jogador.x, jogador.y, jogador.raio)
    
    -- Borda do jogador
    love.graphics.setColor(0.7, 0.65, 0.75)
    love.graphics.circle("line", jogador.x, jogador.y, jogador.raio)
    
    -- Efeito de luz no jogador (pequeno círculo na parte superior esquerda)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", 
        jogador.x - jogador.raio * 0.3, 
        jogador.y - jogador.raio * 0.3, 
        jogador.raio * 0.2)
    
    -- Se a UI deve ser desenhada pelo módulo (opcional)
    if desenharUI then
        -- Fundo semi-transparente para os textos de UI
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", 5, 5, larguraTela - 10, 60, 8, 8)
        
        -- Desenha a pontuação com melhor visibilidade
        love.graphics.setColor(0.95, 0.95, 1)
        love.graphics.print("Pontuação: " .. pontos, 10, 15)
        
        -- Desenha o nível se disponível
        if nivel and nivel.dificuldade then
            love.graphics.print("Nível: " .. nivel.dificuldade, 10, 35)
        end
    end
    
    -- Restaura o estado de transformação
    love.graphics.pop()
end

-- Obtém a pontuação atual
function gameplay.getPontuacao()
    return pontos
end

-- Obtém o combo atual (mantido para compatibilidade)
function gameplay.getCombo()
    return 0
end

-- Obtém o multiplicador atual (mantido para compatibilidade)
function gameplay.getMultiplicador()
    return 1
end

-- Obtém o tempo decorrido (mantido para compatibilidade)
function gameplay.getTempoDecorrido()
    return 0
end

-- Função para lidar com teclas pressionadas
function gameplay.keypressed(key)
    if key == "left" then
        -- Move para a posição à esquerda ou volta para a última posição
        if jogador.posicaoAtual > 1 then
            jogador.posicaoAtual = jogador.posicaoAtual - 1
        else
            -- Se estiver na posição mais à esquerda, vai para a mais à direita
            jogador.posicaoAtual = #jogador.posicoesJogador
        end
    elseif key == "right" then
        -- Move para a posição à direita ou volta para a primeira posição
        if jogador.posicaoAtual < #jogador.posicoesJogador then
            jogador.posicaoAtual = jogador.posicaoAtual + 1
        else
            -- Se estiver na posição mais à direita, vai para a mais à esquerda
            jogador.posicaoAtual = 1
        end
    end
end

-- Para compatibilidade com código existente
function gameplay.pausar() end
function gameplay.continuar() end
function gameplay.onResize() 
    if nivel then
        gameplay.setDimensoes(larguraTela, alturaTela)
    end
end

-- Retorna o módulo
return gameplay