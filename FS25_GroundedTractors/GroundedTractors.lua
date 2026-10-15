-- Grounded Tractors: tractors stay planted over ditches and bumps instead of
-- bouncing like a spring. On every motorized vehicle, by default:
--   * chassis centre of mass 0.5 m forward and 0.3 m lower (front ballast, low engine block)
--   * suspension travel x0.4: long travel stored the ditch's energy and catapulted the tractor
--   * body rotation damped only while all wheels are in the air, so it cannot spin mid-jump
-- Values were tuned on video against "slow = glued, 40 km/h = front lifts a little"
-- (docs/acceptance.md).
--
-- Console (needs <development><controls>true</controls> in game.xml):
--   gtTravel <k>   suspension travel x k            gtAir <v>      angular damping while airborne
--   gtCom <dy>     centre of mass dy m lower        gtComZ <dz>    centre of mass dz m forward
--   gtDamp <k>     wheel damper x k                 gtAngDamp <v>  angular damping, always
--   gtInertia <s>  body inertia x s                 gtMass <k>     body mass x k
--   gtOff          everything back to stock         gtInfo         values of the vehicle you are in
--   gtUpright      stand loose implements within 8 m back on their feet
--   gtHud          hide/show the HUD for screenshots

GroundedTractors = {damp = 1, angDamp = nil, comDrop = 0.3, comForward = 0.5, inertia = 1, mass = 1, travel = 0.4, airDamp = 2}

-- WheelAxle's dynamic suspension also calls setSuspensionMultipliers every few
-- frames, so our factor rides on top of whatever the game asks for instead of
-- being overwritten by it.
WheelPhysics.setSuspensionMultipliers = Utils.overwrittenFunction(WheelPhysics.setSuspensionMultipliers,
    function(self, superFunc, springMultiplier, dampingMultiplier)
        self.gtBaseDamping = dampingMultiplier or 1
        superFunc(self, springMultiplier, self.gtBaseDamping * GroundedTractors.damp)
    end)

local function eachVehicle(fn)
    if g_currentMission == nil or g_currentMission.vehicleSystem == nil then
        return 0
    end
    local n = 0
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        -- Tractors only: ballast on an implement's own centre of mass tips it over
        -- (a mower tipped onto its nose and could not be attached).
        if vehicle.components ~= nil and vehicle.spec_motorized ~= nil then
            fn(vehicle)
            n = n + 1
        end
    end
    return n
end

local function eachDynamicComponent(vehicle, fn)
    for _, component in ipairs(vehicle.components) do
        if component.isDynamic and component.node ~= nil and component.node ~= 0 then
            fn(component)
        end
    end
end

local function apply()
    return eachVehicle(function(vehicle)
        if vehicle.spec_wheels ~= nil then
            for _, wheel in ipairs(vehicle.spec_wheels.wheels) do
                local physics = wheel.physics
                if physics ~= nil then
                    physics.gtBaseTravel = physics.gtBaseTravel or physics.suspTravel
                    physics.suspTravel = physics.gtBaseTravel * GroundedTractors.travel
                    physics:setSuspensionMultipliers(physics.springMultiplier, physics.gtBaseDamping or 1)
                end
            end
        end
        local body = vehicle.components[1]
        eachDynamicComponent(vehicle, function(component)
            local node = component.node
            if component.gtStock == nil then
                local cx, cy, cz = getCenterOfMass(node)
                component.gtStock = {angDamp = getAngularDamping(node), mass = getMass(node), cx = cx, cy = cy, cz = cz}
            end
            local stock = component.gtStock
            setAngularDamping(node, GroundedTractors.angDamp or stock.angDamp)
            -- Ballast belongs to the chassis only: the other components (pendulum
            -- front axle, cab) rotate about their own pivot, and moving their
            -- centre of mass turns them into an unbalanced pendulum.
            if component == body then
                setCenterOfMass(node, stock.cx, stock.cy - GroundedTractors.comDrop, stock.cz + GroundedTractors.comForward)
            else
                setCenterOfMass(node, stock.cx, stock.cy, stock.cz)
            end
            setMass(node, stock.mass * GroundedTractors.mass)
            setInertiaScale(node, GroundedTractors.inertia, GroundedTractors.inertia, GroundedTractors.inertia)
        end)
    end)
end

-- H: per frame, damp body rotation only while every wheel has lost the ground,
-- so the tractor still pitches freely to follow a ditch but cannot spin in the air.
local function isAirborne(vehicle)
    local wheels = vehicle.spec_wheels ~= nil and vehicle.spec_wheels.wheels or nil
    if wheels == nil or #wheels == 0 then
        return false
    end
    for _, wheel in ipairs(wheels) do
        local physics = wheel.physics
        if physics == nil or not physics.wheelShapeCreated or physics.hasGroundContact then
            return false
        end
    end
    return true
end

function GroundedTractors:update(dt)
    -- ponytail: re-apply whenever the vehicle count changes (load, purchase);
    -- a sold-and-bought-same-frame swap would be missed.
    local count = 0
    if g_currentMission ~= nil and g_currentMission.vehicleSystem ~= nil then
        for _ in pairs(g_currentMission.vehicleSystem.vehicles) do count = count + 1 end
    end
    if count ~= self.lastCount then
        self.lastCount = count
        apply()
    end
    if self.airDamp == nil and not self.airActive then
        return
    end
    eachVehicle(function(vehicle)
        local airborne = self.airDamp ~= nil and isAirborne(vehicle)
        if airborne ~= (vehicle.gtAirborne or false) then
            vehicle.gtAirborne = airborne
            eachDynamicComponent(vehicle, function(component)
                if component.gtStock == nil then
                    local cx, cy, cz = getCenterOfMass(component.node)
                    component.gtStock = {angDamp = getAngularDamping(component.node), mass = getMass(component.node), cx = cx, cy = cy, cz = cz}
                end
                local grounded = self.angDamp or component.gtStock.angDamp
                setAngularDamping(component.node, airborne and self.airDamp or grounded)
            end)
        end
    end)
    -- one more pass after gtOff so any vehicle caught mid-air is put back on stock damping
    self.airActive = self.airDamp ~= nil
end

addModEventListener(GroundedTractors)

local function report(what)
    local n = apply()
    return string.format("GroundedTractors %s | damp x%.2f  angDamp %s  com -%.2fm fwd %.2fm  inertia x%.2f  mass x%.2f  travel x%.2f  air %s | %d vehicles",
        what, GroundedTractors.damp, tostring(GroundedTractors.angDamp or "stock"), GroundedTractors.comDrop, GroundedTractors.comForward,
        GroundedTractors.inertia, GroundedTractors.mass, GroundedTractors.travel, tostring(GroundedTractors.airDamp or "off"), n)
end

function GroundedTractors:cmdDamp(k)        self.damp = tonumber(k) or 1;          return report("A") end
function GroundedTractors:cmdAngDamp(v)     self.angDamp = tonumber(v);            return report("B") end
function GroundedTractors:cmdCom(dy)        self.comDrop = tonumber(dy) or 0;      return report("C") end
function GroundedTractors:cmdInertia(s)     self.inertia = tonumber(s) or 1;       return report("D") end
function GroundedTractors:cmdComZ(dz)       self.comForward = tonumber(dz) or 0;   return report("E") end
-- ponytail: Vehicle re-applies component mass when fill levels change, so this
-- only holds for an empty tractor; enough for the spike.
function GroundedTractors:cmdMass(k)        self.mass = tonumber(k) or 1;          return report("F") end
function GroundedTractors:cmdTravel(k)      self.travel = tonumber(k) or 1;        return report("G") end
function GroundedTractors:cmdAir(v)         self.airDamp = tonumber(v);            return report("H") end
function GroundedTractors:cmdOff()
    self.damp, self.angDamp, self.comDrop, self.comForward, self.inertia, self.mass = 1, nil, 0, 0, 1, 1
    self.travel, self.airDamp = 1, nil
    return report("off")
end

function GroundedTractors:cmdInfo()
    local vehicle = g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() or nil
    if vehicle == nil then
        return "GroundedTractors: enter a vehicle first"
    end
    local lines = {vehicle:getFullName()}
    eachDynamicComponent(vehicle, function(component)
        local cx, cy, cz = getCenterOfMass(component.node)
        table.insert(lines, string.format("  component mass %.2ft  com (%.2f %.2f %.2f)  angDamp %.3f",
            getMass(component.node), cx, cy, cz, getAngularDamping(component.node)))
    end)
    if vehicle.spec_wheels ~= nil then
        for i, wheel in ipairs(vehicle.spec_wheels.wheels) do
            local p = wheel.physics
            table.insert(lines, string.format("  wheel %d spring %.1f damperRelax %.1f/%.1f damperComp %.1f/%.1f travel %.2f mult s%.2f d%.2f",
                i, p.spring, p.damperRelaxationLowSpeed, p.damperRelaxationHighSpeed,
                p.damperCompressionLowSpeed, p.damperCompressionHighSpeed, p.suspTravel,
                p.springMultiplier, p.dampingMultiplier))
        end
    end
    local text = table.concat(lines, "\n")
    print(text)
    return text
end

-- Stands implements within 8 m of the player back on their wheels, keeping the heading.
function GroundedTractors:cmdUpright()
    if g_localPlayer == nil or g_currentMission == nil then
        return "GroundedTractors: no player"
    end
    local px, py, pz = g_localPlayer:getPosition()
    local n = 0
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.rootNode ~= nil and vehicle.spec_motorized == nil and vehicle.getAttacherVehicle ~= nil and vehicle:getAttacherVehicle() == nil then
            local x, y, z = getWorldTranslation(vehicle.rootNode)
            if MathUtil.vector3Length(x - px, y - py, z - pz) < 8 then
                local dx, _, dz = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
                local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 300, z)
                vehicle:setAbsolutePosition(x, math.max(y, terrainY) + 0.5, z, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)
                n = n + 1
            end
        end
    end
    return string.format("GroundedTractors upright | %d implements", n)
end

-- For ModHub screenshots: the base game has no HUD toggle outside some vehicle cameras.
function GroundedTractors:cmdHud()
    local hud = g_currentMission ~= nil and g_currentMission.hud or nil
    if hud == nil then
        return "GroundedTractors: no HUD"
    end
    self.hudHidden = not self.hudHidden
    hud:setIsVisible(not self.hudHidden)
    return self.hudHidden and "HUD hidden (gtHud again to show)" or "HUD shown"
end

addConsoleCommand("gtDamp", "A: wheel damper multiplier", "cmdDamp", GroundedTractors, "k")
addConsoleCommand("gtAngDamp", "B: body angular damping", "cmdAngDamp", GroundedTractors, "value")
addConsoleCommand("gtCom", "C: lower centre of mass by metres", "cmdCom", GroundedTractors, "metres")
addConsoleCommand("gtInertia", "D: body inertia multiplier", "cmdInertia", GroundedTractors, "scale")
addConsoleCommand("gtComZ", "E: move centre of mass forward by metres", "cmdComZ", GroundedTractors, "metres")
addConsoleCommand("gtMass", "F: body mass multiplier", "cmdMass", GroundedTractors, "factor")
addConsoleCommand("gtTravel", "G: suspension travel multiplier", "cmdTravel", GroundedTractors, "factor")
addConsoleCommand("gtAir", "H: angular damping only while airborne", "cmdAir", GroundedTractors, "value")
addConsoleCommand("gtOff", "Back to stock", "cmdOff", GroundedTractors)
addConsoleCommand("gtUpright", "Stand nearby implements back on their wheels", "cmdUpright", GroundedTractors)
addConsoleCommand("gtHud", "Toggle the HUD for screenshots", "cmdHud", GroundedTractors)
addConsoleCommand("gtInfo", "Print physics values of current vehicle", "cmdInfo", GroundedTractors)
