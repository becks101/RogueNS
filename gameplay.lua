-- gameplay.lua
-- Módulo que contém toda a lógica do jogo de ritmo

local gameplay = {}

-- Variáveis locais do gameplay
local circuloCentral = nil        -- O círculo vermelho central (alvo a proteger)
local circuloExterno = nil        -- O círculo externo de referência
local circuloOrigem = nil         -- O círculo de onde parte o laser
local escudo = nil                -- O semi-círculo que serve de escudo
local angulo = 0                  -- Ângulo do ponto alvo no círculo externo
local anguloOrigem = 0            -- Ângulo da origem do laser no círculo de origem
local targetAnguloEscudo = 0      -- Ângulo alvo do escudo
local anguloEscudo = 0            -- Ângulo atual do escudo
local centroCirX = 0              -- Centro dos círculos X - agora variável local, inicializada em 0
local centroCirY = 0              -- Centro dos círculos Y - agora variável local, inicializada em 0
local pontoOrigemX = 0            -- Posição X da origem do laser
local pontoOrigemY = 0            -- Posição Y da origem do laser
local pontoAlvoX = 0              -- Posição X do alvo do laser
local pontoAlvoY = 0              -- Posição Y do alvo do laser
local trajetoriaLaser = {}        -- Pontos que formam a trajetória do laser

-- Configurações do laser
local forcaGravitacional = 32000000   -- Força gravitacional para o cálculo da trajetória
local velocidadeLaser = 20            -- Velocidade do laser
local numPontos = 200                 -- Número de pontos para simular a trajetória do laser
local distanciaOrigem = 1450          -- Distância da origem do laser
local RaioCent = 80                   -- Raio do círculo central
local RaioExt = 800                   -- Raio do círculo externo

-- Configurações de UI (você pode ajustar estas variáveis para personalizar a aparência)
local coresBeat = {
    normal = {
        externo = {1, 1, 1, 1},        -- Cor externa do beat normal
        interno = {0, 0, 0, 1}         -- Cor interna do beat normal
    },
    continuo = {1, 1, 1, 1}            -- Cor do beat contínuo
}
local tamanhoBeats = 15                -- Tamanho dos beats
local espessuraBeatContinuo = 2        -- Multiplicador de espessura para beats contínuos
local corLaser = {1, 1, 1, 0.7}        -- Cor do laser
local espessuraLaser = 1.5             -- Espessura da linha do laser
local corCirculoCentral = {1, 0, 0, 1} -- Cor do círculo central
local corCirculoExterno = {0.5, 0.5, 0.5, 0.3} -- Cor do círculo externo
local corCirculoOrigem = {0.3, 0.3, 0.3, 0.2}  -- Cor do círculo de origem
local corEscudo = {1, 1, 1, 0.8}       -- Cor do escudo
local espessuraEscudo = 3              -- Espessura da linha do escudo
local larguraArcoEscudo = 30           -- Largura do arco do escudo em graus
local corOnda = {1, 1, 1, 1}           -- Cor do efeito de onda
local espessuraOnda = 2                -- Espessura da linha da onda
local tamanhoMaximoOnda = 50           -- Tamanho máximo da onda
local velocidadeOnda = 100             -- Velocidade da onda

-- Configuração de suavização
local velocidadeSuavizacaoAngulo = 0.3 -- Fator de suavização para mudanças angulares
local tempoAntecipacaoBeat = 2       -- Quantos beats antes o ângulo começa a mudar para o próximo alvo

-- Configurações do jogo
local velocidadeRotacaoEscudo = 5      -- Velocidade de rotação do escudo
local faseAtual = nil                  -- Fase atual sendo jogada
local tempoDecorrido = 0               -- Tempo decorrido desde o início da fase
local indiceBeat = 1                   -- Índice do beat atual
local proximoBeatTempo = 0             -- Tempo do próximo beat
local beatsAtivos = {}                 -- Lista de beats ativos na tela
local particulas = {}                  -- Lista de partículas para efeitos visuais
local pontuacao = 0                    -- Pontuação do jogador
local multiplicador = 1                -- Multiplicador de pontos
local combo = 0                        -- Combo atual
local anguloLaserAlvo = 0              -- Ângulo alvo do laser
local anguloOrigemAlvo = 0             -- Ângulo alvo da origem
local proximoAnguloLaserAlvo = nil     -- Próximo ângulo alvo do laser (para suavização)
local proximoAnguloOrigemAlvo = nil    -- Próximo ângulo alvo da origem (para suavização)
local tempoProximaMudancaAngulo = 0    -- Tempo para a próxima mudança de ângulo

-- Funções auxiliares
local function criarCirculo(x, y, raio, cor)
    return {
        x = x,
        y = y,
        raio = raio,
        cor = cor,
        
        desenhar = function(self)
            love.graphics.setColor(self.cor)
            love.graphics.circle("fill", self.x, self.y, self.raio)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", self.x, self.y, self.raio)
        end
    }
end

-- Função para converter ângulos do sistema da fase (A=0, G=180) para radianos
local function converterAnguloParaRadianos(anguloLetra, angsTabela)
    if not angsTabela or not angsTabela[anguloLetra] then
        return math.rad(180) -- valor padrão se não for encontrado
    end
    
    return math.rad(angsTabela[anguloLetra])
end

-- Função para suavizar a transição entre dois ângulos (evita saltos bruscos)
local function suavizarAngulos(anguloAtual, anguloAlvo, dt, velocidade)
    -- Normaliza os ângulos para evitar problemas com a transição
    while anguloAtual > math.pi * 2 do anguloAtual = anguloAtual - math.pi * 2 end
    while anguloAtual < 0 do anguloAtual = anguloAtual + math.pi * 2 end
    
    while anguloAlvo > math.pi * 2 do anguloAlvo = anguloAlvo - math.pi * 2 end
    while anguloAlvo < 0 do anguloAlvo = anguloAlvo + math.pi * 2 end
    
    -- Calcula a diferença entre os ângulos
    local diff = anguloAlvo - anguloAtual
    
    -- Ajusta para o caminho mais curto
    if diff > math.pi then
        diff = diff - math.pi * 2
    elseif diff < -math.pi then
        diff = diff + math.pi * 2
    end
    
    -- Aplica a suavização
    return anguloAtual + diff * dt * velocidade
end

-- Atualiza as posições dos pontos de origem e alvo do laser
local function atualizarPosicoes()
    -- Origem do laser (no círculo de origem)
    pontoOrigemX = centroCirX + math.cos(anguloOrigem) * distanciaOrigem
    pontoOrigemY = centroCirY + math.sin(anguloOrigem) * distanciaOrigem
    
    -- Alvo do laser (no círculo externo)
    pontoAlvoX = centroCirX + math.cos(angulo) * RaioExt
    pontoAlvoY = centroCirY + math.sin(angulo) * RaioExt
end

-- Calcula a trajetória do laser com efeito gravitacional
local function calcularTrajetoriaLaser()
    local pontos = {}
    
    -- Adiciona o ponto inicial
    table.insert(pontos, {x = pontoOrigemX, y = pontoOrigemY})
    
    -- Direção inicial do laser (normalizada)
    local dirX = pontoAlvoX - pontoOrigemX
    local dirY = pontoAlvoY - pontoOrigemY
    local comprimento = math.sqrt(dirX*dirX + dirY*dirY)
    
    if comprimento > 0 then
        dirX = dirX / comprimento
        dirY = dirY / comprimento
    else
        dirX = 1
        dirY = 0
    end
    
    -- Velocidade inicial do laser
    local velX = dirX * velocidadeLaser
    local velY = dirY * velocidadeLaser
    
    -- Posição atual
    local posX = pontoOrigemX
    local posY = pontoOrigemY
    
    -- Simula o movimento do laser com influência gravitacional
    for i = 1, numPontos do
        -- Calcula a distância ao centro gravitacional
        local dx = centroCirX - posX
        local dy = centroCirY - posY
        local distSqr = dx*dx + dy*dy
        
        -- Evita divisão por zero
        if distSqr < 10 then
            break
        end
        
        -- Força gravitacional inversamente proporcional ao quadrado da distância
        local dist = math.sqrt(distSqr)
        local forca = forcaGravitacional / distSqr
        
        -- Direção da força gravitacional (normalizada)
        local forcaDirX = dx / dist
        local forcaDirY = dy / dist
        
        -- Aplica a força à velocidade
        velX = velX + forcaDirX * forca * 0.01
        velY = velY + forcaDirY * forca * 0.01
        
        -- Normaliza a velocidade para manter o comprimento constante
        local velComprimento = math.sqrt(velX*velX + velY*velY)
        if velComprimento > 0 then
            velX = velX / velComprimento * velocidadeLaser
            velY = velY / velComprimento * velocidadeLaser
        end
        
        -- Atualiza a posição
        posX = posX + velX
        posY = posY + velY
        
        -- Adiciona o ponto à trajetória
        table.insert(pontos, {x = posX, y = posY})
        
        -- Verifica se chegou ao centro
        if dist < RaioCent then  -- Agora usando o raio central configurável
            break
        end
    end
    
    return pontos
end

-- Pré-planeja os próximos ângulos com base no indiceBeat atual
local function planejarProximosAngulos()
    if not faseAtual then return end
    
    local proximoIndice = indiceBeat + 1
    if proximoIndice <= #faseAtual.beats then
        -- Pré-calcula o próximo ângulo alvo para o laser
        if faseAtual.tangAng and faseAtual.tangAng[proximoIndice] and faseAtual.angs[faseAtual.tangAng[proximoIndice]] then
            proximoAnguloLaserAlvo = math.rad(faseAtual.angs[faseAtual.tangAng[proximoIndice]])
        end
        
        -- Pré-calcula o próximo ângulo alvo para a origem
        if faseAtual.originAng and faseAtual.originAng[proximoIndice] and faseAtual.angs[faseAtual.originAng[proximoIndice]] then
            proximoAnguloOrigemAlvo = math.rad(faseAtual.angs[faseAtual.originAng[proximoIndice]])
        end
    end
end

-- Declaração antecipada de criarOnda (para resolver referência circular)
local criarOnda

-- Cria um novo beat
local function criarBeat(tipo, posicaoNaTrajetoria)
    local beat = {
        tipo = tipo,                          -- "normal" ou "continuo"
        posicaoNaTrajetoria = posicaoNaTrajetoria or 0, -- 0 a 1, onde está na trajetória
        tamanho = tamanhoBeats,               -- Tamanho do beat (configurável)
        ativo = true,                         -- Se o beat está ativo
        acertado = false,                     -- Se o beat foi acertado
        desenhar = function(self)
            if not self.ativo then return end
            
            -- Calcula a posição atual na trajetória
            local indice = math.floor(self.posicaoNaTrajetoria * (#trajetoriaLaser - 1)) + 1
            indice = math.min(indice, #trajetoriaLaser)
            
            if self.tipo == "normal" then
                -- Beat normal é um círculo
                love.graphics.setColor(coresBeat.normal.externo)
                love.graphics.circle("fill", trajetoriaLaser[indice].x, trajetoriaLaser[indice].y, self.tamanho)
                love.graphics.setColor(coresBeat.normal.interno)
                love.graphics.circle("fill", trajetoriaLaser[indice].x, trajetoriaLaser[indice].y, self.tamanho - 2)
            else
                -- Beat contínuo é uma linha grossa
                local indiceInicio = indice
                local indiceFim = math.min(indice + 10, #trajetoriaLaser)
                
                love.graphics.setColor(coresBeat.continuo)
                love.graphics.setLineWidth(self.tamanho * espessuraBeatContinuo)
                
                for i = indiceInicio, indiceFim - 1 do
                    love.graphics.line(
                        trajetoriaLaser[i].x, 
                        trajetoriaLaser[i].y, 
                        trajetoriaLaser[i+1].x, 
                        trajetoriaLaser[i+1].y
                    )
                end
            end
        end,

        atualizar = function(self, dt)
            if not self.ativo then return end
            
            -- Avança na trajetória
            self.posicaoNaTrajetoria = self.posicaoNaTrajetoria + dt * 0.5
            
            -- Verifica se chegou ao centro
            if self.posicaoNaTrajetoria >= 0.9 then
                -- Verifica colisão com o escudo
                local indice = math.floor(self.posicaoNaTrajetoria * (#trajetoriaLaser - 1)) + 1
                indice = math.min(indice, #trajetoriaLaser)
                
                local posX = trajetoriaLaser[indice].x
                local posY = trajetoriaLaser[indice].y
                
                -- Calcula ângulo em relação ao centro
                local dx = posX - centroCirX
                local dy = posY - centroCirY
                local anguloBeat = math.atan2(dy, dx)
                
                -- Converte para graus
                local anguloGraus = anguloBeat * 180 / math.pi
                if anguloGraus < 0 then anguloGraus = anguloGraus + 360 end
                
                -- Verifica se o escudo está na posição correta (com margem de erro)
                local margemErro = 20
                local diferencaAngulo = math.abs(anguloGraus - anguloEscudo)
                if diferencaAngulo > 180 then 
                    diferencaAngulo = 360 - diferencaAngulo
                end
                
                if diferencaAngulo <= margemErro then
                    -- Acertou!
                    if not self.acertado then
                        self.acertado = true
                        pontuacao = pontuacao + 100 * multiplicador
                        combo = combo + 1
                        if combo % 10 == 0 then
                            multiplicador = multiplicador + 1
                        end
                        
                        -- Cria efeito de partículas
                        criarOnda(posX, posY)
                    end
                else if self.posicaoNaTrajetoria >= 0.95 then
                    -- Errou!
                    self.ativo = false
                    combo = 0
                    multiplicador = 1
                end
                end
            end
            
            if self.posicaoNaTrajetoria >= 1 then
                self.ativo = false
            end
        end
    } 
    return beat
end

-- Cria um efeito de onda quando um beat é acertado
criarOnda = function(x, y)
    local onda = {
        x = x,
        y = y,
        raio = 5,
        maxRaio = tamanhoMaximoOnda,
        velocidade = velocidadeOnda,
        alpha = 1,
        atualizar = function(self, dt)
            self.raio = self.raio + self.velocidade * dt
            self.alpha = 1 - (self.raio / self.maxRaio)
            
            if self.raio >= self.maxRaio then
                return false -- Remove a partícula
            end
            return true
        end,
        desenhar = function(self)
            love.graphics.setColor(corOnda[1], corOnda[2], corOnda[3], self.alpha)
            love.graphics.setLineWidth(espessuraOnda)
            love.graphics.circle("line", self.x, self.y, self.raio)
        end
    }
    
    table.insert(particulas, onda)
end

-- Funções exportadas do módulo
-------------------------------

-- Define o centro dos círculos (posicionamento do jogo na tela)
function gameplay.setCentro(x, y)
    centroCirX = x
    centroCirY = y
    
    -- Atualiza o círculo de origem visível também
    if circuloOrigem then
        circuloOrigem.x = x
        circuloOrigem.y = y
    end
    
    -- Atualiza o círculo central
    if circuloCentral then
        circuloCentral.x = x
        circuloCentral.y = y
    end
    
    -- Atualiza o círculo externo
    if circuloExterno then
        circuloExterno.x = x
        circuloExterno.y = y
    end
    
    -- Atualiza o escudo
    if escudo then
        escudo.x = x
        escudo.y = y
    end
end

-- Define a distância da origem do laser
function gameplay.setDistanciaOrigem(dist)
    distanciaOrigem = dist
    -- Atualiza o círculo de origem visível também
    if circuloOrigem then
        circuloOrigem.raio = dist
    end
end

-- Define o raio do círculo central
function gameplay.setRaioCentral(raio)
    RaioCent = raio
    if circuloCentral then
        circuloCentral.raio = raio
    end
end

-- Define o raio do círculo externo
function gameplay.setRaioExterno(raio)
    RaioExt = raio
    if circuloExterno then
        circuloExterno.raio = raio
    end
end

-- Define a velocidade de suavização do laser
function gameplay.setVelocidadeSuavizacao(velocidade)
    velocidadeSuavizacaoAngulo = velocidade
end

-- Define o tempo de antecipação do beat
function gameplay.setTempoAntecipacao(tempo)
    tempoAntecipacaoBeat = tempo
end

-- Define a força gravitacional
function gameplay.setForcaGravitacional(forca)
    forcaGravitacional = forca
end

-- Define a velocidade do laser
function gameplay.setVelocidadeLaser(velocidade)
    velocidadeLaser = velocidade
end

-- Define a largura do arco do escudo
function gameplay.setLarguraArcoEscudo(largura)
    larguraArcoEscudo = largura
    if escudo then
        escudo.larguraArco = largura
    end
end

-- Define o ângulo do escudo
function gameplay.setAnguloEscudo(angulo)
    targetAnguloEscudo = angulo
end

-- Obtém o ângulo atual do escudo
function gameplay.getAnguloEscudo()
    return anguloEscudo
end

-- Obtém a pontuação atual
function gameplay.getPontuacao()
    return pontuacao
end

-- Obtém o combo atual
function gameplay.getCombo()
    return combo
end

-- Obtém o multiplicador atual
function gameplay.getMultiplicador()
    return multiplicador
end

-- Obtém o tempo restante da fase
function gameplay.getTempoRestante()
    if faseAtual and faseAtual.duracao then
        return math.max(0, faseAtual.duracao - tempoDecorrido)
    end
    return 0
end

-- Obtém o nome da fase atual
function gameplay.getNomeFase()
    if faseAtual then
        return faseAtual.nome
    end
    return ""
end

function gameplay.onResize()
    if not faseAtual then return end
    
    -- Recarrega a fase para recalcular todos os parâmetros baseados no novo tamanho da tela
    gameplay.carregar(faseAtual)
end

-- Carrega uma fase
function gameplay.carregar(fase)
    faseAtual = fase
    
    -- Obtém as dimensões da tela para posicionamento responsivo
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Define valores padrão que funcionam bem em diferentes resoluções
    local defaultRaioCentral = screenWidth * 0.05  -- 5% da largura da tela
    local defaultRaioExterno = screenWidth * 0.25  -- 25% da largura da tela
    local defaultDistanciaOrigem = screenWidth * 1.5  -- 50% da largura da tela
    
    -- Posição central (por padrão é o centro da tela)
    centroCirX = screenWidth * 0.98
    centroCirY = screenHeight * 0.98
    
    -- Usa valores da fase se fornecidos, senão usa os padrões
    RaioCent = fase.raioCentral or defaultRaioCentral
    RaioExt = fase.raioExterno or defaultRaioExterno
    distanciaOrigem = fase.distanciaOrigem or defaultDistanciaOrigem
    
    -- Criação dos círculos com os valores definidos
    circuloCentral = criarCirculo(centroCirX, centroCirY, RaioCent, corCirculoCentral)        -- Círculo central vermelho
    circuloExterno = criarCirculo(centroCirX, centroCirY, RaioExt, corCirculoExterno)         -- Círculo externo cinza
    circuloOrigem = criarCirculo(centroCirX, centroCirY, distanciaOrigem, corCirculoOrigem)   -- Círculo de origem do laser
    
    -- Criação do escudo (semi-círculo)
    escudo = {
        x = centroCirX,
        y = centroCirY,
        raio = RaioCent + 60,  -- O escudo é ligeiramente maior que o círculo central
        angulo = 180, -- Inicializa em 180 graus (ajustado para o novo sistema)
        larguraArco = larguraArcoEscudo, -- Largura do arco em graus
        desenhar = function(self)
            -- Desenha o semi-círculo do escudo
            love.graphics.setColor(corEscudo)
            local anguloInicio = math.rad(self.angulo - self.larguraArco / 2)
            local anguloFim = math.rad(self.angulo + self.larguraArco / 2)
            love.graphics.setLineWidth(espessuraEscudo)
            love.graphics.arc("line", "open", self.x, self.y, self.raio, anguloInicio, anguloFim, 30)
        end
    }
    
    -- Configura o tempo inicial da fase
    tempoDecorrido = 0
    indiceBeat = 1
    proximoBeatTempo = 0
    beatsAtivos = {}
    particulas = {}
    pontuacao = 0
    multiplicador = 1
    combo = 0
    
    -- Reset dos próximos ângulos
    proximoAnguloLaserAlvo = nil
    proximoAnguloOrigemAlvo = nil
    
    -- Inicializa os ângulos com base na fase
    if faseAtual and faseAtual.angs and faseAtual.tangAng and faseAtual.tangAng[1] then
        local primeiroAngTangente = faseAtual.angs[faseAtual.tangAng[1]] or 180 -- Padrão é 180 (letra A)
        anguloLaserAlvo = math.rad(primeiroAngTangente)
        angulo = anguloLaserAlvo
    else
        anguloLaserAlvo = math.rad(180) -- Padrão é 180 (letra A)
        angulo = anguloLaserAlvo
    end
    
    if faseAtual and faseAtual.angs and faseAtual.originAng and faseAtual.originAng[1] then
        local primeiroAngOrigem = faseAtual.angs[faseAtual.originAng[1]] or 270 -- Qualquer valor padrão
        anguloOrigemAlvo = math.rad(primeiroAngOrigem)
        anguloOrigem = anguloOrigemAlvo
    else
        anguloOrigemAlvo = math.rad(270) -- Valor padrão
        anguloOrigem = anguloOrigemAlvo
    end
    
    -- Inicializa o ângulo do escudo
    targetAnguloEscudo = 180 -- Começa em 180 graus (ajustado para o novo sistema)
    anguloEscudo = 180
    
    -- Planeja os próximos ângulos
    planejarProximosAngulos()
    
    -- Calcula as posições iniciais
    atualizarPosicoes()
    trajetoriaLaser = calcularTrajetoriaLaser()
end
-- Função principal de atualização
function gameplay.atualizar(dt, anguloEscudoInput)
    tempoDecorrido = tempoDecorrido + dt
    
    -- Atualiza os ângulos suavemente para os alvos usando a função de suavização
    angulo = suavizarAngulos(angulo, anguloLaserAlvo, dt, velocidadeSuavizacaoAngulo)
    anguloOrigem = suavizarAngulos(anguloOrigem, anguloOrigemAlvo, dt, velocidadeSuavizacaoAngulo)
    
    -- Verifica se estamos próximos da próxima batida e devemos começar a transição suave
    if faseAtual and faseAtual.bpm and proximoAnguloLaserAlvo and proximoAnguloOrigemAlvo then
        local tempoEntreBatidas = 60 / faseAtual.bpm
        local tempoParaProximoBeat = proximoBeatTempo - tempoDecorrido
        
        -- Se estamos no intervalo de antecipação, começamos a transitar para o próximo ângulo
        if tempoParaProximoBeat <= tempoEntreBatidas / tempoAntecipacaoBeat then
            -- Mistura gradual entre o ângulo atual e o próximo
            local progresso = 1 - (tempoParaProximoBeat / (tempoEntreBatidas / tempoAntecipacaoBeat))
            progresso = math.min(1, progresso) -- Garantir que não exceda 1
            
            -- Atualiza os ângulos alvo para uma posição intermediária
            anguloLaserAlvo = suavizarAngulos(anguloLaserAlvo, proximoAnguloLaserAlvo, progresso, 0.2)
            anguloOrigemAlvo = suavizarAngulos(anguloOrigemAlvo, proximoAnguloOrigemAlvo, progresso, 0.2)
        end
    end
    
    -- Atualiza o ângulo do escudo com base no input externo (se fornecido)
    if anguloEscudoInput then
        targetAnguloEscudo = anguloEscudoInput
        -- Limita o ângulo do escudo entre 180 e 270 graus (ajustado para o novo sistema)
        targetAnguloEscudo = math.max(180, math.min(270, targetAnguloEscudo))
    end
    
    -- Suaviza a movimentação do escudo
    anguloEscudo = anguloEscudo + (targetAnguloEscudo - anguloEscudo) * dt * 10
    escudo.angulo = anguloEscudo
    
    -- Verifica se é hora de criar um novo beat
    if faseAtual and faseAtual.bpm and indiceBeat <= #faseAtual.beats then
        local tempoEntreBatidas = 60 / faseAtual.bpm
        
        if tempoDecorrido >= proximoBeatTempo then
            -- Cria um novo beat
            local tipoBeat = faseAtual.beats[indiceBeat]
            if tipoBeat == "n" then
                table.insert(beatsAtivos, criarBeat("normal", 0))
            elseif tipoBeat == "c" then
                table.insert(beatsAtivos, criarBeat("continuo", 0))
            end
            
            -- Atualiza o índice do beat e o tempo do próximo
            indiceBeat = indiceBeat + 1
            proximoBeatTempo = proximoBeatTempo + tempoEntreBatidas
            
            -- Atualiza os ângulos alvo para os atuais
            if faseAtual.tangAng and faseAtual.tangAng[indiceBeat] and faseAtual.angs[faseAtual.tangAng[indiceBeat]] then
                anguloLaserAlvo = math.rad(faseAtual.angs[faseAtual.tangAng[indiceBeat]])
            end
            
            if faseAtual.originAng and faseAtual.originAng[indiceBeat] and faseAtual.angs[faseAtual.originAng[indiceBeat]] then
                anguloOrigemAlvo = math.rad(faseAtual.angs[faseAtual.originAng[indiceBeat]])
            end
            
            -- Planeja os próximos ângulos
            planejarProximosAngulos()
        end
    end
    
    -- Atualiza as posições dos pontos
    atualizarPosicoes()
    
    -- Recalcula a trajetória do laser
    trajetoriaLaser = calcularTrajetoriaLaser()
    
    -- Atualiza os beats ativos
    for i = #beatsAtivos, 1, -1 do
        local beat = beatsAtivos[i]
        beat:atualizar(dt)
        
        if not beat.ativo then
            table.remove(beatsAtivos, i)
        end
    end
    
    -- Atualiza as partículas
    for i = #particulas, 1, -1 do
        local particula = particulas[i]
        local ativa = particula:atualizar(dt)
        
        if not ativa then
            table.remove(particulas, i)
        end
    end
    
    -- Verifica se a fase acabou
    if faseAtual and faseAtual.duracao and tempoDecorrido >= faseAtual.duracao and #beatsAtivos == 0 then
        -- A fase acabou, apenas sinaliza que acabou (não reinicia automaticamente)
        return "fase_concluida"
    end
    
    return nil -- Retorna nil se nada especial aconteceu
end

-- Função principal de desenho
function gameplay.desenhar(desenharUI)
    -- Desenha os círculos
    circuloExterno:desenhar()
    circuloCentral:desenhar()
    
    -- Desenha o círculo de origem do laser
    circuloOrigem:desenhar()
    
    -- Desenha o raio laser
    love.graphics.setColor(corLaser)
    love.graphics.setLineWidth(espessuraLaser)
    for i = 1, #trajetoriaLaser - 1 do
        love.graphics.line(
            trajetoriaLaser[i].x, 
            trajetoriaLaser[i].y, 
            trajetoriaLaser[i+1].x, 
            trajetoriaLaser[i+1].y
        )
    end
    
    -- Desenha o escudo
    escudo:desenhar()
    
    -- Desenha os beats
    for _, beat in ipairs(beatsAtivos) do
        beat:desenhar()
    end
    
    -- Desenha as partículas
    for _, particula in ipairs(particulas) do
        particula:desenhar()
    end
    
    -- Se a UI deve ser desenhada pelo módulo (opcional)
    if desenharUI then
        -- Desenha a pontuação e o combo
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Pontuação: " .. pontuacao, 10, 10)
        love.graphics.print("Combo: " .. combo .. "x", 10, 30)
        love.graphics.print("Multiplicador: " .. multiplicador .. "x", 10, 50)
        
        -- Desenha o tempo
        if faseAtual and faseAtual.duracao then
            local tempoRestante = math.max(0, faseAtual.duracao - tempoDecorrido)
            love.graphics.print("Tempo: " .. string.format("%.1f", tempoRestante), 10, 70)
        end
        
        -- Desenha o nome da fase
        if faseAtual and faseAtual.nome then
            love.graphics.print(faseAtual.nome, 10, 90)
        end
        
        -- Desenha instruções de controle
        local screenWidth, screenHeight = love.graphics.getDimensions()
        love.graphics.print("Controles: ← → para mover o escudo", screenWidth - 280, screenHeight - 30)
    end
end

-- Personalização de cores e estilos
function gameplay.setEstilo(config)
    if config.coresBeat then
        coresBeat = config.coresBeat
    end
    if config.tamanhoBeats then
        tamanhoBeats = config.tamanhoBeats
    end
    if config.espessuraBeatContinuo then
        espessuraBeatContinuo = config.espessuraBeatContinuo
    end
    if config.corLaser then
        corLaser = config.corLaser
    end
    if config.espessuraLaser then
        espessuraLaser = config.espessuraLaser
    end
    if config.corCirculoCentral then
        corCirculoCentral = config.corCirculoCentral
        if circuloCentral then
            circuloCentral.cor = config.corCirculoCentral
        end
    end
    if config.corCirculoExterno then
        corCirculoExterno = config.corCirculoExterno
        if circuloExterno then
            circuloExterno.cor = config.corCirculoExterno
        end
    end
    if config.corCirculoOrigem then
        corCirculoOrigem = config.corCirculoOrigem
        if circuloOrigem then
            circuloOrigem.cor = config.corCirculoOrigem
        end
    end
    if config.corEscudo then
        corEscudo = config.corEscudo
    end
    if config.espessuraEscudo then
        espessuraEscudo = config.espessuraEscudo
    end
    if config.corOnda then
        corOnda = config.corOnda
    end
    if config.espessuraOnda then
        espessuraOnda = config.espessuraOnda
    end
    if config.tamanhoMaximoOnda then
        tamanhoMaximoOnda = config.tamanhoMaximoOnda
    end
    if config.velocidadeOnda then
        velocidadeOnda = config.velocidadeOnda
    end
end

-- Retorna a lista de beats ativos (útil para debugging ou visualização externa)
function gameplay.getBeatsAtivos()
    return beatsAtivos
end

-- Retorna a trajetória atual do laser (útil para debugging ou visualização externa)
function gameplay.getTrajetoriaLaser()
    return trajetoriaLaser
end

-- Verifica se a fase foi carregada
function gameplay.isFaseCarregada()
    return faseAtual ~= nil
end

-- Define uma função de callback para quando um beat é acertado (opcional)
local callbackBeatAcertado = nil
function gameplay.setCallbackBeatAcertado(callback)
    callbackBeatAcertado = callback
end

-- Define uma função de callback para quando um beat é errado (opcional)
local callbackBeatErrado = nil
function gameplay.setCallbackBeatErrado(callback)
    callbackBeatErrado = callback
end

-- Reseta o jogo
function gameplay.resetar()
    if faseAtual then
        gameplay.carregar(faseAtual)
    end
end

-- Pausa o jogo
function gameplay.pausar()
    -- Implementação opcional para pausar o jogo
    -- Por enquanto, não faz nada, você pode implementar conforme necessário
end

-- Continua o jogo
function gameplay.continuar()
    -- Implementação opcional para continuar o jogo após pausa
    -- Por enquanto, não faz nada, você pode implementar conforme necessário
end

-- Finaliza o módulo (libera recursos, etc.)
function gameplay.finalizar()
    -- Código para limpar/finalizar o módulo
    faseAtual = nil
    beatsAtivos = {}
    particulas = {}
end

-- Retorna coordenadas atuais do centro
function gameplay.getCentro()
    return centroCirX, centroCirY
end

return gameplay