        local Players, Client, Mouse, RS, Camera, r =
        game:GetService("Players"),
        game:GetService("Players").LocalPlayer,
        game:GetService("Players").LocalPlayer:GetMouse(),
        game:GetService("RunService"),
        game.Workspace.CurrentCamera,
        math.random

        local Circle = Drawing.new("Circle")
        Circle.Color = Color3.new(1, 1, 1)
        Circle.Transparency = 1
        Circle.Thickness = 2

        local TracerCircle = Drawing.new("Circle")
        TracerCircle.Color = Color3.new(1, 1, 1)
        TracerCircle.Thickness = 1

        local prey
        local prey2
        local On

        local Vec2 = function(property)
            return Vector2.new(property.X, property.Y + (game:GetService("GuiService"):GetGuiInset().Y))
        end

        local UpdateSilentFOV = function()
            if not Circle then
                return Circle
            end
            Circle.Visible = getgenv().Genetic.Silent["ShowFOV"]
            Circle.Radius = getgenv().Genetic.Silent["FOV"] * 3.05
            Circle.Position = Vec2(Mouse)

            return Circle
        end

        local UpdateTracerFOV = function()
            if not TracerCircle then
                return TracerCircle
            end

            TracerCircle.Visible = getgenv().Genetic.Tracer["ShowFOV"]
            TracerCircle.Radius = getgenv().Genetic.Tracer["FOV"]
            TracerCircle.Position = Vec2(Mouse)

            return TracerCircle
        end

        game.RunService.RenderStepped:Connect(function ()
            UpdateTracerFOV()
            UpdateSilentFOV()
        end)

        local WallCheck = function(destination, ignore)
            if getgenv().Genetic.Silent.WallCheck then
                local Origin = Camera.CFrame.p
                local CheckRay = Ray.new(Origin, destination - Origin)
                local Hit = game.workspace:FindPartOnRayWithIgnoreList(CheckRay, ignore)
                return Hit == nil
            else
                return true
            end
        end

        GetClosestToMouse = function()
            local Target, Closest = nil, 1 / 0

            for _, v in pairs(Players:GetPlayers()) do
                if (v.Character and v ~= Client and v.Character:FindFirstChild("HumanoidRootPart")) then
                    local Position, OnScreen = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
                    local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                    if
                        (Circle.Radius > Distance and Distance < Closest and OnScreen and
                            WallCheck(v.Character.HumanoidRootPart.Position, {Client, v.Character}))
                     then
                        Closest = Distance
                        Target = v
                    end
                end
            end
            return Target
        end

        function TargetChecks(Target)
            if getgenv().Genetic.Silent.KOCheck == true and Target.Character then
                return Target.Character.BodyEffects["K.O"].Value and true or false
            end
            return false
        end

        function PredictionictTargets(Target, Value)
            return Target.Character[getgenv().Genetic.Silent.AimPart].CFrame +
                (Target.Character[getgenv().Genetic.Silent.AimPart].Velocity * Value)
        end

        local WTS = function(Object)
            local ObjectVector = Camera:WorldToScreenPoint(Object.Position)
            return Vector2.new(ObjectVector.X, ObjectVector.Y)
        end

        local IsOnScreen = function(Object)
            local IsOnScreen = Camera:WorldToScreenPoint(Object.Position)
            return IsOnScreen
        end

        local FilterObjs = function(Object)
            if string.find(Object.Name, "Gun") then
                return
            end
            if table.find({"Part", "MeshPart", "BasePart"}, Object.ClassName) then
                return true
            end
        end
        GetClosestBodyPart = function(character)
            local ClosestDistance = 1 / 0
            local BodyPart = nil
            if (character and character:GetChildren()) then
                for _, x in next, character:GetChildren() do
                    if FilterObjs(x) and IsOnScreen(x) then
                        local Distance = (WTS(x) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if getgenv().Genetic.Tracer.UseFOV == true then
                            if (TracerCircle.Radius > Distance and Distance < ClosestDistance) then
                                ClosestDistance = Distance
                                BodyPart = x
                            end
                        else
                            if (Distance < ClosestDistance) then
                                ClosestDistance = Distance
                                BodyPart = x
                            end
                        end
                    end
                end
            end
            return BodyPart
        end

        Mouse.KeyDown:Connect(
            function(Key)
                if (Key == getgenv().Genetic.Tracer.Toggle:lower()) then
                    if getgenv().Genetic.Tracer.Enabled == true then
                        On = not On
                        if On then
                            prey2 = GetClosestToMouse()
                        else
                            if prey2 ~= nil then
                                prey2 = nil
                            end
                        end
                    end
                end
                if (Key == getgenv().Genetic.Silent.Toggle:lower()) then
                    if getgenv().Genetic.Silent.Enabled == true then
                        getgenv().Genetic.Silent.Enabled = false
                    else
                        getgenv().Genetic.Silent.Enabled = true
                    end
                end
            end
        )

        RS.RenderStepped:Connect(
            function()
                if prey then
                    if prey ~= nil and getgenv().Genetic.Silent.Enabled and getgenv().Genetic.Silent.ShootNearestPart == true then
                        getgenv().Genetic.Silent["AimPart"] = tostring(GetClosestBodyPart(prey.Character))
                    end
                end
                if prey2 then
                    if
                        prey2 ~= nil and not TargetChecks(prey2) and getgenv().Genetic.Tracer.Enabled and
                            getgenv().Genetic.Tracer.TraceNearestPart == true
                     then
                        getgenv().Genetic.Tracer["AimPart"] = tostring(GetClosestBodyPart(prey2.Character))
                    end
                end
            end
        )

        local TracerPredictioniction = function(Target, Value)
            return Target.Character[getgenv().Genetic.Tracer.AimPart].Position +
                (Target.Character[getgenv().Genetic.Tracer.AimPart].Velocity / Value)
        end

        RS.RenderStepped:Connect(
            function()
                if
                    prey2 ~= nil and not TargetChecks(prey2) and getgenv().Genetic.Tracer.Enabled and
                        getgenv().Genetic.Tracer.SmoothnessEnabled == true
                 then
                    local Main = CFrame.new(Camera.CFrame.p, TracerPredictioniction(prey2, getgenv().Genetic.Tracer.Prediction))
                    Camera.CFrame =
                        Camera.CFrame:Lerp(
                        Main,
                        getgenv().Genetic.Tracer.Smoothness,
                        Enum.EasingStyle.Elastic,
                        Enum.EasingDirection.InOut,
                        Enum.EasingStyle.Sine,
                        Enum.EasingDirection.Out
                    )
                elseif prey2 ~= nil and getgenv().Genetic.Tracer.Enabled and getgenv().Genetic.Tracer.SmoothnessEnabled == false then
                    Camera.CFrame =
                        CFrame.new(Camera.CFrame.Position, TracerPredictioniction(prey2, getgenv().Genetic.Tracer.Prediction))
                end
            end
        )

        local grmt = getrawmetatable(game)
        local index = grmt.__index
        local properties = {
            "Hit"
        }
        setreadonly(grmt, false)

        grmt.__index =
            newcclosure(
            function(self, v)
                if Mouse and (table.find(properties, v)) then
                    prey = GetClosestToMouse()
                    if prey ~= nil and getgenv().Genetic.Silent.Enabled and not TargetChecks(prey) then
                        local endpoint = PredictionictTargets(prey, getgenv().Genetic.Silent.Prediction)

                        return (table.find(properties, tostring(v)) and endpoint)
                    end
                end
            return index(self, v)
        end
    )

    if getgenv().Genetic.Silent.AutoPrediction == true then
        local pingvalue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        local split = string.split(pingvalue, '(')
        local ping = tonumber(split[1])
        if ping < 130 then
            getgenv().Genetic.Silent.Prediction = 0.151
        elseif ping < 125 then
            getgenv().Genetic.Silent.Prediction = 0.149
        elseif ping < 110 then
            getgenv().Genetic.Silent.Prediction = 0.146
        elseif ping < 105 then
            getgenv().Genetic.Silent.Prediction = 0.138
        elseif ping < 90 then
            getgenv().Genetic.Silent.Prediction = 0.136
        elseif ping < 80 then
            getgenv().Genetic.Silent.Prediction = 0.134
        elseif ping < 70 then
            getgenv().Genetic.Silent.Prediction = 0.131
        elseif ping < 60 then
            getgenv().Genetic.Silent.Prediction = 0.1229
        elseif ping < 50 then
            getgenv().Genetic.Silent.Prediction = 0.1225
        elseif ping < 40 then
            getgenv().Genetic.Silent.Prediction = 0.1256
        end
    end

    if getgenv().Genetic.Tracer.AutoPrediction == true then
        local pingvalue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        local split = string.split(pingvalue, '(')
        local ping = tonumber(split[1])
        if ping < 130 then
            getgenv().Genetic.Tracer.Prediction = 0.151
        elseif ping < 125 then
            getgenv().Genetic.Tracer.Prediction = 0.149
        elseif ping < 110 then
            getgenv().Genetic.Tracer.Prediction = 0.146
        elseif ping < 105 then
            getgenv().Genetic.Tracer.Prediction = 0.138
        elseif ping < 90 then
            getgenv().Genetic.Tracer.Prediction = 0.136
        elseif ping < 80 then
            getgenv().Genetic.Tracer.Prediction = 0.134
        elseif ping < 70 then
            getgenv().Genetic.Tracer.Prediction = 0.131
        elseif ping < 60 then
            getgenv().Genetic.Tracer.Prediction = 0.1229
        elseif ping < 50 then
            getgenv().Genetic.Tracer.Prediction = 0.1225
        elseif ping < 40 then
            getgenv().Genetic.Tracer.Prediction = 0.1256
        end
    end
