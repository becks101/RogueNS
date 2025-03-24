-- tutorial.lua
-- Fase tutorial para o jogo de ritmo no novo sistema

local fase = {
    nome = "Tutorial 01",
    
    IconeLarge = "assets/icons/frog4x.png", -- Ícone na galeria
    bpm = 75,      -- Define a velocidade base (beats per minute) mais lenta para tutorial
    duracao = 60,  -- Duração da fase em segundos
    fase_seed = 98765432,  -- Seed usada para geração de padrões
    
    -- Parâmetros específicos do novo sistema
    velocidade = 150,  -- Velocidade de queda dos blocos (mais lento para tutorial)
    intervalo = 1.2,   -- Intervalo entre blocos maior para iniciantes
    dificuldade = 1,   -- Nível de dificuldade
    
    -- Cores customizadas mais vivas para o tutorial
    cores = {
        {1.0, 0.7, 0.9},  -- Rosa mais brilhante
        {0.7, 1.0, 0.8},  -- Verde mais vivo
        {0.7, 0.8, 1.0},  -- Azul mais claro
        {1.0, 0.9, 0.7}   -- Amarelo mais brilhante
    },
    
    -- Animação inicial do tutorial
    animation = "stages/ss_mast01",
    
    -- Achievements do tutorial (mais fáceis)
    achievements = {
        {
            id = "Tutorial Completo",
            condition = "musica_terminada",
            value = true,
            reward_type = "fase",
            reward_value = "exemploDeFase01",
        },
        {
            id = "Primeiros Passos",
            condition = "pontuacao_minima",
            value = 50,
            reward_type = "cutscene",
            reward_value = "cutscenes/chapter1",
        }
    }
}

return fase