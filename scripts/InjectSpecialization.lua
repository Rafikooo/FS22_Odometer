--
-- InjectSpecialization
-- adds mileage counter to vehicles with drivable specialization
--
-- @author  Manuel Leithner
-- @date  21/12/2022
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.

--Store the current modName. This global is set once while each mod is loaded at starttime so we need to store it
local modName = g_currentModName

--Prepends a new function to TypeManagers finalizeTypes
--System now first calls this anonymous function and later the original TypeManager.fianlizeTypes
TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(self, ...)
    --Type manager handles vehicle and placeable types so we first need to check if it's currently finalizing the vehicle types
    if self.typeName == "vehicle" then
        --Loop over all types
        for typeName, typeEntry in pairs(self:getTypes()) do
            --Loop over all specilizations of the current type
            for name, _ in pairs(typeEntry.specializationsByName) do
                --Check if the current spec is motorized
                if name == "motorized" then
                    --Add our mileage counter spec. We need to also pass the modName because mod specializations have their our mod namespace
                    self:addSpecialization(typeName, modName..".mileageCounter")
                    --Break the inner for loop as we already found the motorized specialization for this type
                    break
                end
            end
        end
    end
end)
