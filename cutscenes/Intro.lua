-- cutscenes/intro.lua
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
        -- Passos iniciais da introdução
        {
            text = "Era uma vez em um reino distante...",
            speaker = nil -- Narrador
        },
        {
            text = "Um jovem herói começando sua jornada em busca de aventura.",
            speaker = nil
        },
        {
            text = "Finalmente chegou o dia do seu treinamento!",
            speaker = "mentor",
            sprites = {
                {
                    image = "assets/sprites/mast02.png",
                    x = 0.7,
                    y = 0.5,
                    scale = 1.0
                }
            }
        },
        {
            text = "Estou pronto para aprender, mestre. Como devemos começar?",
            speaker = "heroi",
            sprites = {
                {
                    image = "assets/sprites/mast01.png",
                    x = 0.3,
                    y = 0.5,
                    scale = 1.0
                },
                {
                    image = "assets/sprites/mast02.png",
                    x = 0.7,
                    y = 0.5,
                    scale = 1.0
                }
            }
        },
        {
            text = "Existem vários caminhos para começar. Você deve escolher o que melhor se adequa ao seu estilo.",
            speaker = "mentor"
        },
        -- Passo com as escolhas para o jogador
        {
            text = "Qual caminho você deseja seguir?",
            speaker = "mentor",
            choices = {
                {
                    text = "Treinamento Básico (Tutorial)",
                    action = "startLevel",
                    levelPath = "levels/tutorial",
                    nextStep = 7 -- Vai para o próximo passo antes de iniciar a fase
                },
                {
                    text = "Já tenho experiência (Pular tutorial)",
                    action = "startLevel",
                    levelPath = "levels/exemploDeFase01",
                    nextStep = 8 -- Vai para outro passo antes de iniciar a fase
                },
                {
                    text = "Preciso pensar mais (Voltar ao menu)",
                    nextStep = 9 -- Vai para o passo que finaliza a cutscene
                }
            }
        },
        -- Passo que confirma a escolha do tutorial
        {
            text = "Sábio! Vamos começar pelo básico para construir uma base sólida.",
            speaker = "mentor",
            action = "startLevel",
            levelPath = "levels/tutorial"
        },
        -- Passo que confirma a escolha de pular o tutorial
        {
            text = "Corajoso! Saltando diretamente para o verdadeiro desafio.",
            speaker = "mentor",
            action = "startLevel",
            levelPath = "levels/exemploDeFase01"
        },
        -- Passo que finaliza a cutscene e retorna ao menu
        {
            text = "Volte quando estiver pronto para começar sua jornada.",
            speaker = "mentor"
        }
    }
}

return cutsceneData