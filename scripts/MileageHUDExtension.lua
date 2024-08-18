--
-- MileageHUDExtension
-- Adds mileage display to ingame hud
--
-- @author  Manuel Leithner
-- @date  21/12/2022
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.


---We need to append a anonymous function to HUD:createDisplayComponents
-- It creates all required display components.
-- Now we are able to create a new instance of our MileageDisplay and add it to the HUD
-- @param uiScale Current UI scale
-- @includeCode
HUD.createDisplayComponents = Utils.appendedFunction(HUD.createDisplayComponents, function(self, uiScale)
    self.mileageDisplay = MileageDisplay.new()
    self.mileageDisplay:setScale(uiScale)
    table.insert(self.displayComponents, self.mileageDisplay)
end)


---We need to append a anonymous function to HUD:drawControlledEntityHUD
-- It draws the HUD components for the currently controlled entity (player or vehicle).
-- @includeCode
HUD.drawControlledEntityHUD = Utils.appendedFunction(HUD.drawControlledEntityHUD, function(self)
    if self.isVisible then
        self.mileageDisplay:draw()
    end
end)


---We need to append a anonymous function to HUD:setControlledVehicle
-- It sets current controlled vehicle.
-- @param table vehicle Vehicle reference or nil (not controlling a vehicle)
-- @includeCode
HUD.setControlledVehicle = Utils.appendedFunction(HUD.setControlledVehicle, function(self, vehicle)
    self.mileageDisplay:setVehicle(vehicle)
end)