-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission configuration file for the Skynet-IADS framework
-- see https://github.com/walder/Skynet-IADS
--
-- This configuration is tailored for a mission generated by DCS Retribution
-- see https://github.com/dcs-retribution/dcs-retribution
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Skynet-IADS plugin - configuration
env.info("DCSRetribution|Skynet-IADS plugin - configuration")

if dcsRetribution and SkynetIADS then

    -- specific options
    local createRedIADS = false
    local createBlueIADS = false
    local includeRedInRadio = false
    local includeBlueInRadio = false
    local debugRED = false
    local debugBLUE = false
    local actMobile = false
    local actMobileMaxEmissionTime = 120
    local actMobileMinimumScootDistance = 500
    local actMobileMaximumScootDistance = 3000

    -- retrieve specific options values
    if dcsRetribution.plugins then
        if dcsRetribution.plugins.skynetiads then
            createRedIADS = dcsRetribution.plugins.skynetiads.createRedIADS
            createBlueIADS = dcsRetribution.plugins.skynetiads.createBlueIADS
            includeRedInRadio = dcsRetribution.plugins.skynetiads.includeRedInRadio
            includeBlueInRadio = dcsRetribution.plugins.skynetiads.includeBlueInRadio
            debugRED = dcsRetribution.plugins.skynetiads.debugRED
            debugBLUE = dcsRetribution.plugins.skynetiads.debugBLUE
            actMobile = dcsRetribution.plugins.skynetiads.actMobile
            actMobileMaxEmissionTime = dcsRetribution.plugins.skynetiads.actMobileMaxEmissionTime
            actMobileMinimumScootDistance = dcsRetribution.plugins.skynetiads.actMobileMinimumScootDistance
            actMobileMaximumScootDistance = dcsRetribution.plugins.skynetiads.actMobileMaximumScootDistance
        end
    end

    env.info(string.format("DCSRetribution|Skynet-IADS plugin - createRedIADS=%s", tostring(createRedIADS)))
    env.info(string.format("DCSRetribution|Skynet-IADS plugin - createBlueIADS=%s", tostring(createBlueIADS)))
    env.info(string.format("DCSRetribution|Skynet-IADS plugin - includeRedInRadio=%s", tostring(includeRedInRadio)))
    env.info(string.format("DCSRetribution|Skynet-IADS plugin - includeBlueInRadio=%s", tostring(includeBlueInRadio)))
    env.info(string.format("DCSRetribution|Skynet-IADS plugin - debugRED=%s", tostring(debugRED)))
    env.info(string.format("DCSRetribution|Skynet-IADS plugin - debugBLUE=%s", tostring(debugBLUE)))

    -- actual configuration code
    local function initializeIADSElement(iads, iads_unit, element)
        if iads_unit == nil then
            -- skip processing of units which can not be handled by skynet
            return
        end
        if element.engagement_zone then
            iads_unit:setEngagementZone(element.engagement_zone)
        end
        if element.can_engage_harm then
            iads_unit:setCanEngageHARM(element.can_engage_harm)
        end
        if element.harm_detection_chance then
            iads_unit:setHARMDetectionChance(tonumber(element.harm_detection_chance))
        end
        if element.can_engage_air_weapon then
            iads_unit:setCanEngageAirWeapons(element.can_engage_air_weapon)
        end
        if element.go_live_range_in_percent then
            iads_unit:setGoLiveRangeInPercent(tonumber(element.go_live_range_in_percent))
        end
        if element.autonomous_behaviour then
            iads_unit:setAutonomousBehaviour(element.autonomous_behaviour)
        end
        if element.ConnectionNode then
            for i, cn in pairs(element.ConnectionNode) do
                env.info(string.format("DCSRetribution|Skynet-IADS plugin - adding IADS ConnectionNode %s", cn))
                local connection_node = StaticObject.getByName(cn .. " object") -- pydcs adds ' object' to the unit name for static elements
                if connection_node then
                    iads_unit:addConnectionNode(connection_node)
                end
            end
        end
        if element.PowerSource then
            for i, ps in pairs(element.PowerSource) do
                env.info(string.format("DCSRetribution|Skynet-IADS plugin - adding IADS PowerSource %s", ps))
                local power_source = StaticObject.getByName(ps .. " object") -- pydcs adds ' object' to the unit name for static elements
                if power_source then
                    iads_unit:addPowerSource(power_source)
                end
            end
        end
        if element.PD then
            for i, pd in pairs(element.PD) do
                env.info(string.format("DCSRetribution|Skynet-IADS plugin - adding IADS Point Defence %s", pd))
                local point_defence = iads:addSAMSite(pd)
                if point_defence ~= nil then
                    -- only add as point defence if skynet can handle the PD unit
                    iads_unit:addPointDefence(point_defence)
                end
            end
        end
    end

    local function initializeIADS(iads, coalition, inRadio, debug)

        local coalitionPrefix = "BLUE"
        if coalition == 1 then
            coalitionPrefix = "RED"
        end

        if debug then
            env.info("adding debug information")
            local iadsDebug = iads:getDebugSettings()
            iadsDebug.IADSStatus = true
            iadsDebug.samWentDark = true
            iadsDebug.contacts = true
            iadsDebug.radarWentLive = true
            iadsDebug.noWorkingCommmandCenter = true
            iadsDebug.ewRadarNoConnection = true
            iadsDebug.samNoConnection = true
            iadsDebug.jammerProbability = true
            iadsDebug.addedEWRadar = true
            iadsDebug.hasNoPower = true
            iadsDebug.harmDefence = true
            iadsDebug.samSiteStatusEnvOutput = true
            iadsDebug.earlyWarningRadarStatusEnvOutput = true
            iadsDebug.commandCenterStatusEnvOutput = true
        end

        -- add the AWACS
        if dcsRetribution.AWACs then
            for _, data in pairs(dcsRetribution.AWACs) do
                env.info(string.format("DCSRetribution|Skynet-IADS plugin - processing AWACS %s", data.dcsGroupName))
                local group = Group.getByName(data.dcsGroupName)
                if group then
                    if group:getCoalition() == coalition then
                        local unit = group:getUnit(1)
                        if unit then
                            local unitName = unit:getName()
                            env.info(string.format("DCSRetribution|Skynet-IADS plugin - adding AWACS %s", unitName))
                            iads:addEarlyWarningRadar(unitName)
                        end
                    end
                end
            end
        end

        -- add the IADS Elements: SAM, EWR, and Command Centers
        if dcsRetribution.IADS then
            local coalition_iads = dcsRetribution.IADS[coalitionPrefix]
            if coalition_iads.Ewr then
                for _, unit in pairs(coalition_iads.Ewr) do
                    env.info(string.format("DCSRetribution|Skynet-IADS plugin - processing IADS EWR %s", unit.dcsGroupName))
                    local iads_unit = iads:addEarlyWarningRadar(unit.dcsGroupName)
                    initializeIADSElement(iads, iads_unit, unit)
                end
            end
            if coalition_iads.Sam then
                for _, unit in pairs(coalition_iads.Sam) do
                    env.info(string.format("DCSRetribution|Skynet-IADS plugin - processing IADS SAM %s", unit.dcsGroupName))
                    local iads_unit = iads:addSAMSite(unit.dcsGroupName)
                    initializeIADSElement(iads, iads_unit, unit)
                end
            end
            if coalition_iads.SamAsEwr then
                for _, unit in pairs(coalition_iads.SamAsEwr) do
                    env.info(string.format("DCSRetribution|Skynet-IADS plugin - processing IADS SAM as EWR %s", unit.dcsGroupName))
                    local iads_unit = iads:addSAMSite(unit.dcsGroupName)
                    if iads_unit ~= nil then
                        -- only process if its a valid skynet group
                        iads_unit:setActAsEW(true)
                        initializeIADSElement(iads, iads_unit, unit)
                    end
                end
            end
            if coalition_iads.CommandCenter then
                for _, unit in pairs(coalition_iads.CommandCenter) do
                    env.info(string.format("DCSRetribution|Skynet-IADS plugin - processing IADS Command Center %s", unit.dcsGroupName))
                    local commandCenter = StaticObject.getByName(unit.dcsGroupName .. " object") -- pydcs adds ' object' to the unit name for static elements
                    if commandCenter then
                        local iads_unit = iads:addCommandCenter(commandCenter)
                        initializeIADSElement(iads, iads_unit, unit)
                    end
                end
            end
        end

        if inRadio then
            --activate the radio menu to toggle IADS Status output
            env.info("DCSRetribution|Skynet-IADS plugin - adding in radio menu")
            iads:addRadioMenu()
        end

        --activate the IADS
        iads:activate()
    end

    local function initializeMobileSams(iads)
        local sams = {"SA-6", "SA-8", "SA-9", "SA-11", "SA-13", "SA-15", "SA-17", "SA-19"}
        for _, sam in ipairs(sams) do
            iads:getSAMSitesByNatoName(sam):setActMobile(true,actMobileMaxEmissionTime,actMobileMinimumScootDistance,actMobileMaximumScootDistance,nil)    --ActMobile
        end
    end


    ------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- create the IADS networks
    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    if createRedIADS then
        env.info("DCSRetribution|Skynet-IADS plugin - creating red IADS")
        local redIADS = SkynetIADS:create("IADS")
        initializeIADS(redIADS, 1, includeRedInRadio, debugRED) -- RED
        if actMobile then
            initializeMobileSams(redIADS)
        end
    end

    if createBlueIADS then
        env.info("DCSRetribution|Skynet-IADS plugin - creating blue IADS")
        local blueIADS = SkynetIADS:create("IADS")
        initializeIADS(blueIADS, 2, includeBlueInRadio, debugBLUE) -- BLUE
        if actMobile then
            initializeMobileSams(blueIADS)
        end
    end

end
