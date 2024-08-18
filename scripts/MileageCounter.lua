--
-- MileageCounter
--
-- @author  Manuel Leithner
-- @date  21/12/2022
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.

-- get the current modname
local modName = g_currentModName

---Specialization for vehicles
-- @category Specializations
MileageCounter = {}

-- pre concatenate the specialization namespace so we don't have to do it every time we access it
MileageCounter.SPEC_TABLE_NAME = "spec_"..modName..".mileageCounter"

---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
-- @includeCode
function MileageCounter.prerequisitesPresent(specializations)
    return true
end

---Registers vehicle event listeners to the given vehicle type
-- Vehicle.lua defines a list of possible event listeners that will be called during runtime
-- @param table vehicleType the vehicle type
-- @includeCode
function MileageCounter.registerEventListeners(vehicleType)
    -- we want the vehicle base class to call our "MileageCounter:onLoad" function during loading
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", MileageCounter)
    -- we want the vehicle base class to call our "MileageCounter:onReadStream" function during network intialization
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MileageCounter)
    -- we want the vehicle base class to call our "MileageCounter:onWriteStream" function during network intialization
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MileageCounter)
    -- we want the vehicle base class to call our "MileageCounter:onReadUpdateStream" function during network object update
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MileageCounter)
    -- we want the vehicle base class to call our "MileageCounter:onWriteUpdateStream" function during network object update
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MileageCounter)
    -- we want the vehicle base class to call our "MileageCounter:onUpdate" function each update loop
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MileageCounter)
end

---Registers custom specialization functions to the vehicle type
-- We need to add all custom functions. Otherwise they won't be available
-- @param table vehicleType the vehicle type
-- @includeCode
function MileageCounter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getDrivenDistance", MileageCounter.getDrivenDistance)
end

---Initializes the specialization
-- Used to register xml config schema and xml savegame schema data
-- @includeCode
function MileageCounter.initSpecialization()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    --Let's add a new savegame element for our mod.
    --We also need to pass the modname as all mod specializations are within the mods namespace
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)."..modName..".mileageCounter#drivenDistance", "Driven distance in meters")
end

---Called on loading
-- @param table savegame savegame
-- @includeCode
function MileageCounter:onLoad(savegame)
    -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    -- initialize the driven distance
    spec.drivenDistance = 0

    -- check if a savegame is available for the current vehicle
    if savegame ~= nil then
        -- read the saved data from savegame
        spec.drivenDistance = savegame.xmlFile:getValue(savegame.key .. "."..modName..".mileageCounter#drivenDistance", 0)
    end

    -- only sync the data to clients if distance changed more than 10m since last network update
    -- in the hud we only display km with 100m precision
    -- threshold needs to be 10m because of up and down rounding in the display
    spec.drivenDistanceNetworkThreshold = 10

    -- we use drivenDistanceSent to determine if we need to update the client
    spec.drivenDistanceSent = spec.drivenDistance

    -- the game uses a dirty pattern system to check if a network object needs an update
    -- we register a new dirty flag for our specialization and we will raise this flag if the system needs to update our specialization
    spec.dirtyFlag = self:getNextDirtyFlag()
end

---Called on game save
-- @param table xmlFile the savegame xml object
-- @param string key the current xml path including the specializations name and namespace
-- @param table usedModNames stores all available mod names
-- @includeCode
function MileageCounter:saveToXMLFile(xmlFile, key, usedModNames)
    -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    -- write the distance to the savegame
    xmlFile:setValue(key .. "#drivenDistance", spec.drivenDistance)
end

---Reads the specializations data on object initialization
-- This function will normally be called on the client once after the object was loaded
-- @param int streamId the id of the network stream
-- @param table connection the network connection
-- @includeCode
function MileageCounter:onReadStream(streamId, connection)
    -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    --Read the driven distance from network stream
    --Note that we loose the decimal part of the driven distance one the client
    --but we can ignore that as we only display the distance on a 100m basis in the hud
    spec.drivenDistance = streamReadInt32(streamId)
end

---Write the specializations data on object initialization
-- This function will normally be called on the server once after the object was loaded
-- @param int streamId the id of the network stream
-- @param table connection the network connection
-- @includeCode
function MileageCounter:onWriteStream(streamId, connection)
    -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    -- write distance to the network stream
    --Note that we loose the decimal part of the driven distance one the client
    --but we can ignore that as we only display the distance on a 100m basis in the hud
    streamWriteInt32(streamId, spec.drivenDistance)
end

---Read the specializations data on object update
-- @param int streamId the id of the network stream
-- @param int timestamp the update timestamp
-- @param table connection the network connection
-- @includeCode
function MileageCounter:onReadUpdateStream(streamId, timestamp, connection)
    -- we only want to read data that was sent from server
    if connection:getIsServer() then
        -- check if server sent us a mileage counter update
        if streamReadBool(streamId) then
            -- Get the specialization namespace
            local spec = self[MileageCounter.SPEC_TABLE_NAME]

            --Read the driven distance from network update stream
            --Note that we loose the decimal part of the driven distance one the client
            --but we can ignore that as we only display the distance on a 100m basis in the hud
            spec.drivenDistance = streamReadInt32(streamId)
        end
    end
end

---Write the specializations data on object update
-- @param int streamId the id of the network stream
-- @param table connection the network connection
-- @param int dirtyMask the update dirtymask
-- @includeCode
function MileageCounter:onWriteUpdateStream(streamId, connection, dirtyMask)
    -- we only want to write to client connections and ignore data that was sent from client to server
    if not connection:getIsServer() then
        -- Get the specialization namespace
        local spec = self[MileageCounter.SPEC_TABLE_NAME]

        -- check if we our mileage counter changed and needs an updat
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            -- write distance to the network stream
            --Note that we loose the decimal part of the driven distance one the client
            --but we can ignore that as we only display the distance on a 100m basis in the hud
            streamWriteInt32(streamId, spec.drivenDistance)
        end
    end
end

---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isActiveForInputIgnoreSelection
-- @param boolean isSelected true if vehicle is selected
-- @includeCode
function MileageCounter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    -- check if the motor is started
    if self:getIsMotorStarted() then
        -- we only count the driven distance on the server
        if self.isServer then
            -- only update the driven distance if vehicle was moved a bit
            if self.lastMovedDistance > 0.001 then
                -- add it to the driven distance
                spec.drivenDistance = spec.drivenDistance + self.lastMovedDistance

                -- check if the distance difference since last network sync
                if math.abs(spec.drivenDistance - spec.drivenDistanceSent) > spec.drivenDistanceNetworkThreshold then
                    -- if difference exceeds the threshold raise the network dirty flag to tell the network system that this vehicle needs a resync
                    self:raiseDirtyFlags(spec.dirtyFlag)
                    -- reset drivenDistanceSent to current distance
                    spec.drivenDistanceSent = spec.drivenDistance
                end
            end
        end
    end
end

---Gets the current driven distance in meter
-- @includeCode
function MileageCounter:getDrivenDistance()
        -- first get the specialization namespace
    local spec = self[MileageCounter.SPEC_TABLE_NAME]

    return spec.drivenDistance
end