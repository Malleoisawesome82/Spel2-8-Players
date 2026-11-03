Version = "0.10.3.5b"
-- ## ONLINE MANAGER ## --
-- Function : Handle the server-client connection and instructions. Sends inputs over the network and tries to keep games in sync
-- if you're wondering why the server code doesn't exist here, it's because this is a beta test version. 

-- values shared between the online and local co-op managers
--[[ patch notes release.backup.patch.iteration

*breaks compatibility with previous versions

0.10.0 
    fixed issue where characters with custom heart colors did not render their offscreen icon
    added resync button

0.10.1 - post test disaster
    fixed when player disconnects from session in character select, the game still waits for them to select character
    fixed when leaving server after choosing character, inputs aren't accepted and game is softlocked (client side issue)
    fixed options.debugDesync not being cleared when in menu
    maybe fixed refresh rates above 60hz can cause issues when going into the character select menu
    fixed players being able to select characters when not supposed to
    fixed when level transition is 'skipped,' players 5-8 are duplicated (8p local)
    fixed extra players appear in the wrong spot during level transition, making it hard to tell where they are (8p local)
    fixed when player is in options menu, game gets stuck
    slightly adjusted how checksums are created to be more accurate
    added "minimum delay" so players can't drag the session down by lagging
    fixed disconnected players not having their input buffer automatically filled (server side issue)
    fixed when a rewind happens, extra players lose the ability to control themselves and become hired hands
    maybe fixed when a rewind happens, sometimes extra players are set to an invalid state
    fixed when a rewind happens, not all players rewind sometimes, causing the game to permanently halt
    fixed when player disconnects during attempting resync, server doesn't keep looking for their checksum
    fixed it so when a player disconnects, their players stop appearing
    added nametags to player HUDs ingame 
    fixed after a rewind happens, sometimes the game doesn't pause when reaching the end of the input buffer, causing continuous desyncs 

0.10.2 - private test success, and some extra polish
    added a shortcut option for the host
    fixed olmec cutscene desync
    online menu input fields now save your data.
    IDs no longer stack when trying to repeatedly join a server
    automatic input buffer slightly adjusted so it doens't mainly cause slowdowns
0.10.3 
    hotfixes. this should be the most stable version as of now.
    added network profiles which adjust the online manager and game's behavior based on the network environment
    Minimum input buffer has been lowered to 1 only for Multi-Instance Sessions
    all clients who aren't host now properly remove players who disconnect from the game.
    "Restart Session" button should be 100% consistent
]]






TestValue = "Is it working, spongebob?"
Online = {
    PlayersCBC = {0, 0, 0, 0, 0, 0, 0, 0},
    PlayerIndex = 0, -- Index where your player list starts
    ActiveSlots = {false, false, false, false},
    Chars = {0, 0, 0, 0},
    Active = false,
    UIDs = {-1, -1, -1, -1, -1, -1, -1, -1},
    Buttons = {0, 0, 0, 0, 0, 0, 0, 0},
    Reset = false,
}
------------------------------------------------ ^^^^^^^^^^^^ global variables shared between managers go up here above this line ^^^^^^^^^^^^^^^^^^ -----------------------------------------------------------------------
P8 = require "8_player_local"
--Replay = require "replay"

meta.name = "8 Player Adventure Co-op Mod"
meta.version = Version
meta.description = [[Allows you to create a personal, self-hosted server and lets up to 8 simultaneous players join you in adventure mode. Also compatible with LAN environments in case you don't have a wifi signal.

The mod is considered "unsafe" due to the requirement of UdpServer methods. Hosting a server will require knowledge on how to port forward and assumes any risk that comes with hosting a server on the internet. 

Features: 
+8 player adventure mode 
+Online / LAN / Dual Instance Multiplayer Capability 
+Desync correction
+Change seeded run value any time
+Start in 1-1, 1-4, 3-1, 5-1, 7-5

]]
meta.author = "Malleoisawesome82"
meta.online_safe = false
meta.unsafe = true

--debug printing
NetProfileStr = "Wi-Fi (Good)\0Wi-Fi (Poor)\0LAN\0Multi-Instance Session\0\0"
NetProfileDesc = [[ Network Profile | Change which profile to use based on your connection type to optimize session smoothness -----------------------------

Wifi (Good) | Use when in the same/neighboring contintent as the Host.
Wifi (Poor) | Use if the wireless connection is poor, or the session keeps stuttering.
LAN | You're connected to the same Modem/Router as the Host.
Multi-Instance Session | You're running two or more Spelunky 2 instances on the same computer.
-----------------------------------------
]]
register_option_combo("NetProfile","Network Profile",NetProfileDesc, NetProfileStr, 1)

register_option_bool("enableprintstatements", "Enable Print Statements", "Prints the incoming data of packets from the server (and clients if applicable)", false)
register_option_bool("drawinputbuffer", "Draw Input Buffer", "Draws all relevant input buffers to screen", false)
register_option_bool("serverdebuginfo", "Show Debug Server Info", "Shows server debug into in the top left corner", false)
register_option_bool("printratio", "Show Debug Auto-Adjust Ratio", "Shows ratio of connection stability used for adjusting the input buffer", false)
register_option_bool("inputbufferautoadjust", "Auto-Adjust input buffer size", "Automatically adjusts the input buffer size based on how much lag is occuring", true)
register_option_bool("debugDesync","DEBUG: test desync", "test desyncing for single-instance sessions", false)
register_option_bool("debugChecksum","DEBUG: display created checksum", "pirnt checksum to humanly compare with host", false)

forceUpdateState = false
UpdatedSeed = false
clientChars = {193, 193, 193, 193}
StartAdventure = false
WaitingForClients = false
Socket = nil
Server = nil
SpelunkerNames = {"Ana", "Colin", "Margaret", "Roffy", "Alto", "Liz", "Nekka", "L.I.S.E.", "Coco", "Manfred", "Little Jay", "Tina", "Valerie", "Au", "Demi", "Pilot", "Airyin", "Guy", "Dirk", "Classic Guy"}
saveData = {
    Name = "Your Name Here",
    IP = "127.0.0.1",
    Port = 0,
    BufferSize = 0,
}
name = tostring(SpelunkerNames[math.floor((math.random()*1000)%20+1)])
hostIP = "127.0.0.1"
hostPort = 20799
myIP = "0.0.0.0"
myPort = 20799



local oldName = name
password = tostring(SpelunkerNames[math.floor((math.random()*1000)%20+1)]).." "..tostring(math.floor(math.random()*10000))
password = ""
menu = 0
timer = 0
statusIndex = 1
myPlayerID = 0
Players = {}
ShortPlayers = {} -- Short hand name of players based on which characters they control
minBuffer = 0
Spelunkers = {}
heartBeatTimer = 0
serverPacket = {}
ClientsControlling = {0, 0, 0, 0, 0, 0, 0, 0}
playersControlledByClient = {0, 0, 0, 0, 0, 0, 0, 0}
activatedSlots = {false, false, false, false}
Resets = -1
serverState = 0
Combos = {
    StartingArea = 1
}

Shortcut = 
{
    {1, 1, THEME.DWELLING},
    {1, 4, THEME.DWELLING},
    {3, 1, THEME.OLMEC},
    {5, 1, THEME.ICE_CAVES},
    {8, 5, THEME.COSMIC_OCEAN},
    ID = 1
}
--[[ only applies if online
0 - server is accepting players
1 - server is not accepting players
3 - initiate character select
4 - continue char select/waiting for adventure to begin
8 - playing adventure, waiting for other players

]]
Status = { -- server state status
    "Disconnected",
    "Connecting...",
    "Connected",
    "Timed out",
    "Kicked",
    "Network socket failure: check your inputs and try again",
    "Failed to bind to port",
    "Waiting...",
    "Hosting Online",
    "Host Creating server...",
    "Host Server quit",
    "Bad Port: Try between a range of 1-65535",
    "Password Rejected",
    "Network socket failure: local socket failed to bind to port",
    "Packet Rejeted: Server not open to players",
    "Adventure time",
    "Custom"
}
packet = ""
timeout = {}
inputCallback = -1
onDeathCallback = -1

ClientsWaiting = {}
framesSinceLastLag = 0
frametimefromserver = 0
frametimefromclient = {}
serverframetime = 0
myframetime = 0
frametimeorigin = 0
leveltimeold = 0
myinputbuffer = {{}, {}, {}, {}}
myinputbuffersize = 3
inputbufferfromclients = {}
inputbufferfromserver = {}
inputbufferlevel = {}
clientsconnected = {}
CharsControlledBy = {0, 0, 0, 0, 0, 0, 0, 0}
ServerChars = {193, 193, 193, 193, 193, 193, 193, 193}
onlineSeed = math.random(0, 999999999) -- the number looks arbitrary but seeded runs are a 4-byte long number. a byte is a number that counts from 00 to FF, or 0 to 255
onlineSeedStr = "FEEDC0DE" -- seed as a string
nextSeed = 0
TimeSinceLastPulse = 0 -- client var
savedinputindex = {-1, -1, -1, -1, -1}

InputUIDs = {-1, -1, -1, -1}

SaveState = {
    frametime = 0,
    Saved = false

}

InputSync = { -- there is nothing to keep the game worlds in sync with eachother.
    WorldFrame = 0, -- keep track of the game's framecount
    WorldFrameOld = -1, -- previous frame count, used to detect slowed game speeds (anything less than 60 fps will cause a desync without syncing)
    MyFrame = 0, -- myframetime.
    Offset = 0 -- used to synchronize WorldFrame and MyFrame for calculation purposes
}

function GetValidPlayers()
    local ValidPlayers = 0
    for i=1, 8, 1 do
        if ServerChars[i] > 193 then ValidPlayers = ValidPlayers + 1 end
    end
    return ValidPlayers
end

function KillAllPlayers(Specific, id)
    Specific = Specific or false
    id = id or -1
    for i=1, 4, 1 do -- kill all players. 1-4
        local nubby = get_player(i)
        if (nubby ~= nil and nubby.uid > 1 and not Specific) or (Specific and i == id) then kill_entity(nubby.uid) end
    end
    for i=5, 8, 1 do -- kill all players 5-8
        local nubby = Online.UIDs[i]
        if (nubby > 1 and not Specific) or (Specific and i == id) then kill_entity(nubby) end
    end
end

framebufferclock = { -- auto adjusts the frame buffer based on how much lag there is
    Rate = 0, -- how long the clock takes to tick
    Frame = 0, -- frame since last tick
    PreviousFrameTime = 0, -- if this value matches current frame time, that means lag is happening
    TotalLagFrames = 0, -- how many lag frames there were during the current tick
    Speed = 0, -- Speed is calculated by doing Rate / (Rate + TotalLagFrames - myinputbuffersize). this allows the game to decide it's running too far ahead and lower the buffer
    MinSpeed = 0, -- the minimum speed the game is allowed to run at. 
    MaxSpeed = 0, -- how fast the game needs to run to decrease the frame buffer
}

-- system used to rollback the session into a state where everybody is synced up if a desync occurs. 
-- if stuck in an infinite loop of desync, it rolls back to the start of the level. if it is still stuck, it force kills everyone. if it is still stuck, it quits out of the server and prints "LOBBY DESYNCED. DISCONNECTED."
Resync = {
    TimeOnThisFrame = 0,
    ThisFrame = 0,
    Frametime = 0,
    CurrentSlot = 2,
    Locked = false, -- if true, it just means that the game is loading the next screen and won't run any functions
    Desynced = false, -- checks if players are desynced on the current frame. 
    LoopAmounts = {1, 4, 2*4, math.huge}, -- amount of times to execute each phase. phase 3 is multiplied by 4 to allow the game to fully start a new run and catch up before attempting loop.
    LoopIndex = 1,
    LoopCount = 0,
    Reset = function()
        Resync.Desynced = false
        Resync.LoopIndex = 1
        Resync.LoopCount = 0
        Checksum.ServerGood = true
    end,
    Tick = function() -- check for desyncs and respond appropriately based on input data
        Resync.Desynced = false
        --check

        Resync.Desynced = not Checksum.ServerGood
        --response
        if Resync.Desynced then
            --LoadStateInputReset()
            if Resync.LoopIndex == 1 then 
                load_state(1)
                prinspect(Online.UIDs)
                --take back input from extra players
                for i=5, 8 do
                    if Online.UIDs[i] > 0 then 
                        return_input(Online.UIDs[i])
                        steal_input(Online.UIDs[i])
                    end
                end
                --myframetime = Resync.Frametime + 150
                --if Server ~= nil then serverframetime = Resync.Frametime +150 end
            end -- phase 1, try quickload only and increment loop count
            if Resync.LoopIndex == 2 then load_state(1) end -- phase 2, restart level
            if Resync.LoopIndex == 3 and Resync.LoopCount%4 == 0 then KillAllPlayers() end -- phase 3, kill everyone and reset run
            if Resync.LoopIndex == 4 then LeaveOnlineGame("Desyncronization ended lobby. Tell the dev he's a NOOB.") end -- phase 4, quit
            Resync.LoopCount = Resync.LoopCount + 1
            
            if Resync.LoopAmounts[Resync.LoopIndex] <= Resync.LoopCount then
                Resync.LoopIndex = Resync.LoopIndex + 1
                Resync.LoopCount = 0
            end
        else
            --print("Resync.Desynced = false")
            save_state(2)
            --Resync.Frametime = state.time_level
            Resync:Reset()
        end
        --print("Finished Resync:Tick()")
    end,
    LevelStart = function()
        for i=1, 4, 1 do InputUIDs[i] = -1 end 
        save_state(1) -- state 1 reserved for screen starts
        save_state(2) -- state 2 reserved for mid level quick load
        Resync.Frametime = 0
    end
}

--player position validation. done on the 20 of every 100 tick pulse. 
--[[the way the checksum works is... 
    numbers are indication of expected order of operation in best case scenario (first occurence)

    SERVER SIDE -
    1. the server creates positional checksum on the 2nd of every 100 tick pulse
    3. if all clients sent a checksum, the server sends a checksum to all the clients on the 30th and 50th
    4. if not all the clients sent a checksum, it assumes a desync occured and rewinds to prevent clients losing data
    
    CLIENT SIDE -
    1. the client creates positional checksum on the 2nd of every 100 tick pulse
    2. the data is sent to the server on the 2nd, 10th, and 30th
    5. if the checksum is not validated because of no reply or bad checksum or no message from clients, the game will rollback

    checksum is a 12 digit decimal number comprised of the added positions of all players X and Y
    
]]
Checksum = {
    Warn = false,
    Printed = false, -- var needed for printing the debug info ONCE for when a desync occurs
    Client = -1,
    Host = -1,
    ServerGood = false,
    AllGood = false,
    ClientSent = {},
    ClientGood = {},
    ClientData = {},
    ServerData = -1,
    Make = function()
        local x = 0
        local y = 0
        for i=1, 4, 1 do 
            local nubby = get_player(i, true)
            if nubby ~= nil and nubby.uid > 1 then 
                x = x + nubby.abs_x*100
                y = y + nubby.abs_y*100
            end
        end
        for i=5, 8, 1 do 
            local nubby = Online.UIDs[i]
            if nubby > 1 and get_entity(nubby) ~= nil then 
                x = x + get_entity(nubby).abs_x*100
                y = y + get_entity(nubby).abs_y*100
            end
        end
        local Checksum = math.abs(math.floor(x%1000000)) + math.abs(math.floor((y%1000000)*100000))
        if options.debugChecksum then prinspect("CHECKSUM CREATED: "..Checksum) end
        return Checksum
    end,
    ServerDataReset = function() -- align data 
        Checksum.ClientSent = {}
        Checksum.ClientGood = {}
        Checksum.ClientData = {}
        for i=1, #Players, 1 do
            table.insert(Checksum.ClientSent, false)
            table.insert(Checksum.ClientGood, false)
            table.insert(Checksum.ClientData, -1)
        end
    end
}

function LoadStateInputReset() -- steal_input() function has a bug where if you save state, steal input, then load a state, that captured entity no longer has the hook attached to it and input needs to be released before being stolen again
    for i=1, 4, 1 do 
        if InputUIDs[i] > 0 then
            return_input(InputUIDs[i]) -- if we revert to a point in time where an entity wasn't controlled, attempting to control it again will run into the bug
            InputUIDs[i] = -1  -- since the UIDs can change via reverting from death, they need to be reset.
        end
    end
end

function InitFrameBufferClock()
    framebufferclock.Frame = 0
    framebufferclock.PreviousFrameTime = -1
    framebufferclock.TotalLagFrames = 0
    framebufferclock.Speed = 1
    -- adjustable parameters (defaults)
    framebufferclock.MinSize = 5 -- minimum input frame buffer size
    framebufferclock.Rate = 30
    framebufferclock.MinSpeed = 0.96 -- the lowert this is, the more likely the buffer increases
    framebufferclock.MaxSpeed = 1.15 -- the higher this is, the less likely the buffer decreases
    -- 1 Wifi Near | 2 Wifi Far | 3 LAN | 4 Same computer
    if options.NetProfile == 2 then
        framebufferclock.MinSize = 7 
        framebufferclock.Rate = 60
        framebufferclock.MinSpeed = 0.98
        framebufferclock.MaxSpeed = 1.3
    end
    if options.NetProfile == 3 then
        framebufferclock.MinSize = 3 
        framebufferclock.Rate = 15
        framebufferclock.MinSpeed = 0.94
        framebufferclock.MaxSpeed = 1.09
    end
    if options.NetProfile == 4 then
        framebufferclock.MinSize = 1
        framebufferclock.Rate = 9
        framebufferclock.MinSpeed = 0.97
        framebufferclock.MaxSpeed = 1.1
    end
end

function InitPlayersForAdventure()
    local ActivePlayers = 0
    for i=1, 4, 1 do --init
        state.items.player_select[i].character = 194
        state.items.player_select[i].activated = false
        Online.Chars[i] = 0
        Online.ActiveSlots[i] = false
    end

    for i=1, 8, 1 do
        if i <= 4 then 
            if ServerChars[i] > 193 then -- first four playerscal 
                ActivePlayers = ActivePlayers + 1
                state.items.player_select[i].character = ServerChars[i] 
                state.items.player_select[i].texture = ServerChars[i]+91
                state.items.player_select[i].activated = true 
                if playersControlledByClient[i] == 0 then state.items.player_select[i].activated = false end
            end
        else -- last four players
            if ServerChars[i] > 193 then -- to get texture ID, add 91
                ActivePlayers = ActivePlayers + 1
                Online.ActiveSlots[i-4] = true
                if playersControlledByClient[i] == 0 then Online.ActiveSlots[i-4] = false end
            end
        end


    end
    state.items.player_count = GetValidPlayers()
    if state.items.player_count > 4 then state.items.player_count = 4 end
end


set_callback(function(render_ctx)
    local Names = {"", "", "", "", "", "", "", ""}

    for i=1, 8, 1 do
        -- clear playersCBC based on empty name fields
        if Players[i] == "" then for j=1, 8 do if playersControlledByClient[j] == i then playersControlledByClient[j] = 0 end end end
        if playersControlledByClient[i] > 0 then 
            Names[i] = Players[playersControlledByClient[i]] or "" 
            if #Names[i] > 4 then Names[i] = string.sub(Names[i], 1, string.find(Names[i], "#", -6)-2) end
        end
    end

    if state.screen == 12 and options.NetProfile < 4 then 
        local x, y, size, color = -0.8, 0.7, 0.007, Color:white() -- using Color:new(r,g,b,a) just doesn't work. don't ask me why the API is haunted i've been dealing with it
        color.a = 0.6
        for i=1, 8, 1 do
            if i == 5 then x, y = -0.7, -0.8 end
            if i <= 4 then render_ctx:draw_text(Names[i], x+((i-1)*0.31), y, size*0.07, size*0.07, color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.ITALIC) else
                render_ctx:draw_text(Names[i], x+((i-5)*0.45), y, size*0.07, size*0.07, color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.ITALIC) end
        end
    end

    ShortPlayers = Names
end, ON.RENDER_POST_HUD)

set_callback(function(draw_ctx)
    -- DEBUG: print input buffer
    local x = -0.9
    local y = -0.9
    local size = 25
    local color = rgba(255, 255, 255, 255)
    --draw_ctx:draw_text(0, 0, size, "Test", 4294967295)
    
    if #myinputbuffer[1] > 0 and options.drawinputbuffer then
        draw_ctx:draw_text(x, y, size, "My Input Buffer", color)
        draw_ctx:draw_text(x, y-0.04, size, "Frame Time:"..tostring(myframetime), color)
        for i=1, 4, 1 do
            for j=1, #myinputbuffer[i], 1 do
                draw_ctx:draw_text(x+(i*0.055)-0.08, y+(j*0.04), size*0.6, tostring(j)..": "..tostring(myinputbuffer[i][j]), color)
            end
        end
    end
    

    if #inputbufferfromserver > 0 and options.drawinputbuffer then
        x = 0.7
        draw_ctx:draw_text(x, y, size, "Clients' Buffer", color)
        draw_ctx:draw_text(x+0.07, y-0.04, size, "Frame Time: "..tostring(serverframetime), color)
        for i=1, #inputbufferfromserver, 1 do
            y = -0.86
            draw_ctx:draw_text(x+(i*-0.12)+0.15, y, size, "P"..tostring(i), color)
            for j=1, #inputbufferfromserver[i] do
                draw_ctx:draw_text(x+(i*-0.12)+0.15, y+(j*0.04)+0.08, size, tostring(inputbufferfromserver[i][j]), color)
            end
        end
    end

        if #inputbufferfromclients > 0 and options.drawinputbuffer then
        y = 0
        draw_ctx:draw_text(x, y, size, "Server Buffer", color)
        for i=1, #inputbufferfromclients, 1 do
            y = 0.04
            draw_ctx:draw_text(x+(i*-0.12)+0.15, y, size, "P"..tostring(i), color)
            for j=1, #inputbufferfromclients[i] do
                draw_ctx:draw_text(x+(i*-0.12)+0.15, y+(j*0.03)+0.08, size*0.8, tostring(inputbufferfromclients[i][j]), color)
            end
        end
    end

    if state.screen == 4 or menu > 0 then
        color = rgba(255, 255, 255, 127)
        local extra = state.screen == 12 and (myframetime-150-state.time_level) ~= 0 and tostring("+"..(myframetime-150-state.time_level)) or ""
        draw_ctx:draw_text(-0.98, -0.92, size*0.6, "playersCBC: "..tostring(inspect(playersControlledByClient)), color)
        draw_ctx:draw_text(-0.98, -0.95, size*0.6, "Delay: "..tostring(myinputbuffersize)..extra, color)
        color = rgba(255, 0, 0, 127)
        if Checksum.Warn and state.screen == 12 then draw_ctx:draw_text(0.8, -0.95, size*0.6, "Warning: Desync Detected ", color) end
        color = rgba(255, 255, 0, 127)
        if not Checksum.ServerGood and state.screen == 12 then draw_ctx:draw_text(-0.8, -0.95, size*0.6, "Attempting Resync...", color) end

        window("8 player online "..Version, -0.5, 0.5, 0.5, 0.8, true, function()
            win_text("Server Status: "..Status[statusIndex])
            win_separator()
            local PlayersOnline = 0
            for i=1, #Players, 1 do
                if #Players[i] > 1 then PlayersOnline = PlayersOnline + 1 end
            end
            win_text("Players online: "..PlayersOnline)
            for i=1, #Players, 1 do
                win_text(tostring("Player "..i..": "..Players[i]))
            end
            win_separator()
            Online.Active = false
            if menu > 0 then Online.Active = true end
            if menu == 0 then HomeScreen() end
            if menu == 1 then HostScreen() end
            if menu == 2 then JoinScreen() end
            if menu == 3 then MakingServer() end
            if menu == 4 then JoiningServer() end
            if menu == 5 then Joined() end
            if Socket ~= nil and Socket:is_open() then
                QuitButton()
            end
        end)
    end
    if Server ~= nil and Server:is_open() then ServerTick() end
end, ON.GUIFRAME)

set_callback(function(render_ctx) --draw characters

    if not Online.Active then return end

    if serverState == 4 and myframetime < 2 then 
        
        local x = -0.95
        local y = -0.9
        local size = 0.002
        local color = Color:white()
        local xOffset = -0.05
        local txtSize = 0.1 -- texture size
        for i=1, 8, 1 do
            local Label = tostring("P"..i)
            local yOffset = (i*0.08)
            if ServerChars[i] > 193 then render_ctx:draw_text(Label, x, y+yOffset, size*0.3, size*0.3, color, VANILLA_TEXT_ALIGNMENT.LEFT, VANILLA_FONT_STYLE.BOLD) end --draws player name and character icon
            yOffset = yOffset + 0.04
            if ServerChars[i] > 193 then render_ctx:draw_screen_texture(ServerChars[i]+91, 11, 0, x+xOffset, y+yOffset, (x+txtSize*0.55)+xOffset, (y-txtSize)+yOffset, Color:white()) end
        end
        --player name
        --icon
        --render_ctx:draw_text(Players[i], x, y+yOffset, size*0.3, size*0.3, color, VANILLA_TEXT_ALIGNMENT.LEFT, VANILLA_FONT_STYLE.BOLD) --draws player name and character icon
        --if ServerChars[i] > 193 then render_ctx:draw_screen_texture(ServerChars[i]+91, 11, 0, x+xOffset, y+yOffset, (x+txtSize*0.55)+xOffset, (y-txtSize)+yOffset, Color:white()) end
    end
    if WaitingForClients then -- on char select screen waiting for clients to finish joining   
        local x, y, size, color, xOffset, Label = 0, 0.2, 0.007, Color:white(), 0, "Waiting for players..."
        render_ctx:draw_text("Waiting for players...", x, y, size*0.3, size*0.3, color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.ITALIC)
        if serverState ~= 4 then 
            WaitingForClients = false 
            frametimefromserver = 0    
        end
    end
    if state.screen >= 11 and Resets < 0 then
        local x, y, size, color, xOffset, Label = 0, 0.2, 0.007, Color:white(), 0, "Waiting for players..."
        if myframetime < 149 then 
            render_ctx:draw_text("Preparing Adventure Mode...", x, y, size*0.3, size*0.3, color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.ITALIC) 
                if myframetime > 10 then KillAllPlayers() end
        end
    end
end, ON.RENDER_POST_HUD)

function HomeScreen() -- initialization of server and client variables.
    if inputCallback > -1 then clear_callback(inputCallback) end
    name = oldName
    myframetime = 0
    serverState = 0
    heartBeatTimer = 0
    myPlayerID = 0
    StartAdventure = false
    WaitingForClients = false
    Players = {}
    ShortPlayers = {}
    timeout = {0, 0, 0, 0, 0, 0, 0, 0}
    ServerChars = {193, 193, 193, 193, 193, 193, 193, 193}
    playersControlledByClient = {0, 0, 0, 0, 0, 0, 0, 0} -- client IDs that are controlling each player instance. for example it would look like {1, 1, 1, 2, 3, 3, 0, 0} 3 on 1st, 1 on 2nd, 2 on 3rd

    
    if win_button("Host session") then
        menu = 1
    end
    if win_button("Join session") then
        menu = 2
    end
end

function HostScreen()
    inputbufferfromclients = {}
    name = win_input_text(" ",name)
    win_text("It is recommended to use your IPv4 address for hosting.")
    hostIP = win_input_text("IP", hostIP)
    hostPort = win_input_int("Port", hostPort)
    --win_text("A password is strongly recommended for games hosted on the internet.")
    --password = win_input_text("  ", password)

    if win_button("Start Server") then
        statusIndex = 10
        if hostPort < 1 or hostPort > 65536 then statusIndex = 12 end
        if statusIndex == 10 then 
            Socket = UdpServer:new("0.0.0.0", 0)
            Server = UdpServer:new(hostIP, hostPort)
            menu = 3
            timer = 0
        end
    end
    if win_button("Back") then
        menu = 0
    end
end

set_callback(function()
    if serverState < 2 then return false end
    if Socket == nil then return false end
    if not Socket:is_open() then return false end
    if state.screen_next == 4 and state.screen == 9 then return true end -- can't back out of char select menu
    if state.screen_next >= 11 then -- if the next screen is a level/base camp
        if serverState == 4 and state.screen < 11 then -- coming from char select screen
            WaitingForClients = true -- prevent the game from going to the next screen. once the server sees all clients are ready, it will update the server state and the game will advance
            play_seeded(onlineSeed)
            return 
        end
        -- if reaching this point, that means serverState == 5, and adventure is ready to start
    
        InitPlayersForAdventure()

    end
end, ON.PRE_LOAD_SCREEN)

function JoinScreen()
    name = win_input_text(" ",name)
    win_text("Server IP and Port")
    hostIP = win_input_text("IP", hostIP)
    hostPort = win_input_int("Port", hostPort)

    if win_button("Join Server") then
        Socket = UdpServer:new("0.0.0.0", 0)
        menu = 4
        timer = 0
    end
    if win_button("Back") then
        menu = 0
    end
end

function MakingServer()
    timer = timer + 1
    if Server == nil then 
        menu = 1 
        statusIndex = 6
    end
    if timer > 60 then
        if Server:is_open() then 
            menu = 4
            timer = 0
        else statusIndex = 7 end
    end
end

function JoiningServer()
    if Socket == nil then 
        statusIndex = 6 
        menu = 0
    end

    statusIndex = 2
    if Server and Server:is_open() then statusIndex = 10 end
    timer = timer + 1
    if timer == 1 then 
        if #name > 16 then name = string.sub(name, 1, 16) end
        if #name < 1 then name = tostring(SpelunkerNames[math.floor((math.random()*1000)%20+1)]) end
        oldName = name
        name = name.." #"..tostring(math.floor(math.random()*10000)) 
    end
    if timer == 30 and not Socket:is_open() then statusIndex = 14 end
    
    if timer%60 == 59 then
        packet = password.."|"..name.."|".."JoinRequest"
        Socket:send(packet, hostIP, hostPort)
    end
    Socket:read(function(data, source)
        if #data < 0 then return end
        if data == "BadPassword" then -- server accepting players but rejects password
            print(password)
            menu = 2
            statusIndex = 13
            Socket:close()
            name = oldName
        end
        if data == "PacketRejected" then -- server not accepting players
            menu = 2
            statusIndex = 15
            Socket:close()
            name = oldName
        end
        if string.sub(data, 1, 6) == "JoinOK" then -- server accepts password, player names are instantly sent
            menu = 5
            timer = 0
            local inPacket = {""}
            local j = 1
            for i=1, #data, 1 do
                if string.sub(data, i, i) == "|" then
                    i = i + 1
                    j = j + 1
                    inPacket[j] = ""
                else inPacket[j] = inPacket[j]..string.sub(data, i, i)
                end
            end
            --printer#inPacket)
            Players = {"", ""}
            for i=3, #inPacket, 1 do
                Players[i-2] = inPacket[i]
            end

            printer(inPacket[2])
            serverState = inPacket[2]
            if Players[2] == "" then table.remove(Players, 2) end
            for i=1, #Players, 1 do
                if Players[i] == name then myPlayerID = i break end
            end
            if serverFunctionCheck() == false then serverState = 1 end
            -- inputCallback = set_callback(function() return true end, ON.PRE_PROCESS_INPUT) -- disable player inputs
        end
    end)
    if timer > 60*15 then
        menu = 2
        statusIndex = 4
        Socket:close()
        state.level_flags = set_flag(state.level_flags, 20)
        name = oldName
    end

end

function LeaveOnlineGame(warn)
        state.fade_enabled = true
        options.debugDesync = false
        state.screen_character_select.disable_controls = false
        pause(false)
        warn = warn or ""
        Online.Active = false
        state.level_flags = set_flag(state.level_flags, 20)
        statusIndex = 1
        myPlayerID = 1
        Players = {}
        if Socket then 
            SendPacketToHost("Quit")
            Socket:close() 
            if inputCallback > -1 then clear_callback(inputCallback) end

        end
        if Server then Server:close() end
        menu = 0
        Resync:Reset()
        if string.len(warn) > 2 then 
            statusIndex = 17
            Status[17] = warn
            print("Disconnected From Server: "..warn) 
        end -- i put > 2 because i don't want future me to be sending coded letters as a message for something
end

function QuitButton()
    pause(false)
    if myPlayerID > 0 then
        win_separator()
        win_text("[YOU] Player "..myPlayerID..": "..name)
    end
    win_separator()
    if win_button("Quit session") then
        LeaveOnlineGame("Goodbye!")
    end
    win_text("")
    win_separator()
    if myPlayerID > 1 then return end
    --admin panel
    
    win_text("Admin Control Panel")

    minBuffer = win_input_int("Minimum Input Buffer for all Clients", minBuffer)
    minBuffer = minBuffer%25

    if serverState < 5 then
        win_text("")
        Combos.StartingArea = win_combo("Starting Area", Combos.StartingArea, " 1-1 \0 1-4 \0 3-1 \0 5-1\0 7-5 \0")
    end

    if not (serverState < 5) then if win_button("Restart Session (Mainly for Softlocks/Desyncs)") then
        SoftLocked()
        ClientsWaiting[1] = "false"
    end end

    if state.screen == 12 then if win_button("Resync Game") then options.debugDesync = true end
    
    end
    win_text("")
    win_text("Kick Players:")
    
    for i=2, #Players, 1 do
        if Players[i] ~= "" then if win_button("Kick "..Players[i]) then
            timeout[i] = 999*60
        end end
    end
end

function SoftLocked()
    if Server ~= nil and Server:is_open() then
        if serverState < 5 then return end
        --print("Force restarting session")
        state.fade_enabled = true
        play_seeded(onlineSeed)
        serverState = 1
        state.screen_next = 4
    end
end

function SendPacketToHost(header, message) -- data seperator is "|", packet terminator is "." since packets love to intermingle their data for some god forsaken reason
    message = message or ""
    if Socket == nil then return printer("Socket: Packet failed to send, network socket doesn't exist.") end
    packet = password.."|"..name.."|"..header.."|"..myPlayerID.."|"..message
    Socket:send(packet, hostIP, hostPort)
    
end

function SendPacketToClient(header, message, source)
    if serverFunctionCheck() then return printer("sendPacketToClient() failed to run, server function only") end
    if Server == nil then return printer("Server: Packet failed to send, network socket doesn't exist.") end
    packet = header.."|"..message
    Server:send(packet, source)
end

function serverFunctionCheck()
    if Server ~= nil and Server:is_open() then return false end
    return true
end

function newGame() -- starts a new run 

end

function prepareAdventure() -- SERVER FUNCTION
    if serverFunctionCheck() then return printer("Attempted to run 'prepareAdventure()' but this function is restricted to server execution only") end
    serverState = 3
    frametimefromclient = {}
    serverframetime = 0

end

function DecideOnlinePlayerSlotLimit(FourPlayerTest)
    FourPlayerTest = true and FourPlayerTest or false
    local RoomSize = {
        {4}, -- yes this one needs to be here
        {4, 4},
        {3, 3, 2},
        {2, 2, 2, 2},
        {2, 2, 2, 1, 1},
        {2, 2, 1, 1, 1, 1},
        {2, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1}
    }
    if FourPlayerTest then
        RoomSize = {
            {4},
            {2, 2},
            {2, 1, 1},
            {1, 1, 1, 1},
            {0, 0, 0, 0, 0},
            {0, 0, 0, 0, 0, 0},
            {0, 0, 0, 0, 0, 0, 0},
            {0, 0, 0, 0, 0, 0, 0, 0}
        }
    end
    state.screen_character_select.available_mine_entrances = RoomSize[#Players][myPlayerID]
end

function PulsePacketCharSelect() -- if host is waiting for run to start, there's a chance for this function to run when it's not supposed to, causing huge issues.
    if game_manager.game_props.input_index[1] > -1 then for i=1, 5, 1 do savedinputindex[i] = game_manager.game_props.input_index[i] end end -- it disables the screen controls by clearing all input indexes. a lazy solution, but i woulda done the same
    DecideOnlinePlayerSlotLimit() -- function should be ran immediately
    frametimeorigin = 0
    set_seed(onlineSeed)
    -- this function needs to be escaped if characters are already selected and waiting for adventure mode to start.
    local ValidPlayers = GetValidPlayers()
    inputbufferfromserer = {} -- initializes input buffer from server
    for i=1, ValidPlayers, 1 do 
        inputbufferfromserver[i] = {0}
        inputbufferlevel[i] = {0}
    end
    local p = 0
    for i=1, 4, 1 do -- how many player slots am i taking up?
        if state.items.player_select[i].activated then p = p + 1 end
        packet = tostring(p)
    end
    local a = 0
    activatedSlots = {false, false, false, false}
    packet = packet.."|"..tostring(WaitingForClients)
    for i=1, 4, 1 do
        activatedSlots[i] = state.items.player_select[i].activated -- remember this client's activated slots
        if state.items.player_select[i].activated then --add selected players into the table, ONLY if they're actually activated
            a = a + 1 
            if a > p then -- if over the allowed limit, end the loop early. 
                state.items.player_select[i].activated = false -- also disable the slot.
                break 
            end
            packet = packet.."|"..tostring(state.items.player_select[i].character)
            clientChars[i] = state.items.player_select[i].character
        end
    end  
end

function PulsePacketAdventure()
    state.screen_character_select.disable_controls = true
    local p = 0
    for i=1, 4, 1 do -- how many player slots am i taking up?
        if activatedSlots[i] then p = p + 1 end
        packet = tostring(p)
    end
    packet = packet.."|True"
    for i=1, 4, 1 do
        if activatedSlots[i] then --add selected players into the table, ONLY if they're actually activated
            packet = packet.."|"..tostring(clientChars[i])
        end
    end
    local ValidPlayers = GetValidPlayers()
    inputbufferfromserer = {} -- initializes input buffer from server
    for i=1, ValidPlayers, 1 do 
        inputbufferfromserver[i] = {0}
        inputbufferlevel[i] = {0}
    end
end

function Joined()
    -- if time since last pulse is too long, the server has long forgotten about you. off with your head!
    
    -- set save data
    saveData.Name = name
    saveData.IP = hostIP
    saveData.Port = hostPort
    saveData.BufferSize = myinputbuffersize

    --state.quest_flags = set_flag(state.quest_flags, 7) -- force seeded run mode to be activated, because sometimes it just doesn't for some reason?
    state.level_flags = clr_flag(state.level_flags, 20) -- disable pausing 
    serverState = tonumber(serverState)
    statusIndex = 3
    if Server ~= nil and Server:is_open() then statusIndex = 9 end
    heartBeatTimer = heartBeatTimer + 1

    if options.inputbufferautoadjust then -- automatic input buffer adjusting
        if serverState < 5 then -- not ready for adventure
            InitFrameBufferClock()
        else -- run frame buffer clock
            if state.screen == 12 then 
                framebufferclock.Frame = framebufferclock.Frame + 1
                if framebufferclock.Frame > framebufferclock.Rate then -- clock tick
                    if options.printratio then prinspect(framebufferclock.Rate / (framebufferclock.TotalLagFrames + framebufferclock.Rate - myinputbuffersize)) end
                    if (framebufferclock.TotalLagFrames + framebufferclock.Rate - myinputbuffersize) <= 0 then myinputbuffersize = myinputbuffersize - 1 -- input buffer is so high that it either hits NaN or wraps to negative.
                    else
                        framebufferclock.Speed = framebufferclock.Rate / (framebufferclock.TotalLagFrames + framebufferclock.Rate - myinputbuffersize)
                        if state.time_level < framebufferclock.Rate * 2 then framebufferclock.Speed = 1 end -- prevent frame buffer from changing on level start
                        if framebufferclock.Speed <= framebufferclock.MinSpeed then myinputbuffersize = myinputbuffersize + 1 end
                        if framebufferclock.Speed > framebufferclock.MaxSpeed then myinputbuffersize = myinputbuffersize - 1 end
                    end
                    framebufferclock.TotalLagFrames = 0
                    framebufferclock.Frame = 0
                end
                if myinputbuffersize > 23 then myinputbuffersize = 23 end
                if myinputbuffersize < framebufferclock.MinSize then myinputbuffersize = framebufferclock.MinSize end
            end
        end
    end

    if heartBeatTimer % 60 == 30 then -- packet format [1][2][3][4] usual header info | [5] players on my client | [6] fully ready | [7][8][9][10] char IDs
        if serverState == 5 or state.screen > 10 or WaitingForClients then PulsePacketAdventure() -- preserve local char data to send to server
        else PulsePacketCharSelect() end -- inform server of your char data
        SendPacketToHost("Pulse", tostring(packet)) 
    end
    if serverState == 0 then
        myframetime = 0
        leveltimeold = -1 
        win_text("Server is accepting players.")
        if options.NetProfile <= 2 then
            if myPlayerID == 1 and win_button("Lock player list") then
                serverState = 1
            end
        end
    end
    if serverState == 1 then 
        myframetime = 0
        leveltimeold = -1
        if options.NetProfile <= 2 then
        win_text("Server is not accepting players.")
            if myPlayerID == 1 and win_button("Unlock player list") then
                serverState = 0
            end
        end
    end


    options.NetProfile =  win_combo("Network Profile", options.NetProfile, NetProfileStr)
    
    myinputbuffersize = win_input_int("Input Buffer (Frames)", myinputbuffersize)
    myinputbuffersize = (myinputbuffersize % 23) 
    myinputbuffersize = myinputbuffersize >= framebufferclock.MinSize and myinputbuffersize or framebufferclock.MinSize
    myinputbuffersize = myinputbuffersize >= minBuffer and myinputbuffersize or minBuffer
    
    if state.screen < 12 then 
        onlineSeed = win_input_int("Seed to use", onlineSeed)
        onlineSeed = (onlineSeed % 4294967295)
    end 

    if serverState < 2 and myPlayerID == 1 then -- pre-run lobby host controls
    

    
        win_text("")
        if win_button("Start Game") then 
            for i=1, #Players, 1 do
                ClientsWaiting[i] = false
            end
            myframetime = 0
            myinputbuffer = {{}, {}, {}, {}}
            inputbufferfromserver = {}
            clientsconnected = {}
            for i=1, GetValidPlayers(), 1 do
                inputbufferfromclients[i] = {0}
            end
            prepareAdventure() 
        end
    end

    if heartBeatTimer > 60*8 then
        --printer"Socket timed out.")
        Socket:close()
        menu = 0
        statusIndex = 4
    end
    local size = 0
    while size > -1 do
        size = Socket:read(function(data)
            Online.PlayerIndex = myPlayerID
            Online.PlayersCBC = playersControlledByClient
            serverState = tonumber(serverState)
            heartBeatTimer = 0 
            local inPacket = {"", ""} -- [1] header | [2] data
            local j = 1
            for i=1, #data, 1 do
                if string.sub(data, i, i) == "|" then
                    i = i + 1
                    j = j + 1
                    inPacket[j] = ""
                else inPacket[j] = inPacket[j]..string.sub(data, i, i)
                end
            end
            
            printer("CLIENT SOCKET RECIEVED DATA:")
            printer(data)
            printer("-------------------------------")
            if inPacket[1] == "Kicked" then 
                statusIndex = 5
                LeaveOnlineGame("Kicked")
                if Server ~= nil then Server:Quit() end
                return
            end

            if inPacket[1] == "playersCBC" then -- playersControlledByClient packet. 
                for i=2, 9, 1 do
                    if myPlayerID > 1 then playersControlledByClient[i-1] = tonumber(inPacket[i]) end
                    -- disable players that disconnected so they don't appear again
                    if playersControlledByClient[i-1] == 0 then
                        if (i-1) <= 4 then --front half
                            state.items.player_select[i-1].activated = false
                        else -- back half
                            Online.ActiveSlots[i-1-4] = false
                        end
                    end
                end
                -- the last element of the packet is the minimum input buffer for ALL clients
                minBuffer = tonumber(inPacket[10])
                Shortcut.ID = tonumber(inPacket[11])
                Online.PlayersCBC = playersControlledByClient
                -- clear out names if they aren't controlling anybody
                for i=2, #Players, 1 do
                    local PlayerGone = true
                    for j=1, 8, 1 do
                        if playersControlledByClient[j] == i then PlayerGone = false break end
                    end
                    if PlayerGone then Players[i] = "" end
                end
            end
            if inPacket[1] == "ChecksumS" then
                --checksum of all clients validated by server, this is the message from that server. the online seed is also sent through here as the data to force sync the clients if the seed somehow goes haywire
                if inPacket[3] == "true" then Checksum.ServerGood = true end -- resync attempts should only be initiated by the server, since packets may be dropped.
                if inPacket[3] == "false" then Checksum.ServerGood = false end -- for some reason the "true" was being treated as a false.
                if myPlayerID > 1 and state.screen_level.time_till_death_screen > 130 then onlineSeed = tonumber(inPacket[2]) end
                if myPlayerID > 1 then minBuffer = tonumber(inPacket[4]) end
            end
            if inPacket[1] == "Pulse" then -- pulse from the server that tells clients the session is still active, the names of all players, and the list of chars
                TimeSinceLastPulse = 0
                serverState = Server ~= nil and Server:is_open() and serverState or tonumber(inPacket[2]) -- only change server state if this is a client
                local ReadingChars = {Boolean = false, Index = 0}
                ServerChars = {0, 0, 0, 0, 0, 0, 0, 0} -- clear list since clients don't do this correctly
                for i=3, #inPacket, 1 do
                    if ReadingChars.Boolean == false then 
                        if inPacket[i] ~= "CharIDs" then Players[i-2] = inPacket[i] else
                            ReadingChars.Boolean = true
                            ReadingChars.Index = i
                        end
                    else
                        ServerChars[i-ReadingChars.Index] = tonumber(inPacket[i])
                        if i-ReadingChars.Index > 4 then Online.Chars[i-ReadingChars.Index-4] = ServerChars[i-ReadingChars.Index]+91 end -- this is written to in other places but just doesn't work for some reason (untested currently)
                        --Online.Chars[i-ReadingChars.Index] = ServerChars[i-ReadingChars.Index]+91 



                    end

                end
                if serverState == 5 and state.screen == 9 then warp(Shortcut[Shortcut.ID][1], Shortcut[Shortcut.ID][2], Shortcut[Shortcut.ID][3]) end -- if everyone is ready then start adventure
                return 

                --clean up names of players
            end

            if inPacket[1] == "Quit" then Socket:close() menu = 0 statusIndex = 11 return end
            if inPacket[1] == "charSelect" then
                TimeSinceLastPulse = 0
                DecideOnlinePlayerSlotLimit() -- automatically set slot limit using the blocked off doors.
                if myPlayerID > 1 then onlineSeed = tonumber(inPacket[2]) end
                if state.screen > 4 and state.screen < 12 then return end
                serverState = 4
                state.screen_character_select.disable_controls = false
                Resets = -1
                ServerChars = {193, 193, 193, 193, 193, 193, 193, 193}
                if state.loading > 0 then return end
                play_seeded(onlineSeed)
            end
           if inPacket[1] == "ServerBuffer" then -- writes to the 'inputbufferfromserver' variable
                TimeSinceLastPulse = 0
                -- input packet format
                -- "ServerBuffer"
                -- Buffer Size Send
                local BufferFromServer = tonumber(inPacket[2])
                -- Server Frame Time
                frametimefromserver = tonumber(inPacket[3])
                -- Inputs for all players
                
                -- compensate for running in the future

                local FutureTime = frametimefromserver < myframetime and myframetime - frametimefromserver or 0
                for i=1, GetValidPlayers(), 1 do -- prepare input buffer from server
                    for j=1, BufferFromServer, 1 do
                        if j > FutureTime then inputbufferfromserver[i][j-FutureTime] = tonumber(inPacket[3+((i-1)*BufferFromServer)+j]) end
                    end
                end
            end
        end)
    end
end

function compilePlayersCBCPacket(sauce)
    local packet = tostring(playersControlledByClient[1])
    for i=2, 8, 1 do
        packet = packet..tostring("|"..playersControlledByClient[i])
    end
    packet = packet..tostring("|"..minBuffer.."|"..Combos.StartingArea)
    SendPacketToClient("playersCBC", packet, sauce)

end

function ServerTick()
    --prinspect("players Controlled By: "..inspect(playersControlledByClient))
    --prinspect("Clients Controlling: "..inspect(ClientsControlling))
    for i=1, #Players, 1 do -- timeout function for when a client loses connection
        timeout[i] = timeout[i] + 1
        if options.serverdebuginfo then win_text("Player "..tostring(i).." timeout: "..tostring((math.floor(timeout[i]/60)))) end
        if timeout[i] >= 60*8 and Players[i] ~= "" then 
        --printer"Player "..tostring(i).." timed out")
        if serverState < 2 then
                Players[i] = ""
            else
                Players[i] = ""
                for j=1, #inputbufferfromclients[i], 1 do
                    inputbufferfromclients[i][j] = 0
                end
                for j=1, 8, 1 do
                    if playersControlledByClient[j] == i then playersControlledByClient[j] = 0 end
                end
            end
        end    
    end
    if options.serverdebuginfo then win_separator() end
    if Server:is_open() and options.serverdebuginfo then win_text("SERVER ONLINE ON "..Server:address()) end
    local size = 0
    while size > -1 do
        size = Server:read(function(data, source)  
            local inPacket = {"", "", "", ""} -- [1] - password | [2] name | [3] header | [4] playerID | [5] body
            local j = 1
            for i=1, #data, 1 do
                if string.sub(data, i, i) == "|" then
                    i = i + 1
                    j = j + 1
                    inPacket[j] = ""
                else inPacket[j] = inPacket[j]..string.sub(data, i, i)
                end
            end
            printer("SERVER RECEIVED DATA: ")
            printer(data)
            printer("----------------------")
            if inPacket[1] ~= password then -- bad password
                --printer"Server: Bad password")
                Server:send("BadPassword", source)
                return -- end execution. the packet doesn't need to be read if the password is bad.
            end
            serverState = tonumber(serverState) -- prevents hosting client from inadvertendly turning server state into a string
            if serverState == 0 then -- Waiting in menu, accepting players
                if inPacket[3] == "JoinRequest" then --client trying to join. Server should give the OK and send player names
                    if #Players >= 8 then return Server:send("PacketRejected", source) end 
                    for i=1, #Players, 1 do --  
                        if Players[i] == inPacket[2] then return Server:send("PacketRejected", source) end
                    end
                    printer("Server: Good Password from "..inPacket[2])
                    packet = "JoinOK|"..tostring(serverState)

                    --find empty slot, or if none left
                    local Place = #Players+1
                    for i=1, #Players, 1 do
                        if Players[i] == "" then Place = i break end
                    end

                    Players[Place] = inPacket[2]
                    for i=1, #Players, 1 do
                        timeout[i] = 0
                        packet = packet.."|"..Players[i]
                    end
                    Server:send(packet, source)
                end
            else -- not accepting players
                if inPacket[3] == "JoinRequest" then
                    return Server:send("PacketRejected", source)
                end
            end
            if StartAdventure and serverState > 1 then -- server switches to state 5 which will indicate to clients that the adventure is ready to start
                serverState = 5
            end
            -- packet format [1][2][3][4] usual header info | [5] players on my client | [6] fully ready | [7][8][9][10] char IDs
            if inPacket[3] == "Pulse" then -- pulse from the client indicating selected characters and how many players are on their end

                local id = tonumber(inPacket[4])
                if timeout[id] >= 990*60 then
                    SendPacketToClient("Kicked", "", source)
                    return
                end


                inputbufferfromclients = {}
                for i=1, GetValidPlayers(), 1 do -- init input buffer
                    inputbufferfromclients[i] = {0}
                end
                --printer"Server: Recieved pulse packet from player "..inPacket[4])
                local PlayersOnClient = tonumber(inPacket[5])
                ClientsWaiting[id] = inPacket[6]
                ClientsControlling[id] = PlayersOnClient
                local Offset = 0
                local TotalChars = 0
                playersControlledByClient = {0, 0, 0, 0, 0, 0, 0, 0} -- this is what will help decipher input buffers sent from a client
                for i=1, 8, 1 do
                    local inputsSet = 0
                    while ClientsControlling[i] > inputsSet do
                        Offset = Offset + 1
                        TotalChars = TotalChars + 1
                        if i == id then -- set ServerChars while in the correct spot. we assume we don't have data from other clients.
                            ServerChars[Offset] = tonumber(inPacket[7+inputsSet])
                        end
                        playersControlledByClient[Offset] = i
                        inputsSet = inputsSet + 1
                    end
                    --clear serverchar if we've passed the player count
                    if i > #Players then 
                        Offset = Offset + 1
                        ServerChars[Offset] = 190 
                    end
                end

                compilePlayersCBCPacket(source)

                --place server chars into correct slot
                timeout[id] = 0
                Players[id] = inPacket[2]
                packet = tostring(serverState)
                for i=1, #Players, 1 do
                    packet = packet.."|"..Players[i]
                end
                packet = packet.."|CharIDs"
                for i=1, TotalChars, 1 do               
                    packet = packet.."|"..ServerChars[i]
                end
                SendPacketToClient("Pulse", packet, source) -- reply of pulse sends names of all players to client
                if serverState == 3 or serverState == 4 then -- only when on char select screen, however
                    packet = tostring(onlineSeed)
                    SendPacketToClient("charSelect", packet, source)
                end
                StartAdventure = true
                if #Players < 1 then StartAdventure = false end -- just incase there's no players for some reason
                for i=1, #Players, 1 do -- check if all clients are ready
                    if Players[i] == "" then ClientsWaiting[i] = true end
                    if ClientsWaiting[i] == "false" then -- remember, client can only send string
                        StartAdventure = false
                    end
                end
            end
            if inPacket[3] == "clientInput" then -- [3] | [4] client id | [5] client frametime | [6]
                
                
                local InputNil = false
                local BufferFix = {{}, {}, {}, {}, {}, {}, {}, {}}
                local clientID = tonumber(inPacket[4])
                if timeout[clientID] >= 990*60 then
                    SendPacketToClient("Kicked", "", source)
                    return
                end
                timeout[clientID] = 0
                local buffer = {}
                frametimefromclient[clientID] = tonumber(inPacket[5])
                local MinFrameTime = frametimefromclient[1]
                for i=2, #Players, 1 do -- catch up with slowest client and clear unecessary input buffer data
                    if #Players[i] > 0 then MinFrameTime = frametimefromclient[i] < MinFrameTime and frametimefromclient[i] or MinFrameTime 
                    else frametimefromclient[i] = MinFrameTime end
                end 
                -- do the actual catching up part now
                while (MinFrameTime > serverframetime) do
                    for j=1, #inputbufferfromclients, 1 do
                        table.remove(inputbufferfromclients[j], 1)
                    end
                    serverframetime = serverframetime + 1

                    if serverframetime%60 == 2 then compilePlayersCBCPacket(source) end

                end
                serverframetime = MinFrameTime -- in the event that the server is running in the future, force the server to not do that.
                BufferFix = inputbufferfromclients
                local FutureRun = (frametimefromclient[clientID] - serverframetime)
                local StartPos = 0
                for i=1, 8, 1 do
                    if clientID == playersControlledByClient[i] then StartPos = i break end -- get 
                end
                local BufferIndex = 6
                local ServerBufferIndex = 0
                while BufferIndex < #inPacket do 
                    ServerBufferIndex = ServerBufferIndex + 1
                    inputbufferfromclients[StartPos][ServerBufferIndex+FutureRun] = inPacket[BufferIndex]
                    if clientID == playersControlledByClient[StartPos+1] then inputbufferfromclients[StartPos+1][ServerBufferIndex+FutureRun] = inPacket[BufferIndex+1] end
                    if clientID == playersControlledByClient[StartPos+2] then inputbufferfromclients[StartPos+2][ServerBufferIndex+FutureRun] = inPacket[BufferIndex+2] end
                    if clientID == playersControlledByClient[StartPos+3] then inputbufferfromclients[StartPos+3][ServerBufferIndex+FutureRun] = inPacket[BufferIndex+3] end
                    BufferIndex = BufferIndex + 4
                end

                -- sometimes, data from clients can be invalid and may attempt to overwrite data that already exists and has been sent to other clients.
                -- this can be fixed by bringing over the old data after the buffer has been optimized, but BEFORE it has been sent.
                -- the new data will be out of range of the old data, therefore only new data can be written and only be removed by old age.
                -- in other instances, a client may have disconnected and cannot send inputs anymore. all future inputs of the client will be cleared and whatever remains will be kept.
                for i=1, #inputbufferfromclients do
                    if playersControlledByClient[i] == 0 then inputbufferfromclients[i] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} end
                end
                for i=1, #BufferFix, 1 do
                    for j=1, #BufferFix[i], 1 do
                        inputbufferfromclients[i][j] = BufferFix[i][j]
                    end
                end
                
                -- now that table has been optimized, begin compiling into sendable packet by...
                -- first determining size of the input packet
                local BufferSizeSend = 99999999
                for i=1, GetValidPlayers(), 1 do
                    BufferSizeSend = #inputbufferfromclients[i] < BufferSizeSend and #inputbufferfromclients[i] or BufferSizeSend
                end
                -- then the server frame time needs to be sent
                packet = BufferSizeSend.."|"..serverframetime
                -- then the specific stored input data needs to be sent, the data size is specified by BufferSizeSend
                for i=1, GetValidPlayers(), 1 do
                    for j=1, BufferSizeSend, 1 do
                        if inputbufferfromclients[i][j] == nil then -- print message when encountering nil data
                            inputbufferfromclients[i][j] = 0
                            --[[InputNil = true
                            prinspect("@@@@@@@@@@@@@@@@@@@@@@@@ Client #"..clientID.." triggered invalid input buffer read on frame "..-1+j+serverframetime..". No reply will be sent. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
                            print("invalid input at inputbufferfromclients["..tostring(i).."]["..tostring(j).."] | BufferSizeSend: "..tostring(BufferSizeSend).." | GetValidPlayers(): "..tostring(GetValidPlayers()))
                            print("inputbufferfromclients:")
                            prinspect(inputbufferfromclients)]]
                           
                        end
                        packet = packet.."|"..inputbufferfromclients[i][j]
                    end
                end
                SendPacketToClient("ServerBuffer", packet, source)
                --50, 65, 85 - if all client checksums are valid, send reply to clients giving OK to no rollback
                if (serverframetime%100) > 50 and (serverframetime%100) < 80 then
                    local packet = tostring(onlineSeed)
                    packet = packet.."|"..tostring(Checksum.AllGood).."|"..tostring(minBuffer)
                    SendPacketToClient("ChecksumS", packet, source)
                end 
            end
            -- POSITIONAL CHECKSUM FOR SAVING SESSIONS FROM DESYNCS --------------------
            --2 - create checksum
            if (serverframetime%100) == 1 then Checksum:ServerDataReset() end 
            --*15, *30, *40 - checksum from client
            if inPacket[3] == "ChecksumC" then 
                -- [1] - password | [2] name | [3] header | [4] playerID | [5] body
                local id = tonumber(inPacket[4])
                Checksum.ClientSent[id] = true
                local ChecksumIn = tonumber(inPacket[5])
                Checksum.ClientData[id] = ChecksumIn
                if id == 1 then Checksum.Host = Checksum.ClientData[1] end -- client 1 is the host and the host is always right
                if Checksum.Host == ChecksumIn then Checksum.ClientGood[id] = true end
                -- check if all collected data is valid.
                local Verify = true
                for i=1, #Checksum.ClientGood, 1 do
                    if Checksum.ClientGood[i] == false and Players[i] ~= "" then Verify = false end
                end
                if Verify then Checksum.AllGood = true options.debugDesync = false Checksum.Warn = false end
                if not Verify then Checksum.Warn = true end
                if options.debugDesync then Checksum.AllGood = false end
            end
            if (serverframetime%100) == 89 then Checksum.Printed = false end
            if (serverframetime%100) == 90 and not Checksum.AllGood and not Checksum.Printed then -- print reason for checksum failure if it occurs
                Checksum.Printed = true
                if true then return end
                prinspect("SERVER CHECKSUM FAILED. REASON: ==================================")
                local SendVerify = true
                for i=1, #Checksum.ClientSent, 1 do
                    if Checksum.ClientSent[i] == false then SendVerify = false end
                end
                if not SendVerify then prinspect("Not all data sent by clients.") else
                prinspect("Mismatched data from some clients.") end
                if options.debugDesync then prinspect("Debug rollback check enabled") end
                prinspect(" server clock: "..tostring(serverframetime))
                    prinspect("Printing data: [DATA SENT]   |    [CHECKSUM]    |   [RESULT]   ")
                for i=1, #Players, 1 do
                    prinspect("     Entry:    "..tostring(Checksum.ClientSent[i]).."  |  "..tostring(Checksum.ClientData[i]).."  |  "..tostring(Checksum.ClientGood[i]))
                end
                print("end -----------------------------")
            end 
        end)
    end
end

set_callback(function()
    saveData.Name = name
    saveData.IP = hostIP
    saveData.Port = hostPort
    saveData.BufferSize = myinputbuffersize
    save_progress()
    state.screen_character_select.disable_controls = false
    if Socket then Socket:close() end
    if Server then Server:close() end
    if inputCallback > -1 then clear_callback(inputCallback) end
    set_start_level_paused(false)
    state.level_flags = set_flag(state.level_flags, 20)
    pause(false)
end, ON.SCRIPT_DISABLE)


-- input handling
function setButtons(input, id)
    if id == 1 then prinspect("setButtons: level frame: "..state.time_level.." | input "..input) end
    input = tonumber(input)
    id = tonumber(id)
    if id <= 4 then
        send_input(InputUIDs[id], input)
    else
        Online.Buttons[id] = input
    end
end


function clearButton(input)
    input = tonumber(input)
    state.player_inputs.player_slots[1].buttons = state.player_inputs.player_slots[1].buttons - input
    state.player_inputs.player_slots[1].buttons_gameplay = state.player_inputs.player_slots[1].buttons - input
end

CLEAR = 0
JUMP = 1
WHIP = 2
BOMB = 4
ROPE = 8
DOOR = 32
MENU = 64
JOURNAL = 128
UP = 1024
DOWN = 2048 
LEFT = 256
RIGHT = 512
SPRINT = 16

function runInput()

    
    if myPlayerID > 1 and Online.Active and game_manager.music.main_backgroundtrack ~= nil then game_manager.music.main_backgroundtrack.playing = false end 
    if Online.Active and options.NetProfile == 4 and state.screen >= 12 then
        game_manager.game_props.game_has_focus = true
        game_manager.game_props.input_index = savedinputindex
    end
    if Online.Active and options.NetProfile >= 3 and serverState == 1 then
        serverState = 0
    end

    --prinspect("ServerChars 5-8: "..ServerChars[5].." "..ServerChars[6].." "..ServerChars[7].." "..ServerChars[8].." ")
    --prinspect("Online.Chars 1-4: "..Online.Chars[1].." "..Online.Chars[2].." "..Online.Chars[3].." "..Online.Chars[4].." ")
    -- go back to menu screen when server gets force reset
    
    -- REALLY make sure that every client goes back
    if state.screen >= 12 and serverState < 2 and state.fade_value == 0 and state.screen_next ~= 4 and Online.Active then 
        prinspect("Host restarted the session. You are still connected. (Player #"..tostring(myPlayerID).." "..tostring(Players[myPlayerID])..")")
        play_seeded(0)
        state.screen_next = 4
    end

    --if game is frozen and desynced, attempt resyncs if allowed
    if get_global_frame()%30 == 0 and Resync.TimeOnThisFrame >= 4*60 then Resync:Tick() end

    if state.logic.olmec_cutscene ~= nil then state.logic.olmec_cutscene.timer = 809 end
    if state.logic.tiamat_cutscene ~= nil then state.logic.tiamat_cutscene.timer = 379 end 
    
    
    
    if Socket == nil then pause(false) return false end
    if Socket and not Socket:is_open() then pause(false) return false end
    if serverState < 2 then pause(false) return false end
    if state.screen >= 12 then
        --fix input indexes
        
        
        
        --automatic input buffer. this can always run inconsequentially
        if myframetime == framebufferclock.PreviousFrameTime then framebufferclock.TotalLagFrames = framebufferclock.TotalLagFrames + 1 end
        framebufferclock.PreviousFrameTime = myframetime
        --prinspect(InputSync.Valid)

        packet = tostring(myframetime) -- tells the server where in the timeline to write the input data (frame time)
        local IncompleteBuffer = false
        local SelfButtons = { -- get inputs of all local players
            state.player_inputs.player_slots[1].buttons,
            state.player_inputs.player_slots[2].buttons,
            state.player_inputs.player_slots[3].buttons,
            state.player_inputs.player_slots[4].buttons
        }
        for i=1, 4, 1 do
            if activatedSlots[i] ~= true then SelfButtons[i] = -1 end -- mark the input as "invalid" in the buffer so the server skips over it.
            if #myinputbuffer[i] < myinputbuffersize then -- if input buffer is not filled to the maximum, fill it up and don't run game physics
                myinputbuffer[i][#myinputbuffer[i]+1] = SelfButtons[i]
                if #myinputbuffer[i] ~= myinputbuffersize then IncompleteBuffer = true end
            end
        end 
        -- if input buffer is incomplete, return true to pause game
        if IncompleteBuffer then 
            pause(true)
            return true 
        end

        -- host always has control of screen transitions and 

        -- now that data is organized, create packet.
        -- one frame of data: |P1|P2|P3|P4

        for i=1, #myinputbuffer[1], 1 do
            for j=1, 4, 1 do
                packet = packet.."|"..tostring(myinputbuffer[j][i])
            end
        end



        SendPacketToHost("clientInput", packet)

         --do i have a server input buffer?
        local ForceInputRead = false

        while (myframetime >= 150 and (myframetime-150-state.time_level)<0 and state.screen_level.time_till_death_screen >= 140 ) do
            myframetime = state.time_level+150
        end
        if (myframetime-150-state.time_level) > 1 then ForceInputRead = true end -- this is here to prevent the game from pausing if there is extra data in the level buffer
        
        if (ForceInputRead or (inputbufferfromserver[1] ~=nil and #inputbufferfromserver[1] > 0)) or state.time_level < 2 then 
            if state.screen > 12 then 
                for i=1, GetValidPlayers(), 1 do if i <= 4 then 
                    state.player_inputs.player_slots[i].buttons = inputbufferfromserver[i][1] or 0
                    state.player_inputs.player_slots[i].buttons_gameplay = inputbufferfromserver[i][1] or 0
                end end
            else
                if (myframetime-150-state.time_level) >= 1 and (state.time_level % 45) == 0 and not forceUpdateState then forceUpdateState = true update_state() end -- catch up with end of level buffer
                if (state.time_level%45) == 1 then forceUpdateState = false end

                for i=1, GetValidPlayers(), 1 do
                    if i <= 4 then 
                        state.player_inputs.player_slots[i].buttons = inputbufferlevel[i][state.time_level] or 0
                        state.player_inputs.player_slots[i].buttons_gameplay = inputbufferlevel[i][state.time_level] or 0
                            
                    else -- set inputs for players 5-8
                        Online.Buttons[i] = inputbufferlevel[i][state.time_level] or 0
                    end
                end
            end
            pause(false) 
        else pause(true) end

        if state.time_level == Resync.ThisFrame then Resync.TimeOnThisFrame = Resync.TimeOnThisFrame + 1
        else Resync.TimeOnThisFrame = 0 end

        Resync.ThisFrame = state.time_level
    end
end

set_callback(runInput, ON.BLOCKED_UPDATE)
set_callback(runInput, ON.PRE_UPDATE)

set_callback(function()
    if Socket == nil then return false end
    if Socket and not Socket:is_open() then return false end
    --state.items.leader = 0
    if state.screen_level.time_till_death_screen == 0 then 
        if not UpdatedSeed then set_seed(onlineSeed+1) end
        UpdatedSeed = true
        warp(Shortcut[Shortcut.ID][1], Shortcut[Shortcut.ID][2], Shortcut[Shortcut.ID][3])
        if myframetime > 160 then onlineSeed = onlineSeed + 1 end
    else
        UpdatedSeed = false
    end



    if state.screen >= 12 then -- in run
    
        if myframetime == 60*2.5 then game_manager.game_props.input_index = savedinputindex end -- putting this in the pre_update crashes the game
        --every time frametime is a multiple of 100, check for desync. if desync is detected, rollback
        -- 2 - create checksum
        if (myframetime%100) == 2 then Checksum.Client = Checksum:Make() end
        -- 10, 25, 35, 50 - send data to server
        if (myframetime%100) == 10 then SendPacketToHost("ChecksumC",tostring(Checksum.Client)) end
        if (myframetime%100) == 25 then SendPacketToHost("ChecksumC",tostring(Checksum.Client)) end
        if (myframetime%100) == 35 then SendPacketToHost("ChecksumC",tostring(Checksum.Client)) end
        if (myframetime%100) == 50 then SendPacketToHost("ChecksumC",tostring(Checksum.Client)) end
        
        -- line 1580 disabled to test resyncing in instances where game is halted and can't reach the proper frametime
        if state.screen == 12 and myframetime % 100 == 95 and state.time_level > 1 and myframetime > 60*7 then Resync:Tick() end -- this line works fine, until some instances reset, this client misses the bus and is stuck waiting for input that will never arrive
    
        for i=1, 4, 1 do -- don't worry about anti-crash stuff, players 1-4 can handle it.
            -- if UIDs don't match, fix it.
            local a = get_player(i, true) ~= nil and get_player(i, true).health > 0 and get_player(i, true) or get_playerghost(i, true) -- gets either living player or their ghost
            if a == nil then InputUIDs[i] = -1 -- prevent errors from stopping the thread
            else -- if a new player entity is available to control, take them.
                --if InputUIDs[i] ~= a.uid then steal_input(a.uid) end
                InputUIDs[i] = a.uid 
            end
        end

        for i=5, 8, 1 do -- extra players 

        end

        -- reset timers and clear levelbuffer when level timer decreases
        if leveltimeold > state.time_level and state.time_level > 0 then
            inputbufferlevel = {{},{},{},{},{},{},{},{}}
            myframetime = state.time_level + 150 -- the 150 is here to bypass the "preparing adventuer" screen
        end


        -- write input buffer into the correct spot for the level buffer. remember, if level time is 0 then you're in a level transition.
        -- the nice part is it can be indexed anywhere and you can still refer to it from its numbers, so the table can start at 1000 and still be accessed like table[1000]
        for i=1, #inputbufferfromserver, 1 do
            for j=1, #inputbufferfromserver[i] do
                inputbufferlevel[i][myframetime-150+j] = inputbufferfromserver[i][j]
            end
        end


    

        --do i have a server input buffer?
        if inputbufferfromserver[1] ~=nil and #inputbufferfromserver[1] > 0 then 
            for i=1, GetValidPlayers(), 1 do
                -- nil value check because it keeps happening. doesn't matter if setButtons has ran before, since the current frame will run again.
                if inputbufferfromserver[i][1] == nil then pause(true) return end

                --setButtons(inputbufferfromserver[i][1], i)
                table.remove(inputbufferfromserver[i], 1)  
            end
            table.remove(myinputbuffer[1], 1)
            table.remove(myinputbuffer[2], 1)
            table.remove(myinputbuffer[3], 1)
            table.remove(myinputbuffer[4], 1)
            myframetime = myframetime + 1
            if state.time_level > 0 then leveltimeold = state.time_level end
        else
            pause(true)
        end
    end

end, ON.GAMEFRAME)


function printer(message)
    if options.enableprintstatements then prinspect(message) end
end

set_callback(function()
    Resync:LevelStart()
end, ON.LEVEL)

-- save and load info

set_callback(function(save_ctx)
    if not (Socket ~= nil and Socket:is_open()) then return end
    saveData.Name = name
    saveData.IP = hostIP
    saveData.Port = hostPort
    saveData.BufferSize = myinputbuffersize
    saveData.NetProfile = options.NetProfile
    local save_data_str = json.encode(saveData)
    save_ctx:save(save_data_str)
end, ON.SAVE)

set_callback(function(load_ctx)
    local load_data_str = load_ctx:load()
    if load_data_str ~= "" then
        saveData = json.decode(load_data_str)
    end
    name = saveData.Name
    hostIP = saveData.IP
    hostPort = saveData.Port
    myinputbuffersize = saveData.BufferSize
    options.NetProfile = saveData.NetProfile
    oldName = string.sub(name, 1, string.find(name, "#", -6)-2)
end, ON.LOAD)

--[[ the way the system works is the clients send packets to the host, the host interprets the data and returns packets to the client.
    if the client doesn't receive data from the server in 15 seconds, it times itself out. 
    once a session begins, the game stops accepting local input

    the client records the player's input every frame and places it in a buffer. if the buffer is filled before the end of the frame, the buffer and a frame counter is sent to the server

    if the server has received input buffers from all players, it sends the minimum sized buffer to all players.
        the min size is the lowest buffer size of all players, if one guy has 3 frame buffer and another guy has 15, the server sends only 3 frames of input
    the client receives the input buffers for all players, updates the frame counter and runs the game world for one frame with the specific player inputs. 1 element is taken off from all buffers.
    the client then reads player input to refill its own buffer, and sends a packet to the server becaues the player's input buffer is full.
    the server sees that a player is running in the future, for every frame the player is in the future, it offsets where it writes into the input buffer table by 1.
    when the server sends the packets, it sends the oldest ones.
    when the client receives packets from the server, it recieves at what time frame the server is sitting at.
    for every frame the client is in the future, it subtracts 1 from the received input buffer
]]

