local cutsceneData = {
    nome = "tuto", -- Nome para exibir na galeria
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
            speaker = nil, -- Narrador
            sprites = {
                {
                    image = "assets/sprites/mast02.png",
                    x = 0.3,
                    y = 0.5,
                    scale = 1
                },
                {
                    image = "assets/sprites/mast01.png",
                    x = 0.7,
                    y = 0.5,
                    scale = 1
                }
            }
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
                    scale = 1
                },
                {
                    image = "assets/sprites/mast01.png",
                    x = 0.7,
                    y = 0.5,
                    scale = 1
                }
            }
        }
        -- Outros passos...
    }
}

return cutsceneData