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
    
    -- Ângulos da tangente por tempo (controla a rota do laser)
    tangAng = {
        "A", "A", "A", "C", "C", 
        "C", "A", "A", "A", "A", 
        "C", "C", "C", "C", "C", 
        "B", "B", "B", "B", "B"
    },
    
    -- Ângulos da origem por tempo
    originAng = {
        "G", "F", "G", "E", "G", 
        "A", "G", "F", "A", "G", 
        "E", "G", "F", "G", "E", 
        "A", "F", "G", "A", "G"
    },
    
    -- Sequência de beats (n = normal, c = contínuo)
    beats = {
        "n", "n", "n", "c", "c", 
        "c", "n", "c", "c", "c", 
        "n", "c", "c", "c", "n", 
        "c", "c", "c", "n", "n"
    },
    animation = "stages/ss_mast01",
    
    -- Novo: lista de achievements possíveis
    achievements = {
        {
            id = "Nível 2",
            condition = "combo_maximo",
            value = 5,
            reward_type = "fase",
            reward_value = "nivel2",
        },
        {
            id = "mast_branch02",
            condition = "combo_maximo",
            value = 5,
            reward_type = "stage_scene",
            reward_value = "mast_branch02",
            real_time_check = true
        },
        {
            id = "Introdução",
            condition = "musica_terminada",
            value = true,
            reward_type = "cutscene",
            reward_value = "cutscenes/intro",
        },
        {
            id = "Pontuação Alta",
            condition = "pontuacao_minima",
            value = 1000,
            reward_type = "cutscene",
            reward_value = "cutscenes/high_score",
        }
    }
}

return fase
