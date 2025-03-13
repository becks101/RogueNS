-- screen_utils.lua
--[[
    Utility module for managing screen dimensions, scaling, and responsive positioning.
    Provides a centralized way to handle screen dimensions across all game modules.
]]

local ScreenUtils = {}

-- Current screen dimensions
ScreenUtils.width = 800
ScreenUtils.height = 600
ScreenUtils.scale = 1
ScreenUtils.baseWidth = 800 -- Base dimensions for reference
ScreenUtils.baseHeight = 600
ScreenUtils.aspectRatio = ScreenUtils.width / ScreenUtils.height

-- Initialize on first load
function ScreenUtils.init()
    local width, height = love.graphics.getDimensions()
    ScreenUtils.updateDimensions(width, height)
end

-- Update dimensions when screen size changes
function ScreenUtils.updateDimensions(width, height)
    ScreenUtils.width = width
    ScreenUtils.height = height
    ScreenUtils.aspectRatio = width / height
    
    -- Calculate a global scale factor based on height
    ScreenUtils.scale = height / ScreenUtils.baseHeight
    
    -- Broadcast dimension change to all listeners
    if ScreenUtils.onDimensionsChanged then
        ScreenUtils.onDimensionsChanged(width, height, ScreenUtils.scale)
    end
end

-- Convert percentage to actual screen coordinates
function ScreenUtils.relativeToScreen(percentX, percentY)
    return percentX * ScreenUtils.width, percentY * ScreenUtils.height
end

-- Scale a value based on screen height
function ScreenUtils.scaleValue(value)
    return value * ScreenUtils.scale
end

-- Calculate a font size that scales with screen
function ScreenUtils.scaleFontSize(baseSize)
    -- Minimum size to maintain readability
    local minSize = 8
    return math.max(minSize, math.floor(baseSize * ScreenUtils.scale))
end

-- Get a good UI element size based on screen dimensions
function ScreenUtils.getUIElementSize(baseWidth, baseHeight)
    -- Scale for responsive sizing but maintain minimum sizes
    local minWidth, minHeight = 50, 20
    
    local scaledWidth = math.max(minWidth, math.floor(baseWidth * ScreenUtils.scale))
    local scaledHeight = math.max(minHeight, math.floor(baseHeight * ScreenUtils.scale))
    
    return scaledWidth, scaledHeight
end

-- Keep a position within screen bounds
function ScreenUtils.clampToScreen(x, y, width, height)
    width = width or 0
    height = height or 0
    
    local clampedX = math.max(0, math.min(x, ScreenUtils.width - width))
    local clampedY = math.max(0, math.min(y, ScreenUtils.height - height))
    
    return clampedX, clampedY
end

-- Calculate centered position for an element
function ScreenUtils.centerElement(width, height, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    
    local x = (ScreenUtils.width - width) / 2 + offsetX
    local y = (ScreenUtils.height - height) / 2 + offsetY
    
    return x, y
end

-- Calculate relative position on screen with optional anchoring
-- anchor: "topleft", "top", "topright", "left", "center", "right", "bottomleft", "bottom", "bottomright"
function ScreenUtils.anchoredPosition(width, height, anchor, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    anchor = anchor or "center"
    
    local x, y
    
    if anchor == "topleft" then
        x, y = 0, 0
    elseif anchor == "top" then
        x, y = (ScreenUtils.width - width) / 2, 0
    elseif anchor == "topright" then
        x, y = ScreenUtils.width - width, 0
    elseif anchor == "left" then
        x, y = 0, (ScreenUtils.height - height) / 2
    elseif anchor == "center" then
        x, y = (ScreenUtils.width - width) / 2, (ScreenUtils.height - height) / 2
    elseif anchor == "right" then
        x, y = ScreenUtils.width - width, (ScreenUtils.height - height) / 2
    elseif anchor == "bottomleft" then
        x, y = 0, ScreenUtils.height - height
    elseif anchor == "bottom" then
        x, y = (ScreenUtils.width - width) / 2, ScreenUtils.height - height
    elseif anchor == "bottomright" then
        x, y = ScreenUtils.width - width, ScreenUtils.height - height
    end
    
    return x + offsetX, y + offsetY
end

-- Calculate a grid position for gallery items
function ScreenUtils.gridPosition(column, row, itemWidth, itemHeight, padding, startX, startY)
    padding = padding or 10
    startX = startX or 0
    startY = startY or 0
    
    local x = startX + column * (itemWidth + padding)
    local y = startY + row * (itemHeight + padding)
    
    return x, y
end

-- Get appropriate number of columns for a grid based on screen width
function ScreenUtils.getGridColumns(itemWidth, padding, minColumns, maxColumns)
    padding = padding or 10
    minColumns = minColumns or 1
    maxColumns = maxColumns or 8
    
    local availableWidth = ScreenUtils.width - padding * 2
    local calculatedColumns = math.floor(availableWidth / (itemWidth + padding))
    
    return math.max(minColumns, math.min(maxColumns, calculatedColumns))
end

-- Transform coordinates from screen to UI space (for clicks on UI elements)
function ScreenUtils.screenToUICoordinates(x, y)
    -- The default implementation just passes through
    -- Override this if your UI uses a different coordinate system
    return x, y
end

return ScreenUtils