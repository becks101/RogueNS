-- ExemploDeFase01.lua
-- Exemplo de fase para o jogo de ritmo

local fase = {
    nome = "Tutorial 01",
    bpm = 90,
    duracao = 50,
    
    -- Lista de ângulos que serão usados (em graus)
    angs = {
        A = 180,   -- Direita
        B = 195,   -- Direita-cima
        C = 210,  -- Direita-baixo
        D = 225,    -- Cima
        E = 240,  -- Baixo
        F = 255,    -- Cima
        G = 270,  -- Esquerda (para origem)
    },
    
    -- Sequência de beats mais simples e padronizada
    beats = {"n", "n", "c", "c", "c", "c", "n", "n"},
    
    -- Ângulos alternando apenas entre poucos valores para facilitar
    tangAng = {"G", "G", "G", "G", "G", "G", "G", "G"},
    
    -- Ângulos de origem simples
    originAng = {"A", "C", "E", "G", "E", "C", "A", "C"},
    
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