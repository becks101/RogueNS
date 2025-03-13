-- ExemploDeFase01.lua
-- Exemplo de fase para o jogo de ritmo no novo sistema

local fase = {
    nome = "Tutorial 01",
    bpm = 90,      -- Define a velocidade base (beats per minute)
    duracao = 50,  -- Duração da fase em segundos
    fase_seed = 13312212,  -- Seed usada para geração de padrões
    
    -- Parâmetros específicos do novo sistema
    velocidade = 180,  -- Velocidade de queda dos blocos
    intervalo = 0.7,   -- Intervalo entre blocos em segundos
    dificuldade = 1,   -- Nível de dificuldade
    
    -- Cores customizadas (opcional)
    cores = {
        {0.92, 0.7, 0.85},  -- Rosa pastel suave
        {0.7, 0.9, 0.8},    -- Verde mint pastel
        {0.7, 0.8, 0.95},   -- Azul céu pastel
        {0.97, 0.9, 0.7}    -- Amarelo pastel suave
    },
    
    -- Animação inicial do tutorial
    animation = "stages/ss_mast01",
    
    -- Achievements do tutorial (mais fáceis)
    achievements = {
        {
            id = "Primeira Fase Completa",
            condition = "musica_terminada",
            value = true,
            reward_type = "fase",
            reward_value = "exemploDeFase01",
        },
        {
            id = "Primeiros Passos",
            condition = "combo_maximo",
            value = 3,
            reward_type = "cutscene",
            reward_value = "cutscenes/chapter1",
        },
        {
            id = "nova_animacao",
            condition = "pontuacao_minima",
            value = 100,
            reward_type = "stage_scene",
            reward_value = "stages/ss_mast02",
            real_time_check = true
        }
    }
}

return fase