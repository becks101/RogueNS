-- SS-Mast1.lua
local stageSceneData = {
    nome = "mast03",                   -- Identifica a stage scene
    Icone = "mast01_icon_16.png",       -- Imagem de 16x16 para menus/galeria
    IconeLarge = "mast01_icon_32.png",  -- Imagem de 32x32 para exibição na galeria
    Efeitos = {
        efeito1 = {
            background = "BG1.png",                         -- Imagem de fundo (ocupa 100% da tela)
            intro = "mast01_intro.png",                       -- Imagem de introdução para a stage scene
            loopSprite = {"mast01.png", "mast02.png", "mast03.png"},  -- Sprites que serão alternados aleatoriamente
            x = 0.4,                                        -- 40% da largura da tela (aplicado aos sprites)
            y = 0.43,                                       -- 43% da altura da tela (aplicado aos sprites)
            totalFrames = 31,                               -- Total de frames na animação
            animationSpeed = 0.04,                          -- Velocidade da animação
            size = 2                                        -- Escala base dos sprites
        }
    }
}

return stageSceneData
