local dynamic = exports["legacydmc_dynamic"]
local brakeGlowDebug = false

function initCameraVars()
    cameraIndex = 1
    enabledBikeYawCorrection = true
    camAccPitchOffset = 0
    camCoastPitchOffset = 0
    camBrakePitchOffset = 0
    camIdlePitchOffset = 0
    camFovOffset = 0 
    camChaseYOffset = 0
    camChaseZOffset = 0
    camFpvYOffset = 0
    camFpvZOffset = 0
end

function initTelemetryVars()
    local telemetryDataThisFrame = dynamic:getTelemetryData()
    tcsActive, escActive= dynamic:getAssists()
    tcsLevel =telemetryDataThisFrame.tcsLevel
    currentWheelIndex = 1
end

function initTuningVars()
    -- idealy, you would want to init then as the base value of the car gathered with dynamic:getVehicleData()
    local currentCarModel = GetEntityModel(GetVehiclePedIsIn(PlayerPedId(),false))
    local currentCarData = dynamic:getVehicleData(currentCarModel)

    local engSwapList = dynamic:getAvailableEngineSwaps()
    local engSwapIdx = 1
    local tyreCompoundList = dynamic:getAvailableTyres()
    local tyreCompoundIdx = 1


    currentAvailableEngines = {}
    for k,v in pairs(engSwapList) do
        currentAvailableEngines[engSwapIdx] = k
        engSwapIdx = engSwapIdx+1
    end

    currentAvailableEngines[engSwapIdx] = "stock"

    currentAvailableTyres = {}
    for k,v in pairs(tyreCompoundList) do
        currentAvailableTyres[tyreCompoundIdx] = k
        tyreCompoundIdx = tyreCompoundIdx+1
    end

    selectedEngineIdx = 1
    selectedTyreIdx = 1
    currentDrivingMode = dynamic:getTransmissionMode()
    stockTransmissionData = currentCarData.transmission
    currentFrontTorqueDist = currentCarData.transmission.frontTorqueDist
    currentGearAmmount = currentCarData.transmission.gearCount -- we dont have the reverse gear included on the vehdata, as it is added dynamically.
    currentTransmissionData = stockTransmissionData
    currentPerformanceIndex = 0
    currentAccHandlingScore = 0
    currentBrakingHandlingScore = 0
    currentTopSpeedHandlingScore = 0
    currentPiHandlingScore = 0
    currentPowerMulti = 1.0
    currentBrakeMulti = 1.0
    currnetWeightMulti = 1.0
end

function inputContextButton(label, inputLabel, toolTip, defaultInputVal, maxVal, minVal,valVariation,editedVal, callBack)
    local buttonPressed, inputText = WarMenu.InputButton(label, inputLabel, _inputText, 4, '← ' .. tostring(editedVal) .. ' →')
    
    if WarMenu.IsItemHovered() then
        WarMenu.ToolTip(toolTip, nil, true)
        if IsControlJustReleased(2, 189) then
            editedVal = math.max(minVal, editedVal - valVariation)
            callBack(editedVal)
        end
        if IsControlJustReleased(2, 190) then
            editedVal = math.min(maxVal, editedVal + valVariation)
            callBack(editedVal)
        end
    end

    if buttonPressed and inputText then
        local val = tonumber(inputText) or defaultInputVal
        callBack(val)
    end
end

function round(val, decimals)
    decimals = decimals or 0
    local multiplier = 10 ^ decimals
    return math.floor(val * multiplier + 0.5) / multiplier
end

Citizen.CreateThread(function()
    -- Create a new menu
    WarMenu.CreateMenu('rightMenu', 'Dynamic Exports')
    WarMenu.CreateSubMenu('brakeMenu', 'rightMenu', 'Brake Exports')
    WarMenu.CreateSubMenu('callerMenu', 'rightMenu', 'Caller Exports')
    WarMenu.CreateSubMenu('cameraMenu', 'rightMenu', 'Camera Exports')
    WarMenu.CreateSubMenu('diffMenu', 'rightMenu', 'Differential Exports')
    WarMenu.CreateSubMenu('driveTrainMenu', 'rightMenu', 'Drivetrain Exports')
    WarMenu.CreateSubMenu('ecuMenu', 'rightMenu', 'ECU Exports')
    WarMenu.CreateSubMenu('wheelMenu', 'rightMenu', 'Wheel Data')
    WarMenu.CreateSubMenu('piMenu', 'rightMenu', 'Performance Index Exports')
    WarMenu.CreateSubMenu('transmissionMenu', 'rightMenu', 'Transmission Exports')
    WarMenu.CreateSubMenu('tuningMenu', 'rightMenu', 'Tuning Exports')
    WarMenu.CreateSubMenu('tyreMenu', 'rightMenu', 'Tyre Exports')
    
    initCameraVars()

    while true do
        Citizen.Wait(0)

        local vehicle = GetVehiclePedIsIn(PlayerPedId(),false)
        if GetIsVehicleEngineRunning(vehicle) then
            if IsControlJustPressed(0, 288) then -- F1
                WarMenu.OpenMenu('rightMenu')
                initTelemetryVars()
                initTuningVars()
            end
        end

        WarMenu.SetMenuX(WarMenu.CurrentMenu(), 0.75)
        WarMenu.SetMenuY(WarMenu.CurrentMenu(), 0.025)

        if WarMenu.Begin('rightMenu') then
            WarMenu.MenuButton('Brake Exports', 'brakeMenu')
            WarMenu.MenuButton('Caller Exports', 'callerMenu')
            WarMenu.MenuButton('Camera Exports', 'cameraMenu')
            WarMenu.MenuButton('Differential Exports', 'diffMenu')
            WarMenu.MenuButton('Drivetrain Exports', 'driveTrainMenu')
            WarMenu.MenuButton('ECU Exports', 'ecuMenu')
            WarMenu.MenuButton('Performance Index Exports', 'piMenu')
            WarMenu.MenuButton('Transmission Exports', 'transmissionMenu')
            WarMenu.MenuButton('Tuning Exports', 'tuningMenu')
            WarMenu.MenuButton('Tyre Exports', 'tyreMenu')
            
            if WarMenu.Button('Close Menu') then
                WarMenu.CloseMenu()
            end
        elseif WarMenu.Begin('brakeMenu') then
            local currentBrakeTemp = math.floor(dynamic:getBrakeTemp())

            local brakeDebugPressed = WarMenu.CheckBox("Toggle Brake Glow Debug",brakeGlowDebug)
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('When enabled, holds the brake temperature at 5000ºC',nil,true)
            end
            if brakeDebugPressed then brakeGlowDebug = dynamic:toggleBrakeDebug() end

            local brakeTempPressed, inputText =  WarMenu.InputButton("Brake Temperature: ", "Temperature in C:", _inputText, 4,tostring(currentBrakeTemp)..'ºC')
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Press enter to input a value.',nil,true)
            end
            if brakeTempPressed then
                if inputText then
                    if tonumber(inputText) == nil then
                        inputText = 25.0
                    end
                    dynamic:setBrakeTemp(inputText)        
                end
            end

        elseif WarMenu.Begin('callerMenu') then
            local currentVehicleNetId = NetworkGetNetworkIdFromEntity(GetVehiclePedIsIn(PlayerPedId(),false))
            
            local stopDynamicPressed = WarMenu.Button("Disable Dynamic")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('When pressed, disables dynamic on the current vehicle.',nil,true)
            end
            if stopDynamicPressed then brakeGlowDebug = dynamic:stopDynamic(currentVehicleNetId) end

            local enableDynamicPressed = WarMenu.Button("Enable Dynamic")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('When pressed, enables dynamic on the current vehicle.',nil,true)
            end
            if enableDynamicPressed then brakeGlowDebug = dynamic:startDynamic(currentVehicleNetId) end

        elseif WarMenu.Begin('cameraMenu') then
            local cameraAmmount = dynamic:getCameraAmmount()

            WarMenu.Button("Current Camera Index: ", '← '..tostring(cameraIndex)..' →')
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('User the arrow keys to swap through available cameras.',nil,true)
                if IsControlJustReleased(2, 189) then
                    cameraIndex = cameraIndex - 1
                    if cameraIndex < 1 then
                        cameraIndex = cameraAmmount
                    end
                    dynamic:swapCamera(cameraIndex)
                end
                if IsControlJustReleased(2, 190) then
                    cameraIndex = cameraIndex + 1
                    if cameraIndex > cameraAmmount then
                        cameraIndex = 1 
                    end
                    dynamic:swapCamera(cameraIndex)
                end
            end   
            local cameraData = dynamic:getCameraData(cameraIndex)
            WarMenu.SetMenuTitle('cameraMenu',cameraData.name) -- this is a custom function, if you ever try replicate this and it doesnt work, that's why.

            inputContextButton(
                "Acceleration Pitch: ",
                "Acceleration Pitch",
                "Controls how much the camera looks up when accelerating.",
                0, 10, -10, 0.05,
                camAccPitchOffset,
                function(val)
                    camAccPitchOffset = val
                    dynamic:setCurrentCameraPitchOffset(camAccPitchOffset, camCoastPitchOffset, camBrakePitchOffset, camIdlePitchOffset)
                end
            )

            inputContextButton(
                "Coasting Pitch: ",
                "Coasting Pitch",
                "Controls how much the camera looks up when coasting.",
                0, 10, -10, 0.05,
                camCoastPitchOffset,
                function(val)
                    camCoastPitchOffset = val
                    dynamic:setCurrentCameraPitchOffset(camAccPitchOffset, camCoastPitchOffset, camBrakePitchOffset, camIdlePitchOffset)
                end
            )

            inputContextButton(
                "Braking Pitch: ",
                "Braking Pitch",
                "Controls how much the camera looks down when braking.",
                0, 10, -10, 0.05,
                camBrakePitchOffset,
                function(val)
                    camBrakePitchOffset = val
                    dynamic:setCurrentCameraPitchOffset(camAccPitchOffset, camCoastPitchOffset, camBrakePitchOffset, camIdlePitchOffset)
                end
            )

            inputContextButton(
                "Idle Pitch: ",
                "Idle Pitch", 0.05,
                "Controls how much the camera looks down when idling.",
                0, 10, -10,
                camIdlePitchOffset,
                function(val)
                    camIdlePitchOffset = val
                    dynamic:setCurrentCameraPitchOffset(camAccPitchOffset, camCoastPitchOffset, camBrakePitchOffset, camIdlePitchOffset)
                end
            )

            -- since Lua numbers are passed by value, not reference we need to repeat this inside the func(). Are there better ways to doing this? Yes. But this is just a simple exports demo.
            local usedOffsetY = cameraData.isFpv and camFpvYOffset or camChaseYOffset
            local usedOffsetZ = cameraData.isFpv and camFpvZOffset or camChaseZOffset

            inputContextButton(
                "Y Offset: ",
                "Y Offset",
                "Controls the camera offset on the y axis.",
                0, 10, -10, 0.05,
                usedOffsetY,
                function(val)
                    if cameraData.isFpv then 
                        camFpvYOffset = val
                        dynamic:setCurrentFpvCameraSpacingOffset(usedOffsetY, usedOffsetZ) 
                    else 
                        camChaseYOffset = val
                        dynamic:setCurrentCameraSpacingOffset(usedOffsetY, usedOffsetZ) 
                    end
                end
            )

            inputContextButton(
                "Z Offset: ",
                "Z Offset",
                "Controls the camera offset on the Z axis.",
                0, 10, -10, 0.05,
                usedOffsetZ,
                function(val)
                    if cameraData.isFpv then 
                        camFpvZOffset = val
                        dynamic:setCurrentFpvCameraSpacingOffset(usedOffsetY, usedOffsetZ) 
                    else 
                        camChaseZOffset = val
                        dynamic:setCurrentCameraSpacingOffset(usedOffsetY, usedOffsetZ) 
                    end
                end
            )

            inputContextButton(
                "FOV Offset: ",
                "FOV Offset",
                "Controls the camera FOV offset.",
                0, 100, -100, 1.0,
                camFovOffset,
                function(val)
                    camFovOffset = val
                    dynamic:setCurrentCameraFovOffset(camFovOffset)
                end
            )

            local yawCorrectionPressed = WarMenu.CheckBox("Toggle Bike Yaw Correction",enabledBikeYawCorrection)
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Toggles the bike yaw correction, acting like a gyroscope for the camera.',nil,true)
            end
            if yawCorrectionPressed then enabledBikeYawCorrection = dynamic:toggleBikeYawCorrection() end

            local stopDynamicPressed = WarMenu.Button("Disable Camera")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('When pressed, disables the camera on the current vehicle.',nil,true)
            end
            if stopDynamicPressed then dynamic:stopCamera() end

            local enableCameraPressed = WarMenu.Button("Enable Camera")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('When pressed, enables the camera on the current vehicle.',nil,true)
            end
            if enableCameraPressed then dynamic:startCamera() end
        elseif WarMenu.Begin('diffMenu') then
            WarMenu.CheckBox("Is Drifting", dynamic:getIsVehicleCurrentlyDrifting())
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Checks if your car is drifting..',nil,true)
            end
            WarMenu.CheckBox("Is Sliding",dynamic:getIsVehicleCurrentlyDriftingThrottleLess())
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Check if your car is sliding (Drifting, without throttle.).',nil,true)
            end
        elseif WarMenu.Begin('driveTrainMenu') then
            inputContextButton(
                "Front Torque Distribution (%): ",
                "Front Torque Distribution (%)",
                "Controls your front torque distribution.",
                0, 1, 0, 0.01,
                currentFrontTorqueDist,
                function(val)
                    currentFrontTorqueDist = val
                    dynamic:setFrontTorqueDist(currentFrontTorqueDist)
                end
            )
        elseif WarMenu.Begin('ecuMenu') then
            local tcsPressed = WarMenu.CheckBox("Toggle TCS",tcsActive)
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Toggles the Traction Control System',nil,true)
            end
            if tcsPressed then tcsActive = dynamic:toggleTcs() end

            local escPressed = WarMenu.CheckBox("Toggle ESC",escActive)
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Toggles the Eletronic Stability Control System',nil,true)
            end
            if escPressed then escActive = dynamic:toggleEsc() end

            local currentCarTelemetry = dynamic:getTelemetryData()
            
            WarMenu.Button("Engine RPM: "..math.round(currentCarTelemetry.engineRpm))
            WarMenu.Button("Current Gear: "..currentCarTelemetry.gear)
            WarMenu.Button("TCS Actuating: "..tostring(currentCarTelemetry.tcsActive))
            WarMenu.Button("ESC Actuating: "..tostring(currentCarTelemetry.escActive))

            inputContextButton(
                "Traction Control Level: ",
                "Traction Control Level:",
                "Controls the interferance of the TCS system.",
                1, 10, 1, 1,
                tcsLevel,
                function(val)
                    tcsLevel = val
                    dynamic:setCurrentVehicleTcsLevel(tcsLevel)
                end
            )

            WarMenu.Button("Traction Loss Ratio: "..currentCarTelemetry.tractionLossRatio)
            WarMenu.MenuButton('Wheel Data', 'wheelMenu')
        elseif WarMenu.Begin('wheelMenu') then
            inputContextButton(
                "Current Wheel Index: ",
                "Wheel Index:",
                "Alters which wheel to display information from.",
                1, 4, 1, 1,
                currentWheelIndex,
                function(val)
                    currentWheelIndex = val
                end
            )
            local wheelData = dynamic:getWheelData()[currentWheelIndex]

            WarMenu.Button("Speed (MS): "..round(wheelData.speed,2))
            WarMenu.Button("Traction Vec Value (Mag): "..round(wheelData.tractionVector,2))
            WarMenu.Button("Load (KG): "..round(wheelData.wheelLoad,2))
            WarMenu.Button("Slip Angle (Deg): "..round(wheelData.slipAngle,2))
            WarMenu.Button("Slip Ratio (%): "..round(wheelData.slipRatio,2))
            WarMenu.Button("Temperature (ºC): "..round(wheelData.temperature,2))
            WarMenu.Button("Temp Friction Multi: "..round(wheelData.tempFricMulti,2))
            WarMenu.Button("Material Friction Multi: "..round(wheelData.materialFricMulti,2))
            WarMenu.Button("Suspension Compression Rate (%): "..round(wheelData.suspensionCompression,3))
            WarMenu.Button("Suspension Travel Distance (M): "..round(wheelData.suspensionTravelDistance,2))
        elseif WarMenu.Begin('piMenu') then
            local piCalPressed = WarMenu.Button("Print PI Calibration Results")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Prints in the F8 Console the data required for calibration.',nil,true)
            end
            if piCalPressed then 
                local currentCarModel = GetEntityModel(GetVehiclePedIsIn(PlayerPedId(),false))
                dynamic:getPerformanceIndexCalibrationMetrics(currentCarModel)
            end
            local piPressed = WarMenu.Button("Performance Index: "..currentPerformanceIndex)
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Press Enter to calculate the PI for the current vehicle (stock)',nil,true)
            end
            if piPressed then 
                local currentCarModel = GetEntityModel(GetVehiclePedIsIn(PlayerPedId(),false))
                local performanceData = dynamic:getPerformanceIndex(currentCarModel,nil,nil,nil,nil,nil,nil)
                currentPerformanceIndex = performanceData.PI -- since we are calculating the stock PI, we can pass all args as nil.
                currentAccHandlingScore = performanceData.accScore
                currentBrakingHandlingScore = performanceData.brakingScore
                currentTopSpeedHandlingScore = performanceData.estimatedTopSpeedScore
                currentPiHandlingScore = performanceData.handlingScore
            end
            local piPressed = WarMenu.Button("Acceleration Score: "..currentAccHandlingScore/100)
            local piPressed = WarMenu.Button("Braking Score: "..currentBrakingHandlingScore/100)
            local piPressed = WarMenu.Button("Top Speed Score: "..currentTopSpeedHandlingScore/100)
            local piPressed = WarMenu.Button("Handling Score: "..currentPiHandlingScore/100)
        elseif WarMenu.Begin('transmissionMenu') then
            local currentCarModel = GetEntityModel(GetVehiclePedIsIn(PlayerPedId(),false))
            local currentDrivingMode = dynamic:getTransmissionMode()
            local getTopSpeedPressed = WarMenu.Button("Print Top Speed of Each Gear")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Prints in the top speed of each gear for this vehicle.',nil,true)
            end
            if getTopSpeedPressed then 
                local currentCarModel = GetEntityModel(GetVehiclePedIsIn(PlayerPedId(),false))
                local speedTable = dynamic:getTopSpeedTable(currentCarModel)

                for k,v in ipairs(speedTable) do
                    print("Gear "..(k-1)..": ", v)
                end
            end

            local getCustomTopSpeedPressed = WarMenu.Button("Print Top Speed of Specific Transmission")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Prints in the top speed of a specific transmission.',nil,true)
            end
            if getCustomTopSpeedPressed then 

                local transmissionData = { -- you can get this with dynamic:getVehicleData(), or loading your own custom solution.
                    frontTorqueDist = 0.3, -- the transmission data it expects, is simply the same as the vehData.lua, as dynamic is built on modular components.
                    gearCount = 7,
                    gearRatios = {
                        3.133,
                        2.083,
                        1.575,
                        1.244,
                        0.979,
                        0.786,
                        0.677,
                    },
                    launchControl = {
                        enabled = false,
                        targetRpmRange = 0.09610389610389611,
                    },
                    maxSpeed = 326,
                    rpmDecaymentSpeed = 2.5,
                    shiftingTime = 125,
                    transmissionType = 0,
                }
                local speedTable = dynamic:getTopSpeedTableFromTransmissionData(transmissionData)

                for k,v in ipairs(speedTable) do
                    print("Gear "..(k-1)..": ", v)
                end
            end

            inputContextButton(
                "Current Driving Mode ID: ",
                "Driving Mode ID:",
                "0 = Seq, 1 = Manual, 2 = Auto.",
                0, 2, 0, 1,
                currentDrivingMode,
                function(val)
                    currentDrivingMode = val
                    dynamic:setTransmissionMode(currentDrivingMode)
                end
            )

        elseif WarMenu.Begin('tuningMenu') then
            WarMenu.Button("Select Your Engine", '← '..tostring(currentAvailableEngines[selectedEngineIdx])..' →')
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('User the arrow keys to choose available engine swaps.',nil,true)
                if IsControlJustReleased(2, 189) then
                    selectedEngineIdx = selectedEngineIdx - 1
                    if selectedEngineIdx < 1 then
                        selectedEngineIdx = #currentAvailableEngines
                    end
                end
                if IsControlJustReleased(2, 190) then
                    selectedEngineIdx = selectedEngineIdx + 1
                    if selectedEngineIdx > #currentAvailableEngines then
                        selectedEngineIdx = 1 
                    end
                end
            end   
            WarMenu.Button("Select Your Tyre", '← '..tostring(currentAvailableTyres[selectedTyreIdx])..' →')
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('User the arrow keys to swap through available cameras.',nil,true)
                if IsControlJustReleased(2, 189) then
                    selectedTyreIdx = selectedTyreIdx - 1
                    if selectedTyreIdx < 1 then
                        selectedTyreIdx = #currentAvailableTyres
                    end
                end
                if IsControlJustReleased(2, 190) then
                    selectedTyreIdx = selectedTyreIdx + 1
                    if selectedTyreIdx > #currentAvailableTyres then
                        selectedTyreIdx = 1 
                    end
                end
            end 
            inputContextButton(
                "Current Gear Ammount: ",
                "Gear Ammount:",
                "The current designed gear ammount for this tune.",
                1, 15, 1, 1,
                currentGearAmmount,
                function(val)
                    currentGearAmmount = val
                end
            )

            for i = 1,currentGearAmmount do
                if currentTransmissionData.gearRatios[i] == nil then
                    currentTransmissionData.gearRatios[i] = 0.5
                end
                inputContextButton(
                    "Gear "..(i).." Ratio: ",
                    "Gear "..(i).." Ratio: ",
                    "Use the arrow keys or press enter to alter  the ratio for this gear.",
                    1, 15, 1, 0.01,
                    currentTransmissionData.gearRatios[i],
                    function(val)
                        currentTransmissionData.gearRatios[i] = val
                    end
                )
            end

            inputContextButton(
                "Transmission Max Speed: ",
                "Transmission Max Speed: ",
                "Use the arrow keys or press enter to alter the max speed for this transmission.",
                5, 350, 5, 5,
                currentTransmissionData.maxSpeed,
                function(val)
                    currentTransmissionData.maxSpeed = val
                end
            )

            inputContextButton(
                "Transmission Shift Time: ",
                "Transmission Shift Time: ",
                "Use the arrow keys or press enter to alter the Shift Time for this transmission.",
                125, 1000, 125, 25,
                currentTransmissionData.shiftingTime,
                function(val)
                    currentTransmissionData.shiftingTime = val
                end
            )

            inputContextButton(
                "Power Multiplier: ",
                "Power Multiplier: ",
                "Use the arrow keys or press enter to alter the power multiplier.",
                1.0, 5.0, 0.1, 0.05,
                currentPowerMulti,
                function(val)
                    currentPowerMulti = val
                end
            )

            inputContextButton(
                "Weight Multiplier: ",
                "Weight Multiplier: ",
                "Use the arrow keys or press enter to alter the weight multiplier.",
                1.0, 5.0, 0.1, 0.05,
                currnetWeightMulti,
                function(val)
                    currnetWeightMulti = val
                end
            )

            inputContextButton(
                "Brakes Multiplier: ",
                "Brakes Multiplier: ",
                "Use the arrow keys or press enter to alter the brakes multiplier.",
                1.0, 5.0, 0.1, 0.05,
                currentBrakeMulti,
                function(val)
                    currentBrakeMulti = val
                end
            )


            local applyTunePressed = WarMenu.Button("Apply Tune")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Applies your created tune profile.',nil,true)
            end
            if applyTunePressed then 
                local engineSwap = currentAvailableEngines[selectedEngineIdx]
                local tyreSwap = currentAvailableTyres[selectedTyreIdx]
                dynamic:loadTunedSetup(engineSwap,currentTransmissionData,tyreSwap,currentPowerMulti,currnetWeightMulti,currentBrakeMulti)
            end
        elseif WarMenu.Begin('tyreMenu') then
            local warmUpTyresPressed = WarMenu.Button("Warm Up Tyres")
            if WarMenu.IsItemHovered() then
                WarMenu.ToolTip('Instantly Warms up the tyres to their operational temp.',nil,true)
            end
            if warmUpTyresPressed then 
                dynamic:warmTyre()
            end
        end
        WarMenu.End()
    end
end)
