-- Zenix Hub — Rayfield Key System Tab (Fixed)
-- Place as a LocalScript in StarterPlayerScripts
-- Adds "Key System" tab (Verify / Get Link / Buy Premium) using Rayfield.
-- No stray 'then' tokens; corrected syntax.

local Config = {
    api = "8aa9d30d-a07e-4c61-8b48-e45ec72c7ea1",
    service = "ZenixHub",
    provider = "ZenixHub",
    executor = "https://api.junkie-development.de/api/v1/luascripts/public/69e4d0498362da54c65a71467bdbe06a701478d70f2543f61b1ddecba3669bca/download",
    webhook = "https://api.junkie-development.de/api/v1/webhooks/execute/ab22dc93-08a4-4d59-aea7-8ddfcbae8a4b",
    premium = "https://discord.gg/MKEz87cBU"
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then
    warn("LocalPlayer not found. Run this as a LocalScript in StarterPlayerScripts.")
    return
end

-- Load Rayfield
local Rayfield
do
    local ok, rf = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if not ok or type(rf) ~= "table" then
        warn("Failed to load Rayfield UI.")
        return
    end
    Rayfield = rf
end

-- safe notify helper
local function Notify(title, content, duration)
    pcall(function()
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({Title = title or "ZenixHub", Content = content or "", Duration = duration or 3})
        end
    end)
end

-- Load Junkie SDK safely
local function LoadJunkie()
    local ok, sdk = pcall(function()
        return loadstring(game:HttpGet("https://junkie-development.de/sdk/JunkieKeySystem.lua"))()
    end)
    if ok and type(sdk) == "table" then
        return sdk
    end
    Notify("Key System", "Failed to load Junkie SDK.", 4)
    return nil
end

-- Verify key flow
local function VerifyKeyFlow(key)
    key = tostring(key or ""):gsub("%s+","")
    if key == "" then
        Notify("Key System", "Please enter a key.", 3)
        return
    end

    Notify("Key System", "Validating key...", 2)
    local sdk = LoadJunkie()
    if not sdk then return end

    local ok, success = pcall(function()
        return sdk.verifyKey(Config.api, key, Config.service)
    end)

    if ok and success then
        Notify("Key System", "Key valid! Loading executor...", 3)

        -- best-effort webhook
        pcall(function()
            HttpService:PostAsync(Config.webhook, HttpService:JSONEncode({key = key, user = tostring(player)}), Enum.HttpContentType.ApplicationJson)
        end)

        -- load executor
        pcall(function()
            local body = game:HttpGet(Config.executor)
            if body and #body > 0 then
                local f, err = loadstring(body)
                if f then
                    f()
                else
                    Notify("Executor", "Failed to load executor: "..tostring(err), 4)
                end
            else
                Notify("Executor", "Empty executor body.", 4)
            end
        end)
    else
        Notify("Key System", "Invalid key or verification failed.", 3)
    end
end

-- Get key link flow
local function GetKeyLinkFlow()
    local sdk = LoadJunkie()
    if not sdk then return end
    local ok, link = pcall(function()
        return sdk.getLink(Config.api, Config.provider, Config.service)
    end)
    if ok and link then
        if setclipboard then
            pcall(setclipboard, link)
            Notify("Key System", "Key link copied to clipboard.", 3)
        else
            Notify("Key System", "Key link: "..tostring(link), 6)
        end
    else
        Notify("Key System", "Failed to get key link.", 3)
    end
end

-- Buy premium flow
local function OpenPremiumFlow()
    if setclipboard then
        pcall(setclipboard, Config.premium)
        Notify("Premium", "Premium link copied to clipboard.", 3)
    else
        Notify("Premium", "Visit: "..Config.premium, 5)
    end
end

-- Create Rayfield window (single)
local Window = Rayfield:CreateWindow({
    Name = "Zenix Hub",
    LoadingTitle = "Zenix Hub",
    LoadingSubtitle = "Key System",
    ConfigurationSaving = { Enabled = true, FolderName = "ZenixHub" },
    ToggleUIKeybind = "K"
})

-- Key System tab
local KeyTab = Window:CreateTab("Key System", 4483362458)
KeyTab:CreateSection("Junkie Key System")

-- Input field
local currentKey = ""
KeyTab:CreateInput({
    Name = "Key",
    PlaceholderText = "Enter your key here...",
    Value = "",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        currentKey = text
    end
})

-- Verify Key button
KeyTab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        task.spawn(function()
            VerifyKeyFlow(currentKey)
        end)
    end
})

-- Get Link button
KeyTab:CreateButton({
    Name = "Get Link",
    Callback = function()
        task.spawn(GetKeyLinkFlow)
    end
})

-- Buy Premium Key button
KeyTab:CreateButton({
    Name = "Buy Premium Key",
    Callback = function()
        OpenPremiumFlow()
    end
})

KeyTab:CreateLabel("Use 'Get Link' to copy the free key link, paste a key above, then press 'Verify Key' to validate and load the executor.")
Notify("ZenixHub", "Key System tab added (fixed syntax).", 3)