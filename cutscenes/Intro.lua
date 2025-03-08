local cutsceneData = {
    nome = "Introdução", -- Nome para exibir na galeria
    IconeLarge = "assets/icons/frog4x.png", -- Ícone na galeria
    background = "assets/backgrounds/sofa.jpg",
    characters = {
        heroi = {
            name = "Herói",
            portrait = "assets/portraits/hero.png"
        },
        mentor = {
            name = "Mentor",
            portrait = "assets/portraits/mentor.png"
        }
    },
    steps = {
        {
            text = "Era uma vez em um reino distante...",
            speaker = nil -- Narrador
        },
        {
            text = "Finalmente chegou o dia do seu treinamento!",
            speaker = "mentor"
        },
        {
            text = "Estou pronto para aprender, mestre.",
            speaker = "heroi",
            sprites = {
                {
                    image = "assets/sprites/mast02.png",
                    x = 0.3,
                    y = 0.5,
                    scale = 1.0,
                    animated = true, -- Ativa animação
                    framesH = 31,     -- 4 frames horizontais
                    framesV = 1,     -- 1 frame vertical (tudo em uma linha)
                    frameDelay = 0.05 -- 150ms entre frames
                }
            }
        }
        -- Outros passos...
    }
}

return cutsceneData
