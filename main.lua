-- main.lua
local Config = require "config"
local Menu = require "menu"

function love.resize(w, h)
    -- Notifica o menu sobre o redimensionamento
    if menu then
        if menu.resize then
            menu:resize(w, h)
        end
        
        -- Recarrega o menu apropriado
        if menu.loadMainMenu and menu.currentMenu then
            if menu.currentMenu == "main" then
                menu:loadMainMenu()
            elseif menu.currentMenu == "gallery" then
                menu:loadGalleryMenu()
            elseif menu.currentMenu == "settings" then
                menu:loadSettingsMenu()
            end
        end
    end
end

function love.load()
    -- Carrega as configurações salvas (ex.: fullscreen, volume, etc.)
    Config.load()
    
    -- Centraliza a janela
    local screenWidth, screenHeight = love.window.getDesktopDimensions()
    local windowWidth, windowHeight = 1024, 768
    
    -- Define configurações iniciais da janela
    love.window.setMode(windowWidth, windowHeight, {
        resizable = true,
        vsync = true,
        minwidth = 640,
        minheight = 480,
        fullscreen = Config.settings.fullscreen
    })
    
    -- Centraliza a janela na tela (quando não estiver em fullscreen)
    if not Config.settings.fullscreen then
        love.window.setPosition(
            (screenWidth - windowWidth) / 2,
            (screenHeight - windowHeight) / 2
        )
    end
    
    -- Cria a instância do menu
    menu = Menu.new()
end

-- Função para definir a posição dos círculos para o jogo
-- Esta função permite definir a posição no Main para ter acesso global
function love.setGameCirclePosition(ratioX, ratioY)
    if menu and menu.gameInstance then
        menu.gameInstance:setCirclePosition(ratioX, ratioY)
    end
end

function love.update(dt)
    menu:update(dt)
end

function love.draw()
    menu:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    menu:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    menu:mousereleased(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
    if menu.keypressed then
        menu:keypressed(key)
    end
    
    -- Sair do jogo com Escape
    if key == "escape" and love.keyboard.isDown("lshift") then
        love.event.quit()
    end
    
    -- Alternar fullscreen com Alt+Enter ou F11
    if (key == "return" and love.keyboard.isDown("lalt")) or key == "f11" then
        Config.setFullscreen(not Config.settings.fullscreen)
    end
end

-- Adiciona tratamento para o evento de movimentação do mouse
function love.mousemoved(x, y, dx, dy)
    if menu.mousemoved then
        menu:mousemoved(x, y, dx, dy)
    end
end