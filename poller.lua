--[[
  Roblox Executor MongoDB Script Runner
  
  Paste this into your executor. It polls your server for
  scripts stored in MongoDB and executes them.
  
  HOW IT WORKS:
  1. You type a script on the website (localhost:3001)
  2. This script checks the server every 3 seconds
  3. It finds your script and runs it with loadstring
  4. You control Roblox from your website through MongoDB
  
  SETUP:
  1. Make sure your Node.js server is running (npm start)
  2. Change SERVER_URL below if needed
  3. Paste this whole script into your executor
]]

-- ============================================
-- CHANGE THIS TO YOUR SERVER URL
-- ============================================
local SERVER_URL = "https://lua-script-manager-production.up.railway.app"
local POLL_INTERVAL = 10 -- seconds between checks (increased for better FPS)

-- Track which commands we've already executed
local executedCommands = {}

-- ============================================
-- HTTP REQUEST (works with most executors)
-- ============================================
local function httpGet(url)
    -- Try executor's httprequest first (Synapse, Script-Ware, Fluxus, etc.)
    local httpreq = httprequest or request or http_request or syn.request or fluxus.request
    
    if httpreq then
        local response = httpreq({
            Url = url,
            Method = "GET"
        })
        return response.Body
    end
    
    -- Fallback to game's HttpService (works in Studio)
    local HttpService = game:GetService("HttpService")
    return HttpService:GetAsync(url)
end

local function httpPost(url, data)
    local httpreq = httprequest or request or http_request or syn.request or fluxus.request
    
    if httpreq then
        local response = httpreq({
            Url = url,
            Method = "POST",
            Body = data,
            Headers = { ["Content-Type"] = "application/json" }
        })
        return response.Body
    end
    
    local HttpService = game:GetService("HttpService")
    return HttpService:PostAsync(url, data, Enum.HttpContentType.ApplicationJson)
end

-- ============================================
-- JSON DECODE (works with most executors)
-- ============================================
local function jsonDecode(str)
    -- Try game's HttpService
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(str)
    end)
    if success then return result end
    
    -- Simple JSON decode fallback for arrays/objects
    -- This handles the basic response format from our API
    return loadstring("return " .. str)()
end

-- ============================================
-- EXECUTE SCRIPT FROM MONGODB
-- ============================================
local function handleCommand(cmd)
    -- Run the Lua code straight from MongoDB
    local func, err = loadstring(cmd.luaCode)
    if not func then
        return false
    end
    
    -- Execute it directly without extra overhead
    local success, result = pcall(func)
    return success
end

-- ============================================
-- POLLING LOGIC
-- ============================================
local function pollMongoDB()
    local success, response = pcall(function()
        return httpGet(SERVER_URL .. "/api/commands/pending")
    end)
    
    if not success or not response then
        return
    end
    
    local data = jsonDecode(response)
    if not data or not data.success then
        return
    end
    
    if not data.commands or #data.commands == 0 then
        return
    end
    
    for _, cmd in ipairs(data.commands) do
        if executedCommands[cmd.name] then
            continue
        end
        
        handleCommand(cmd)
        executedCommands[cmd.name] = true
        pcall(function()
            httpPost(SERVER_URL .. "/api/commands/" .. cmd.name .. "/executed", "{}")
        end)
    end
end

-- ============================================
-- START POLLING
-- ============================================
while true do
    pollMongoDB()
    wait(POLL_INTERVAL)
end
