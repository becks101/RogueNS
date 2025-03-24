-- main.lua
local Config = require "config"
local Menu = require "menu"
local ScreenUtils = require "screen_utils"

-- Handle window resize
function love.resize(w, h)
    -- Update central screen dimensions
    ScreenUtils.updateDimensions(w, h)
    
    -- Notify menu about resizing
    if menu then
        if menu.resize then
            menu:resize(w, h)
        end
        
        -- Reload appropriate menu
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
    -- Initialize screen utilities
    ScreenUtils.init()
    
    -- Load saved configurations
    Config.load()
    
    initializeTestLevelHistoryData()
    -- Set up initial window
    local screenWidth, screenHeight = love.window.getDesktopDimensions()
    local windowWidth, windowHeight = 1024, 768
    
    -- Configure window
    love.window.setMode(windowWidth, windowHeight, {
        resizable = true,
        vsync = true,
        minwidth = 640,
        minheight = 480,
        fullscreen = Config.settings.fullscreen
    })
    
    -- Update screen utils with initial dimensions
    ScreenUtils.updateDimensions(windowWidth, windowHeight)
    
    -- Center window when not in fullscreen
    if not Config.settings.fullscreen then
        love.window.setPosition(
            (screenWidth - windowWidth) / 2,
            (screenHeight - windowHeight) / 2
        )
    end
    
    -- Create menu instance
    menu = Menu.new()
    
    -- Armazenar referência global para que outros módulos possam acessar
    _G.currentMenu = menu
    
    -- Set fallback font with good scaling
    local fontSize = ScreenUtils.scaleFontSize(14)
    local defaultFont = love.graphics.newFont(fontSize)
    love.graphics.setFont(defaultFont)
end

-- Function for setting game circle position (kept for compatibility)
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
    -- Transform coordinates if needed for UI
    local uiX, uiY = ScreenUtils.screenToUICoordinates(x, y)
    menu:mousepressed(uiX, uiY, button)
end

function love.mousereleased(x, y, button)
    -- Transform coordinates if needed for UI
    local uiX, uiY = ScreenUtils.screenToUICoordinates(x, y)
    menu:mousereleased(uiX, uiY, button)
end

function love.keypressed(key, scancode, isrepeat)
    if menu.keypressed then
        menu:keypressed(key)
    end
    
    -- Exit game with Shift+Escape
    if key == "escape" and love.keyboard.isDown("lshift") then
        love.event.quit()
    end
    
    -- Toggle fullscreen with Alt+Enter or F11
    if (key == "return" and love.keyboard.isDown("lalt")) or key == "f11" then
        Config.setFullscreen(not Config.settings.fullscreen)
    end
end

-- Handle mouse movement for hover effects
function love.mousemoved(x, y, dx, dy)
    -- Transform coordinates if needed for UI
    local uiX, uiY = ScreenUtils.screenToUICoordinates(x, y)
    
    if menu.mousemoved then
        menu:mousemoved(uiX, uiY, dx, dy)
    end
end