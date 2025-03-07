-- SS-Mast1.lua
local stageSceneData = {
    nome = "mast02",                   -- Identifica a stage scene
    Icone = "assets/icons/cat4x.png",       -- Imagem de 16x16 para menus/galeria
    IconeLarge = "assets/icons/cat4x.png",  -- Imagem de 32x32 para exibição na galeria
    Efeitos = {
        efeito1 = {
            background = "assets/backgrounds/sofa.jpg",                         -- Imagem de fundo (ocupa 100% da tela)
            intro = "assets/sprites/mast2.png",                       -- Imagem de introdução para a stage scene
            loopSprite = {"assets/sprites/mast01.png","assets/sprites/mast02.png"},  -- Sprites que serão alternados aleatoriamente
            x = 0.4,                                        -- 40% da largura da tela (aplicado aos sprites)
            y = 0.43,                                       -- 43% da altura da tela (aplicado aos sprites)
            totalFrames = 31,                               -- Total de frames na animação
            animationSpeed = 0.02,                          -- Velocidade da animação
            size = 1                                        -- Escala base dos sprites
        }
    }
}

return stageSceneData
