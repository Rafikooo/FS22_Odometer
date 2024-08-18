---
-- MileageDisplay
-- Mileage counter hud display
--
-- @author Manuel Leithner
-- @date 16/12/2022
-- @category GUI
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.

local modDirectory = g_currentModDirectory

-- Create a base table
MileageDisplay = {}

-- Create a metatable to add class functionality and tell the system that MileageDisplay class will be a subclass of HUDDisplayElement
local MileageDisplay_mt = Class(MileageDisplay, HUDDisplayElement)

---The Class constructor
-- @includeCode
function MileageDisplay.new()
    -- first create the background overlay
    local backgroundOverlay = MileageDisplay.createBackground()

    -- HUDDisplayElement takes the overlay as first parameter to be created
    -- Also pass the class metatable so subclass knows about this one
    local self = MileageDisplay:superClass().new(backgroundOverlay, nil, MileageDisplay_mt)

    self.vehicle = nil

    -- initialize base values with ui scale 1
    self:applyValues(1)

    -- return the object reference
    return self
end

---Sets the current vehicle
-- @param table vehicle Vehicle reference or nil (not controlling a vehicle)
-- @includeCode
function MileageDisplay:setVehicle(vehicle)
    -- check if the passed vehicle has a mileage counter
    -- if no ignore it
    if vehicle ~= nil and vehicle.getDrivenDistance == nil then
        vehicle = nil
    end

    self.vehicle = vehicle
end

---Draws the mileage display
-- @includeCode
function MileageDisplay:draw()
    --We dont need to draw anything if no vehicle is set (e.g. if player is walking around)
    if self.vehicle == nil then
        return
    end

    --Class the draw function of the super class to render the background
    MileageDisplay:superClass().draw(self)

    --Get the current driven distance of the vehicle
    local drivenDistance = self.vehicle:getDrivenDistance()

    local distanceInKM = drivenDistance / 1000

    --Max display value is 999999.9. We use modulo operation to wrap around
    distanceInKM = distanceInKM % 999999.9

    --Convert the distance to the player's current unit (km or mi)
    local distance = g_i18n:getDistance(distanceInKM)
    --Get the unit text (km or mi)
    local unit = g_i18n:getMeasuringUnit()
    --Get the background text
    --%08.2f -> converts the passed distance to a string with 6 numbers + 1 number after the decimal point
    local textBG = string.format("%08.1f %s", distance, unit)
    --Get the text
    --%.2f -> converts the passed distance to a string with 1 number after the decimal point
    local text = string.format("%.1f %s", distance, unit)

    --Store the color in a local for faster access
    local textColor = MileageDisplay.COLOR.TEXT
    local textColorBG = MileageDisplay.COLOR.TEXT_BACKGROUND
    local textSize = self.textSize

    --Get the position of the display
    local posX, posY = self:getPosition()
    posX = posX + self.textOffsetX
    posY = posY + self.textOffsetY

    --Disable bold textrendering
    setTextBold(false)
    --Set textrendering to right alignment
    setTextAlignment(RenderText.ALIGN_RIGHT)
    --Set the color of the textrendering for background text
    setTextColor(textColorBG[1], textColorBG[2], textColorBG[3], textColorBG[4])
    --Render the background text
    renderText(posX, posY, textSize, textBG)

    --Set the color of the textrendering for the text
    setTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
    --Render the text
    renderText(posX, posY, textSize, text)

    --As text rendering functions are using a global scope we need to reset all our changes
    --Reset text alignment to left
    setTextAlignment(RenderText.ALIGN_LEFT)
    --Reset text color to white
    setTextColor(1, 1, 1, 1)
end

------------------------------------------------------------------------------------------------------------------------
-- Scaling
------------------------------------------------------------------------------------------------------------------------

---Set this element's UI scale factor.
-- @param float uiScale UI scale factor
-- @includeCode
function MileageDisplay:setScale(uiScale)
    MileageDisplay:superClass().setScale(self, uiScale, uiScale)

    --Reposition the mileage display if ui scale changed
    local posX, posY = MileageDisplay.getBackgroundPosition(uiScale)
    self:setPosition(posX, posY)

    --Recalculate the offset values
    self:applyValues(uiScale)
end

---Calculate some text values with a given ui scale
-- @param float uiScale UI scale factor
-- @includeCode
function MileageDisplay:applyValues(uiScale)
    --Convert our pixel values stored in MileageDisplay.POSITION.TEXT_OFFSET to normalized screen values
    --getNormalizedScreenValues also take care abour aspect ratios. It assumes that the hud/ui is designed for Full-HD (1920x1080)
    local textOffsetX, textOffsetY = getNormalizedScreenValues(unpack(MileageDisplay.POSITION.TEXT_OFFSET))
    local _, textSize = getNormalizedScreenValues(0, MileageDisplay.SIZE.TEXT)

    self.textOffsetX = textOffsetX*uiScale
    self.textOffsetY = textOffsetY*uiScale
    self.textSize = textSize*uiScale
end

---Get the scaled background position.
-- @param float uiScale UI scale factor
-- @includeCode
function MileageDisplay.getBackgroundPosition(uiScale)
    local width, _ = getNormalizedScreenValues(unpack(MileageDisplay.SIZE.SELF))
    local offsetX, offsetY = getNormalizedScreenValues(unpack(MileageDisplay.POSITION.OFFSET))
    local posX = 1 - width*uiScale + offsetX*uiScale
    local posY = offsetY*uiScale

    return posX, posY
end

---Create the background overlay.
-- @includeCode
function MileageDisplay.createBackground()
    local posX, posY = MileageDisplay.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(MileageDisplay.SIZE.SELF))

    --We need to convert the given filepath and add the mod directory to get the final absolute path
    local filename = Utils.getFilename("hud/mileageCounterBackground.png", modDirectory)

    --Creating a new overlay
    local overlay = Overlay.new(filename, posX, posY, width, height)
    return overlay
end

---Element sizes
MileageDisplay.SIZE = {
    SELF = {128, 32},
    TEXT = 17
}

---Element positions
MileageDisplay.POSITION = {
    OFFSET = {-35, 280},
    TEXT_OFFSET = {115, 10}
}

---Element colors
MileageDisplay.COLOR = {
    TEXT = {1, 1, 1, 1},
    TEXT_BACKGROUND = {0.15, 0.15, 0.15, 1}
}