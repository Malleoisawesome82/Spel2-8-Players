-- ## LOCAL CO-OP MANAGER ## --
local iio = get_io()

local LevelCameraBounds = {
  --format = Name = {xLeft, xRight, yBottom, yTop}
  CosmicOcean = {-999999999, 999999999, -99999999, -9999999},
  Normal = {10.424, 34.576, 94.082, 118.918}, -- 4x4 
  Echoes = {0, 0, 0, 0},
  Palace = {0, 0, 0, 0},
  Abzu = {0, 0, 0, 0},
  Duat = {0, 0, 0, 0},
  Tiamat = {0, 0, 0, 0},
  Hundun = {0, 0, 0, 0},
  BlackMarket = {0, 0, 0, 0},
  Vlads = {0, 0, 0, 0},
  LakeOfFire = {0, 0, 0, 0}



}
local TransitionOffset
local OnlineFocus = 0
local GlobalHudy = 0
--array for all players
local allowInput = {1, 1, 1, 1}
local HasAnkh = {false, false, false, false}
local ClearAnkh = {false, false, false, false}
local HideHudAnkh = {false, false, false, false}
local HudCrown = {0, 0, 0, 0}
--death stuff
local DieOrder = 0
local DieTable = {}
--dead players p1-p4
local DeadPlayer = {false, false, false, false}
--not arrays
local p5Buttons = 0
local p5uid = -1
local p5status = {0, false, -1, false, false, 0, false}

local p6Buttons = 0
local p6uid = -1
local p6status = {0, false, -1, false, false, 0, false}

local p7Buttons = 0
local p7uid = -1
local p7status = {0, false, -1, false, false, 0, false}

local p8Buttons = 0
local p8uid = -1
local p8status = {0, false, -1, false, false, 0, false}

local HiredMan1 = nil
local HiredMan2 = nil
local HiredMan3 = nil
local HiredMan4 = nil
local p5Inv = {0, 0, "none", "none"}
local p6Inv = {0, 0, "none", "none"}
local p7Inv = {0, 0, "none", "none"}
local p8Inv = {0, 0, "none", "none"}
local FrontSurvivors = false
local survivors = false

local CamFocus = 1
local OldCam = 1

local DoAnkhReset = false

local temp = {}
--camera variables

local CharSel = {285, 286, 287, 288}
local CharSelActive = {false, false, false, false}
local CharSelCooldown = {0, 0, 0, 0}

local x = 0
local y = 0
local size = 0
local playerCount = 0
local CameraX = 0
local CameraY = 0
--display the option to change extra player count
register_option_bool("useXinput", "8P Local | Use Xinput", "Use Xinput to control players 5-8. This option is not recommended unless you have 4 Dualshock controllers. Spelunky 2 is foolish and overwrites keyboard controls with Xinput, so you unforunately can't use keyboard controls for players 1-4.", false)
--register_option_bool("SuperCoffin", "Super Coffin for Players 5-8", "Instead of each player having their own coffin, players 5-8 all emerge from the same coffin", false)
register_option_bool("AutoRun5", "8P Local | Player 5: Autorun", "Player 5 runs instead of walks.", false)
register_option_bool("AutoRun6", "8P Local | Player 6: Autorun", "Player 6 runs instead of walks.", false)
register_option_bool("AutoRun7", "8P Local | Player 7: Autorun", "Player 7 runs instead of walks.", false)
register_option_bool("AutoRun8", "8P Local | Player 8: Autorun", "Player 8 runs instead of walks.", false)
register_option_bool("DefaultCamera", "8P Local | Use Spelunky's original camera behavior", true)
register_option_bool("debugPrint", "8P Local | Show debugging print messages", false)
--register_option_bool("C", ".", false)

--hud variables
local HudYOffset = 0
local HudXOffset = 0

--list of ghosts that kill you
local Ghosts = {ENT_TYPE.MONS_MEGAJELLYFISH, ENT_TYPE.MONS_GHOST, ENT_TYPE.MONS_MEDIUM_SAD, ENT_TYPE.MONS_MEDIUM_HAPPY, ENT_TYPE.MONS_SMALL_ANGRY, ENT_TYPE.MONS_SMALL_SAD, ENT_TYPE.MONS_SMALL_SURPRISED, ENT_TYPE.MONS_SMALL_HAPPY}
local overlapList = {}
local returnUID = -1

local CurrentLayer = 0

--list of things you can carry through a level
local CarryWhitelist = {365, 371, 372, 373, 374, 399, 401, 416, 439, 442, 448, 480, 482, 485, 486, 487, 520, 521, 524, 525, 526, 527, 528, 529, 539, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 564, 565, 567, 570, 572, 574, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, "none"}



--extra player status data structure
--health
--poisoned?
--poison timer?
--cursed?
--elixir'd?
--kapala level
--died this level? (for necromancer purposes)

--inventory data structure
--bombs
--ropes
--backpack item
--held item

--powerups

--init custom heart
p5Heart = Color:new(1.0, 0.05, 0.05, 0.8)
p6Heart = Color:new(0.1, 0.1, 0.1, 0.8)
p7Heart = Color:new(0.3, 0.95, 0.6, 0.8)
p8Heart = Color:new(0.67, 0.329, 0.81, 0.8)
HUD_Opacity = Color:new(1.0, 1.0, 1.0, 1.0)

function prin(string)
  if options.debugPrint then prinspect(string) end
end

function ProcessInput(buttons, controlScheme, Player, Autorun, InHUD)
  InHud = InHud or false
  local buttons = 0
  if state.screen == 13 and InHud == false then 
    if Player.abs_y < 112.03 then Player.y = 112.03 end
    if Player.abs_x > 21.5 then return 560 end
    Player.velocityx = 0.14499999582767487
    return 528 
end
  if Online.Active then controlScheme = controlScheme + 4 end
  
  if options.useXinput and Online.Active == false then
    --prin(iio.gamepads(controlScheme).buttons)
    local BitButtons = iio.gamepads(controlScheme).buttons
    prin(BitButtons)
    if ExtractBit(BitButtons, 13) >= 1 then buttons = buttons + 1 end -- jump
    if ExtractBit(BitButtons, 14) >= 1 then buttons = buttons + 4 end -- bomb
    if ExtractBit(BitButtons, 15) >= 1 then buttons = buttons + 2 end -- whip
    if ExtractBit(BitButtons, 16) >= 1 then buttons = buttons + 8 end -- rope
    if Autorun then if ExtractBit(BitButtons, 9) < 1 or iio.gamepads(controlScheme).rt < 0.5 then buttons = buttons + 16 end 
    else if ExtractBit(BitButtons, 9) >= 1 or iio.gamepads(controlScheme).rt > 0.5 then buttons = buttons + 16 end -- run
    end
    if ExtractBit(BitButtons, 10) >= 1 or iio.gamepads(controlScheme).lt > 0.5 then buttons = buttons + 32 end -- door
    if iio.gamepads(controlScheme).lx < -0.5 then buttons = buttons + 256 end
    if iio.gamepads(controlScheme).lx > 0.5 then buttons = buttons + 512 end
    if iio.gamepads(controlScheme).ly < -0.5 then buttons = buttons + 2048 end
    if iio.gamepads(controlScheme).ly > 0.5 then buttons = buttons + 1024 end
    prin(BitButtons)
    prin(iio.gamepads(controlScheme).buttons)
    prin(buttons)
    prin("------------------")
    return buttons
  end

  if controlScheme == 1 then
    if iio.keydown('E') then buttons = buttons + 1 end -- jump
    if iio.keydown('Q') then buttons = buttons + 2 end -- whip
    if iio.keydown('R') then buttons = buttons + 4 end -- bomb
    if iio.keydown('T') then buttons = buttons + 8 end -- rope
    if Autorun then if not iio.keydown('F') then buttons = buttons + 16 end
    else if iio.keydown('F') then buttons = buttons + 16 end -- run
    end
    if iio.keydown('G') then buttons = buttons + 32 end -- door
    if iio.keydown('A') then buttons = buttons + 256 end -- left
    if iio.keydown('D') then buttons = buttons + 512 end -- right
    if iio.keydown('W') then buttons = buttons + 1024 end -- up
    if iio.keydown('S') then buttons = buttons + 2048 end -- down
  end
  if controlScheme == 2 then
    if iio.keydown('1') then buttons = buttons + 1 end -- jump
    if iio.keydown('2') then buttons = buttons + 2 end -- whip
    if iio.keydown('3') then buttons = buttons + 4 end -- bomb
    if iio.keydown('4') then buttons = buttons + 8 end -- rope
    if Autorun then if not iio.keydown('5') then buttons = buttons + 16 end
    else if iio.keydown('5') then buttons = buttons + 16 end -- run
    end
    if iio.keydown('6') then buttons = buttons + 32 end -- door
    if iio.keydown('7') then buttons = buttons + 256 end -- left
    if iio.keydown('8') then buttons = buttons + 512 end -- right
    if iio.keydown('9') then buttons = buttons + 1024 end -- up
    if iio.keydown('0') then buttons = buttons + 2048 end -- down
  end
  if controlScheme == 3 then
    if iio.keydown('I') then buttons = buttons + 1 end -- jump
    if iio.keydown('Y') then buttons = buttons + 2 end -- whip
    if iio.keydown('O') then buttons = buttons + 4 end -- bomb
    if iio.keydown('P') then buttons = buttons + 8 end -- rope
    if Autorun then if not iio.keydown('L') then buttons = buttons + 16 end
    else if iio.keydown('L') then buttons = buttons + 16 end -- run
    end
    if iio.keydown(KEY.RSHIFT) then buttons = buttons + 32 end -- door
    if iio.keydown('H') then buttons = buttons + 256 end -- left
    if iio.keydown('K') then buttons = buttons + 512 end -- right
    if iio.keydown('U') then buttons = buttons + 1024 end -- up
    if iio.keydown('J') then buttons = buttons + 2048 end -- down
  end
  if controlScheme == 4 then
    if iio.keydown(KEY.LSHIFT) then buttons = buttons + 1 end -- jump
    if iio.keydown('Z') then buttons = buttons + 2 end -- whip
    if iio.keydown('X') then buttons = buttons + 4 end -- bomb
    if iio.keydown('C') then buttons = buttons + 8 end -- rope
    if Autorun then if not iio.keydown('V') then buttons = buttons + 16 end
    else if iio.keydown('V') then buttons = buttons + 16 end -- run
    end
    if iio.keydown('B') then buttons = buttons + 32 end -- door
    if iio.keydown('N') then buttons = buttons + 256 end -- left
    if iio.keydown('M') then buttons = buttons + 512 end -- right
    if iio.keydown(KEY.COMMA) then buttons = buttons + 1024 end -- up
    if iio.keydown(KEY.PERIOD) then buttons = buttons + 2048 end -- down
  end
  if controlScheme > 4 then -- online inputs
    buttons = Online.Buttons[controlScheme]
  end
  return buttons
end

function ExtractBit(Number, Bit)
  Number = Number / (2 ^ (Bit - 1))
  Number = math.fmod(Number, 2)
  return Number
end
--4096
--16348

--attempts to save the game from crashing by removing callbacks
function end_the_fun(victim)
  return_input(victim.uid)
  return -1
end

function OnlineCamera() -- sets the camera
  if state.screen ~= 12 then return end
  set_camera_layer_control_enabled(false)
  local MyGuys = {}
  local FocusPointX = {List={},Result=0}
  local FocusPointY = {List={},Result=0}
  local NewFocus = true

  --[[prinspect("start ---------------")
  prinspect(Online.PlayersCBC)
  prinspect(Online.PlayerIndex)
  prinspect(OnlineFocus)
  prinspect("end ------------------")]]

  for i=1, 4, 1 do
    Online.UIDs[i] = get_player(i) ~= nil and get_player(i).uid or -1
  end

  local nubbyFocus = get_entity(state.camera.focused_entity_uid)
  -- focus on living player ....................|    nil index check....| controlled by this client .........................|
  if nubbyFocus ~= nil and nubbyFocus.health > 0 and OnlineFocus > 0 and Online.PlayersCBC[OnlineFocus] == Online.PlayerIndex and nubbyFocus.uid == Online.UIDs[OnlineFocus] then 
    --prinspect("nubby focus succeeded")
    state.camera_layer = nubbyFocus.layer
    return 
  end



  -- assign camera to a new client controlled player. 
  for i=1, 8, 1 do -- rule 1
    if i <= 4 then -- front half check
      local nubby = get_player(i)
      if nubby ~= nil and nubby.health > 0 and Online.PlayersCBC[i] == Online.PlayerIndex then state.camera.focused_entity_uid = nubby.uid OnlineFocus = i return end
    else -- back half check
      local nubby = get_entity(Online.UIDs[i])
      if nubby ~= nil and nubby.health > 0 and Online.PlayersCBC[i] == Online.PlayerIndex then state.camera.focused_entity_uid = nubby.uid OnlineFocus = i return end
    end
  end
  OnlineFocus = 0
  -- if not returned by this point, re-assign the camera to the original owner
  AssignCamera(false) -- rule 3
  fixCamera() -- fallback to default behavior
end

function AssignCamera(Reassign) --assigns camera to NEXT player when owner dies. traditional s2 camera just reassigns the camera to the lowest port player, which i dont like
if state.screen ~= 12 then return end
prin("Reassign attempt")
prin("Starting CamFocus:")
prin(CamFocus)
prin(Reassign)

  OldCam = CamFocus
  if Reassign == false then -- assign a camera if it isn't assigned to a player for some reason
    if CamFocus < 5 and get_player(CamFocus) ~= nil then --front half
      state.camera.focused_entity_uid = get_player(CamFocus).uid
      return
    else -- back half
      if CamFocus == 5 then
        state.camera.focused_entity_uid = p5uid
        return
      end
      if CamFocus == 6 then
        state.camera.focused_entity_uid = p6uid
        return
      end
      if CamFocus == 7 then
        state.camera.focused_entity_uid = p7uid
        return
      end
      if CamFocus == 8 then
        state.camera.focused_entity_uid = p8uid
        return
      end
    end
  end 
  CamFocus = CamFocus + 1 -- if reaching this point, the camera owner died and the camera needs to be reassigned
  while CamFocus ~= OldCam do
    if CamFocus < 5 then --front half
      if get_player(CamFocus) ~= nil and get_player(CamFocus).health > 0 then
        state.camera.focused_entity_uid = get_player(CamFocus).uid
        return
      end
    else -- back half
      if CamFocus == 5 and HiredMan1 and p5status[1] > 0 then
        state.camera.focused_entity_uid = p5uid
        return
      end
      if CamFocus == 6 and HiredMan2 and p6status[1] > 0 then
        state.camera.focused_entity_uid = p6uid
        return
      end
      if CamFocus == 7 and HiredMan3 and p7status[1] > 0 then
        state.camera.focused_entity_uid = p7uid
        return
      end
      if CamFocus == 8 and HiredMan4 and p8status[1] > 0 then
        state.camera.focused_entity_uid = p8uid
        return
      end
    end
    CamFocus = CamFocus + 1
    if CamFocus > 8 then CamFocus = 1 end
  end
end

--fixes the camera so it's not all just locked into one place.
function fixCamera() -- this functino is ran even if online is active at the same time, since we need to know who to assign the camrea to when all client players are dead
  set_camera_layer_control_enabled(false)
  if state.screen == 11 then return end
  if state.screen ~= 12 then zoom(13.5) return end
  if options.DefaultCamera then 
    --prin("Camera focus UID")
    --prin(state.camera.focused_entity_uid)
    if state.camera.focused_entity_uid < 1 then AssignCamera(false) end
    if get_entity(state.camera.focused_entity_uid) == nil or get_entity(state.camera.focused_entity_uid).health < 1 then
      AssignCamera(true)
    end
    state.camera_layer = get_entity(state.camera.focused_entity_uid) ~= nil and get_entity(state.camera.focused_entity_uid).layer or state.camera_layer
    return 
  end
  state.camera.focused_entity_uid = -1
  x = 0
  y = 0
  playerCount = 0
  if players[1] then CheckPlayerCamera(1) end
  if players[2] then CheckPlayerCamera(2) end
  if players[3] then CheckPlayerCamera(3) end
  if players[4] then CheckPlayerCamera(4) end
  if HiredMan1 then
  if HiredMan1.health > 0 then
    x = x + HiredMan1.abs_x
    y = y + HiredMan1.abs_y
    playerCount = playerCount + 1
  end
end
  if HiredMan2 then
  if HiredMan2.health > 0 then
    x = x + HiredMan2.abs_x
    y = y + HiredMan2.abs_y
    playerCount = playerCount + 1
  end
end
  if HiredMan3 then
  if HiredMan3.health > 0 then
    x = x + HiredMan3.abs_x
    y = y + HiredMan3.abs_y
    playerCount = playerCount + 1
  end
end
  if HiredMan4 then
  if HiredMan4.health > 0 then
    x = x + HiredMan4.abs_x
    y = y + HiredMan4.abs_y
    playerCount = playerCount + 1
  end
end
  state.camera.focused_entity_uid = -1
  if playerCount > 0 then
    CameraX = x / playerCount
    CameraY = y / playerCount
    state.camera.focus_x = CameraX
    state.camera.focus_y = CameraY
  end
  zoom(13.5+(playerCount-1)*0.7)
end

function CheckPlayerCamera(num)
  if num < 5 then
    if players[num].health > 0 then
      x = x + players[num].abs_x
      y = y + players[num].abs_y
      playerCount = playerCount + 1
    end
  end
end
--hud inventory order
local Hud_Inventory = {545, 546, 547, 548, 550, 551, 552, 553, 554, 555, 560, 561, 562}

--gets the pickup version of a powerup. useful for dying and needing to puke out all of your items. skips the ankh cause you keep all your items when you die.
function GetPickupFromPowerup(id)
if id == 545 then return 529 end -- paste
if id == 546 then return 525 end -- climbing gloves
if id == 547 then return 528 end -- spike shoes
if id == 548 then return 527 end -- spring shoes
if id == 549 then return 534 end -- kapala
if id == 550 then return 524 end -- spectacles
if id == 551 then return 526 end -- pitcher's mitt
if id == 552 then return 533 end -- udjat eye
if id == 553 then return 532 end -- parachute
if id == 554 then return 530 end -- compass
if id == 555 then return 531 end -- alien compass
if id == 556 then return 535 end -- hedjet
if id == 557 then return 536 end -- crown
if id == 558 then return 537 end -- eggplant crown
if id == 559 then return 538 end -- truecrown
if id == 561 then return 540 end -- tablet
if id == 562 then return 541 end -- skeleton key
return -1
end

--spawns playerbag from dead player.
function SpawnPlayerBag(Player, texture)
  prin("Playerbag function ran")
  if Player.inventory.bombs > 0 or Player.inventory.ropes > 0 then
  local bag = spawn_entity(ENT_TYPE.ITEM_PICKUP_PLAYERBAG, Player.abs_x, Player.abs_y, Player.layer, (prng:random(20)-10)*0.01, (prng:random(20))*0.01)
    get_entity(bag).bombs = Player.inventory.bombs
    get_entity(bag).ropes = Player.inventory.ropes
    get_entity(bag):set_texture(texture)
  end
end

--USABLE FOR ALL PLAYERS
--reads the stored status of  Player 5..8 and applies proper details to them
function ReadStatus(HiredMan, status)
  HiredMan.health = status[1]
  if status[2] then 
    poison_entity(HiredMan.uid)
    HiredMan.poison_tick_timer = status[3]
  end
  if status[4] then HiredMan:set_cursed(true) end
  if status[5] then set_entity_flags2(HiredMan.uid, 32768+HiredMan.more_flags) end
end

--USABLE FOR ALL PLAYERS
--writes the info of Player 5..8 to be used on the next screen
function WriteStatus(HiredMan, status)
  status[1] = HiredMan.health
  if HiredMan.poison_tick_timer > 0 then
    status[2] = true
    status[3] = HiredMan.poison_tick_timer
  else
    status[2] = false
    status[3] = -1
  end
  if test_flag(HiredMan.more_flags, 15) then status[4] = true else status[4] = false end
  if test_flag(HiredMan.more_flags, 16) then status[5] = true else status[5] = false end
  return status
end

-- code to run when exiting a level
function exitLevel()
  if HiredMan1 then 
    if state.screen == 12 then p5Inv = store_inventory(HiredMan1, p5Inv) end
    return_input(HiredMan1.uid) 
    p5status = WriteStatus(HiredMan1, p5status)
    p5uid = -1
    HiredMan1 = nil
  end

  if HiredMan2 then 
    if state.screen == 12 then p6Inv = store_inventory(HiredMan2, p6Inv) end
    return_input(HiredMan2.uid) 
    p6status = WriteStatus(HiredMan2, p6status)
    p6uid = -1
    HiredMan2 = nil
  end

  if HiredMan3 then 
    if state.screen == 12 then p7Inv = store_inventory(HiredMan3, p7Inv) end
    return_input(HiredMan3.uid) 
    p7status = WriteStatus(HiredMan3, p7status)
    p7uid = -1
    HiredMan3 = nil
  end

  if HiredMan4 then 
    if state.screen == 12 then p8Inv = store_inventory(HiredMan4, p8Inv) end
    return_input(HiredMan4.uid) 
    p8status = WriteStatus(HiredMan4, p8status)
    p8uid = -1
    HiredMan4 = nil
  end

end

--function MUST be used like this:
--p5Inv = (HiredMan, pInv)
--stores the inventory to be loaded in the next level
function store_inventory(Player, Inventory)
  Inventory = {0, 0, "none", "none"}
  if Player.health < 1 then return Inventory end
  Inventory[1] = Player.inventory.bombs
  Inventory[2] = Player.inventory.ropes
  Inventory[3] = get_entity_type(Player:worn_backitem())
  temp = Player:get_held_entity()
  --check if the held item is in the whitelist
  if temp ~= nil then for i=1, #CarryWhitelist, 1 do
    if get_entity_type(temp.uid) == CarryWhitelist[i] then Inventory[4] = CarryWhitelist[i] break end
    Inventory[4] = "none"
  end end
  temp = Player:get_powerups()
  if #temp > 0 then
    for i=1, #temp, 1 do
      Inventory[4+i] = temp[i]
    end
  end
  return Inventory
end

--read_inventory(HiredMan, pInv)
--changes done to objects referenced in parameters will be reflected outside of functions
--changes done to variables referenced in parameters will NOT be reflected outside of functions
function read_inventory(Player, Inventory)
 Player.inventory.bombs = Inventory[1]
 Player.inventory.ropes = Inventory[2]
 if Inventory[3] ~= "none" and Inventory[3] ~= -1 and Inventory[3] < 600 then pick_up(Player.uid, spawn_entity(Inventory[3], Player.x, Player.y, Player.layer, 0, 0)) end
 if Inventory[4] ~= "none" and Inventory[3] ~= -1 then pick_up(Player.uid, spawn_entity(Inventory[4], Player.x, Player.y, Player.layer, 0, 0)) end
 if #Inventory > 4 then
    for i=5, #Inventory, 1 do
      Player:give_powerup(Inventory[i])
    end
  end
end


function DeathTableAdd(PlayerID) -- 
if DieTable[DieOrder] == PlayerID then return end -- prevents the same player from being put into the death table
  if PlayerID < 5 then -- players 1-4 run this function when dying with the ankh. if they die with the ankh, time of death is not set.
      if state.items.player_inventory[PlayerID].time_of_death < 1 then return end
      DeadPlayer[PlayerID] = true
  end
  DieOrder = DieOrder + 1
  DieTable[DieOrder] = PlayerID



end

function DeathTableRead()
  if DieOrder == 0 then return -1 end
  temp = {0, 0, 0, 0, 0, 0, 0, 0}
  temp[1] = DieTable[2]
  temp[2] = DieTable[3]
  temp[3] = DieTable[4]
  temp[4] = DieTable[5]
  temp[5] = DieTable[6]
  temp[6] = DieTable[7]
  temp[7] = DieTable[8]
  temp[8] = DieTable[1]
  DieTable[1] = temp[1]
  DieTable[2] = temp[2]
  DieTable[3] = temp[3]
  DieTable[4] = temp[4]
  DieTable[5] = temp[5]
  DieTable[6] = temp[6]
  DieTable[7] = temp[7]
  DieTable[8] = 0
  DieOrder = DieOrder - 1
  prin("Death Table Read item:")
  prin(temp[8])
  return temp[8]
end
--[[
table - {5, 2, 1, 6, 7, 8, 3, 4, 0}
temp - {2, 1, 6, 0, 0, 0, 0, 0, 0}

]]
--get list of uids, use a for-loop to iterate through the list and create a list of ENT_TYPE.ITEM_ blah blah blahs.
function AnkhReset()

end

function GiveItem(Player, type) --doesn't work with weapons and back items
  temp = spawn_entity(type, 0, 0, LAYER.FRONT, 0, 0)
  attach_entity(Player.uid, temp)
end

-- stolen from the api page
-- force change the layer
--[[
set_camera_layer_control_enabled(false)

g_current_timer = nil
function change_layer(layer_to)

    if state.camera_layer == layer_to then
        return
    end
    if g_current_timer ~= nil then
        clear_callback(g_current_timer)
        g_current_timer = nil
    end
    state.layer_transition_timer = 36
    state.transition_to_layer = layer_to
    state.camera_layer = layer_to
end]]

--checks if currently viewed layer needs switching. 
function CheckLayer()
  for i=1, 4, 1 do
    if get_player(i) and get_player(i).layer == CurrentLayer and get_player(i).health > 0 then
      return CurrentLayer
    end
  end
  if HiredMan1 and HiredMan1.layer == CurrentLayer and HiredMan1.health > 0 then return end
  if HiredMan2 and HiredMan2.layer == CurrentLayer and HiredMan2.health > 0 then return end
  if HiredMan3 and HiredMan3.layer == CurrentLayer and HiredMan3.health > 0 then return end
  if HiredMan4 and HiredMan4.layer == CurrentLayer and HiredMan4.health > 0 then return end
  --if reaching this point, all conditions failed so the current layer must be changed
  CurrentLayer = CurrentLayer + 1
  if CurrentLayer > 1 then CurrentLayer = 0 end
end

--Spawn player 5 function
function SpawnPlayer5(x, y, layer)
  if CharSelActive[1] == false then return end
   if p5status[1] > 0 and p5status[7] == false then 
     p5uid = spawn_companion(CharSel[1]-91, x+TransitionOffset, y, layer)
     if state.screen == 13 then TransitionOffset = TransitionOffset+1 end
     survivors = true
     HiredMan1 = get_entity(p5uid)
     read_inventory(HiredMan1, p5Inv)
     p5Heart = HiredMan1:get_heart_color()
     ReadStatus(HiredMan1, p5status)
     HiredMan1:set_pre_destroy(function()
      return_input(HiredMan1.uid)
     end)
  else 
    p5uid = spawn_playerghost(CharSel[1]-91, state.level_gen.spawn_x, state.level_gen.spawn_y+0.8, LAYER.FRONT)
    HiredMan1 = get_entity(p5uid)
  end
    HiredMan1:set_texture(CharSel[1])
  

  set_on_player_instagib(HiredMan1.uid, function() -- this function is not properly named, and runs on any death, instagib, or instagib while corpse is destroyed, and also probably runs when a necromancer controlled character dies, gets instagibbed, or has its corpse destroyed
    if p5status[7] == true then return end
    if HasAnkh[1] == false then 
      unequip_backitem(p5uid)
      DeathTableAdd(5)
    if get_entity_type(p5uid) > 193 and get_entity_type(p5uid) < 215 then temp = HiredMan1:get_powerups() SpawnPlayerBag(HiredMan1, txt_Player5)  end
    if #temp > 0 then
      for i=1, #temp, 1 do
        spawn_entity(GetPickupFromPowerup(temp[i]), HiredMan1.x, HiredMan1.y, HiredMan1.layer, (prng:random(20)-10)*0.01, (prng:random(20))*0.01)
      end
    end
    local Diedx, Diedy, Diedlayer = get_position(HiredMan1.uid)
    end_the_fun(HiredMan1)
    if p5status[7] == false then 
      p5uid = spawn_playerghost(CharSel[1]-91, Diedx, Diedy, Diedlayer)
    end
    p5status = {0, false, -1, false, false, 0, true}
    HiredMan1 = get_entity(p5uid)
    HiredMan1:set_texture(CharSel[1])
  else HideHudAnkh[1] = true 
      DoAnkhReset = true
  end
  end)
end


  --Spawn player 6 function
function SpawnPlayer6(x, y, layer)
  if CharSelActive[2] == false then return end
  if p6status[1] > 0 and p6status[7] == false then 
     p6uid = spawn_companion(CharSel[2]-91, x+TransitionOffset, y, layer)
     if state.screen == 13 then TransitionOffset = TransitionOffset+1 end
     survivors = true
     HiredMan2 = get_entity(p6uid)
     p6Heart = HiredMan2:get_heart_color()
     read_inventory(HiredMan2, p6Inv)
  else 
    p6uid = spawn_playerghost(CharSel[2]-91, state.level_gen.spawn_x, state.level_gen.spawn_y+0.8, LAYER.FRONT)
    HiredMan2 = get_entity(p6uid)
  end
    ReadStatus(HiredMan2, p6status)
    HiredMan2:set_texture(txt_Player6)

    set_on_player_instagib(p6uid, function() 
      if p6status[7] == true then return end
      if HasAnkh[2] == false then
        unequip_backitem(p6uid)
        DeathTableAdd(6)
      if get_entity_type(p6uid) > 193 and get_entity_type(p6uid) < 215 then temp = HiredMan2:get_powerups() SpawnPlayerBag(HiredMan2, txt_Player6)  end
      if #temp > 0 then
        for i=1, #temp, 1 do
          spawn_entity(GetPickupFromPowerup(temp[i]), HiredMan2.x, HiredMan2.y, HiredMan2.layer, (prng:random(20)-10)*0.01, (prng:random(20))*0.01)
        end
      end
      local Diedx, Diedy, Diedlayer = get_position(HiredMan2.uid)
      end_the_fun(HiredMan2)
      if p6status[7] == false then 
        p6uid = spawn_playerghost(CharSel[2]-91, Diedx, Diedy, Diedlayer)
      end
      p6status = {0, false, -1, false, false, 0, true}
      HiredMan2 = get_entity(p6uid)
      HiredMan2:set_texture(txt_Player6)
    else HideHudAnkh[2] = true DoAnkhReset = true end
    end)
end

function SpawnPlayer7(x, y, layer)
if CharSelActive[3] == false then return end
  if p7status[1] > 0 and p7status[7] == false then 
     p7uid = spawn_companion(CharSel[3]-91, x+TransitionOffset, y, layer)
     if state.screen == 13 then TransitionOffset = TransitionOffset+1 end
     survivors = true
     HiredMan3 = get_entity(p7uid)
     p7Heart = HiredMan3:get_heart_color()
     read_inventory(HiredMan3, p7Inv)
  else 
    p7uid = spawn_playerghost(CharSel[3]-91, state.level_gen.spawn_x, state.level_gen.spawn_y+0.8, LAYER.FRONT)
    HiredMan3 = get_entity(p7uid)
  end
    ReadStatus(HiredMan3, p7status)
    HiredMan3:set_texture(txt_Player7)


    set_on_player_instagib(p7uid, function() 
      if p7status[7] == true then return end
      if HasAnkh[3] == false then
        unequip_backitem(p7uid)
        DeathTableAdd(7)
      if get_entity_type(p7uid) > 193 and get_entity_type(p7uid) < 215 then temp = HiredMan3:get_powerups() SpawnPlayerBag(HiredMan3, txt_Player7)  end
      if #temp > 0 then
        for i=1, #temp, 1 do
          spawn_entity(GetPickupFromPowerup(temp[i]), HiredMan3.x, HiredMan3.y, HiredMan3.layer, (prng:random(20)-10)*0.01, (prng:random(20))*0.01)
        end
      end
      local Diedx, Diedy, Diedlayer = get_position(HiredMan3.uid)
      end_the_fun(HiredMan3)
      if p7status[7] == false then 
        p7uid = spawn_playerghost(CharSel[3]-91, Diedx, Diedy, Diedlayer)
      end
      p7status = {0, false, -1, false, false, 0, true}
      HiredMan3 = get_entity(p7uid)
      HiredMan3:set_texture(txt_Player7)
    else HideHudAnkh[3] = true DoAnkhReset = true end
    end)
end

function SpawnPlayer8(x, y, layer)
if CharSelActive[4] == false then return end
  if p8status[1] > 0 and p8status[7] == false then 
     p8uid = spawn_companion(CharSel[4]-91, x+TransitionOffset, y, layer)
     survivors = true
     HiredMan4 = get_entity(p8uid)
     p8Heart = HiredMan4:get_heart_color()
     read_inventory(HiredMan4, p8Inv)
  else 
    p8uid = spawn_playerghost(CharSel[4]-91, state.level_gen.spawn_x, state.level_gen.spawn_y+0.8, LAYER.FRONT)
    HiredMan4 = get_entity(p8uid)
  end
    ReadStatus(HiredMan4, p8status)
    HiredMan4:set_texture(txt_Player8)


    set_on_player_instagib(p8uid, function() 
      if p8status[7] == true then return end
      if HasAnkh[4] == false then
        unequip_backitem(p8uid)
        DeathTableAdd(8)
      if get_entity_type(p8uid) > 193 and get_entity_type(p8uid) < 215 then temp = HiredMan4:get_powerups() SpawnPlayerBag(HiredMan4, txt_Player8)  end
      if #temp > 0 then
        for i=1, #temp, 1 do
          spawn_entity(GetPickupFromPowerup(temp[i]), HiredMan4.x, HiredMan4.y, HiredMan4.layer, (prng:random(20)-10)*0.01, (prng:random(20))*0.01)
        end
      end
      local Diedx, Diedy, Diedlayer = get_position(HiredMan4.uid)
      end_the_fun(HiredMan4)
      if p8status[7] == false then 
        p8uid = spawn_playerghost(CharSel[1]-91, Diedx, Diedy, Diedlayer)
      end
      p8status = {0, false, -1, false, false, 0, true}
      HiredMan4 = get_entity(p8uid)
      HiredMan4:set_texture(txt_Player8)
    else HideHudAnkh[4] = true DoAnkhReset = true end
    end)
end

set_post_entity_spawn(function(this) kill_entity(this.uid) end, SPAWN_TYPE.ANY, MASK.ANY, 648) -- clear indicators to make the offscreen icons make more sense having them around

function init8Players()
  CamFocus = 1
  OldCam = 1
  txt_Player5 = CharSel[1]
  txt_Player6 = CharSel[2]
  txt_Player7 = CharSel[3]
  txt_Player8 = CharSel[4]





  MusicFix = false
  initSpawns = true
  p5Inv = {0, 0, "none", "none"}
  p6Inv = {0, 0, "none", "none"}
  p7Inv = {0, 0, "none", "none"}
  p8Inv = {0, 0, "none", "none"}
  if HiredMan1 then kill_entity(HiredMan1.uid) end
  if HiredMan2 then kill_entity(HiredMan2.uid) end
  if HiredMan3 then kill_entity(HiredMan3.uid) end
  if HiredMan4 then kill_entity(HiredMan4.uid) end
  DieTable = {0, 0, 0, 0, 0, 0, 0, 0}
  DieOrder = 0
  DeadPlayer = {true, true, true, true}

  p5Buttons = 0
  p5uid = -1
  p5status = {4, false, -1, false, false, 0, false}
  HiredMan1 = nil
  p5Inv = {1, 1, "none", "none"}
  SpawnPlayer5(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)

  p6Buttons = 0
  p6uid = -1
  p6status = {4, false, -1, false, false, 0, false}
  HiredMan2 = nil
  p6Inv = {1, 1, "none", "none"}
  SpawnPlayer6(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)

  p7Buttons = 0
  p7uid = -1
  p7status = {4, false, -1, false, false, 0, false}
  HiredMan3 = nil
  p7Inv = {1, 1, "none", "none"}
  SpawnPlayer7(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)

  p8Buttons = 0
  p8uid = -1
  p8status = {4, false, -1, false, false, 0, false}
  HiredMan4 = nil
  p8Inv = {1, 1, "none", "none"}
  SpawnPlayer8(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)

  -- make playerghosts invisible
  temp = get_entities_by_type(ENT_TYPE.ITEM_PLAYERGHOST)
  if #temp > 0 then 
    --prin(temp)
    for i=1, #temp, 1 do
      --prin(temp[i])
        get_entity(temp[i]).flags = set_flag(get_entity(temp[i]).flags, 1)
  end end

  prin("Init 8 players")



  for i=1, 4, 1 do -- kill all players. 1-4
    local nubby = get_player(i)
    if nubby ~= nil and nubby.uid > 1 then Online.UIDs[i] = nubby.uid end
  end
  Online.UIDs[5] = p5uid
  Online.UIDs[6] = p6uid
  Online.UIDs[7] = p7uid
  Online.UIDs[8] = p8uid

end
--init 8 player mode

set_callback(function()
  init8Players()
end, ON.CAMP)

--check if players are alive
function CheckSurvivors(Numbers)
  -- i write it like this cause idk if lua will get mad at me in case a player doesn't exist or something like that
  DeadPlayer[Numbers] = true
  temp = get_player(Numbers)
  if get_player(Numbers) then
    if get_player(Numbers).health > 0 then
      survivors = true
      FrontSurvivors = true
      DeadPlayer[Numbers] = false
    end
  end
end
function coffinHijack()
  temp = get_entities_by_type(ENT_TYPE.ITEM_COFFIN) -- hijack non-player coffins to spawn ana spelunkies. 
  if #temp < 1 then return end
  for i=1, #temp do
    local coffin = get_entity(temp[i])
    --coffin.flags = clr_flag(coffin.flags, 7)
    coffin.player_respawn = false
    if coffin.player_respawn == false then coffin.inside = 216 end
  end
end

function revive_player(Number, xPos, yPos, Layer) -- revive player 1-4
  --if state.items.player_inventory[Number].time_of_death < 1 then return end
  state.items.player_inventory[Number].health = 4
  state.items.player_inventory[Number].time_of_death = 0
  temp = spawn_player(Number, xPos, yPos, Layer)
  return temp
end

function coffinHijackRespawn()
  if state.screen ~= 11 then 
    local ReviveWho = 0
    temp = get_entities_by_type(ENT_TYPE.CHAR_EGGPLANT_CHILD) -- then the ana spelunkies that are spawned will revive all dead players from 5 to 8.
    if #temp < 1 then return end
    for i=1, #temp do
      hijack = get_entity(temp[i])
      if hijack:get_texture() == 306 then --hijack the eggplant child
      local Revivemonkey = -1
      local secondRevive = false
        ReviveWho = DeathTableRead()
        while ReviveWho > 0 do
          if ReviveWho < 1 then kill_entity(hijack.uid) return end
          if ReviveWho < 5 then
            Revivemonkey = revive_player(ReviveWho, hijack.abs_x, hijack.abs_y, hijack.layer)
          end
          if ReviveWho == 5 then 
            p5Inv = {0, 0, "none", "none"}
            p5status = {4, false, -1, false, false, 0, false}
            return_input(HiredMan1.uid)
            get_entity(HiredMan1.uid).flags = set_flag(get_entity(HiredMan1.uid).flags, 1)
            SpawnPlayer5(hijack.abs_x, hijack.abs_y, hijack.layer)
            Revivemonkey = p5uid
          end
          if ReviveWho == 6 then 
            p6Inv = {0, 0, "none", "none"}
            p6status = {4, false, -1, false, false, 0, false}
            return_input(HiredMan2.uid)
            get_entity(HiredMan2.uid).flags = set_flag(get_entity(HiredMan2.uid).flags, 1)
            SpawnPlayer6(hijack.abs_x, hijack.abs_y, hijack.layer)
            Revivemonkey = p6uid
          end
          if ReviveWho == 7 then 
            p7Inv = {0, 0, "none", "none"}
            p7status = {4, false, -1, false, false, 0, false}
            return_input(HiredMan3.uid)
            get_entity(HiredMan3.uid).flags = set_flag(get_entity(HiredMan3.uid).flags, 1)
            SpawnPlayer7(hijack.abs_x, hijack.abs_y, hijack.layer)
            Revivemonkey = p7uid
          end
          if ReviveWho == 8 then 
            p8Inv = {0, 0, "none", "none"}
            p8status = {4, false, -1, false, false, 0, false}
            return_input(HiredMan4.uid)
            get_entity(HiredMan4.uid).flags = set_flag(get_entity(HiredMan4.uid).flags, 1)
            SpawnPlayer8(hijack.abs_x, hijack.abs_y, hijack.layer)
            Revivemonkey = p8uid
          end
          get_entity(Revivemonkey).invincibility_frames_timer = 30
          get_entity(Revivemonkey).stun_timer = 30
            if secondRevive then
              get_entity(Revivemonkey).velocityx = prng:random((20)-10)*0.0
              get_entity(Revivemonkey).velocityy = prng:random((20))*0.0
            end
          ReviveWho = DeathTableRead()
          secondRevive = true
        end
        kill_entity(hijack.uid)
      end
    end
  end
end

function drawIconOverPlayer(Player, Label, render_ctx, ColorOverride)
  local size = 0
  local side = none
  local render = false
  local screenX = Player.abs_x
  local screenY = Player.abs_y+0
  screenX, screenY = screen_position(screenX, screenY)
  size = math.sqrt(screenX^2 + screenY^2)
  size = 0.002 - (size - 1.4) * 0.0005
  if size < 0.0006 then size = 0.0006 end
  if size > 0.002 then size = 0.002 end
  screenY = screenY * (size/0.002)
  screenX = screenX * (size/0.002)
  Color = Player:get_heart_color()
  if screenX < -0.94 then side = "lr" screenX = -0.94 render = true end
  if screenX > 0.94 then side = "lr" screenX = 0.94 render = true end
  if screenY < -0.77 then side = "tb" screenY = -0.77 render = true end
  if screenY > 0.75 then side = "tb" screenY = 0.75 render = true end
  Color.a = 1

  


  if Player.layer ~= state.camera_layer then Color.a = 0.3 render = true end
  if Player.color.a == 0 then Color.a = 0.6  render = true end
  if not render then return end
  render_ctx:draw_text(Label, screenX, screenY, size, size, Color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.BOLD)
end

function ExtraPlayer(Player, Status, Inventory, uid, Buttons, txt_player, ID)
  -- store data into Online table
  Online.UIDs[ID+4] = uid

  if Player then
    --prin(HasAnkh[1])
    HasAnkh[ID] = false 
    HudCrown[ID] = 0
    if Player.health > 0 then HideHudAnkh[ID] = false end
    if Status[7] == false then 
      survivors = true 
      temp = Player:get_powerups()
      if #temp > 0 then 
        for i=1, #temp, 1 do 
        --prin(temp[i])
        if temp[i] == 556 then HudCrown[ID] = 1 end
        if temp[i] == 557 then HudCrown[ID] = 2 end
        if temp[i] == 558 then HudCrown[ID] = 3 end
        if temp[i] == 559 then HudCrown[ID] = 4 end
        if temp[i] == 560 then HasAnkh[ID] = true break end
        end end
    end
      steal_input(uid)
      send_input(uid, Buttons)
  end
    -- if p5Inv ~= nil and #p5Inv > 0 then prin(table.concat(p5Inv, " ")) end
    return Player, Status, Inventory, uid
end

  --init 8 players on run start
set_callback(function()
  for i=1, #players do
    if players[i] then players[i].inventory.companion_count = 0 end
  end
  if Online.Active then init8Players() end
end, ON.START)


set_callback(function()
  --prin("On Post Level Generation")
  TransitionOffset = 0
  if state.screen == 13 then -- add health for saving pets
  TransitionOffset = #players
    for i=1, state.items.saved_pets_count, 1 do
      if p5status[1] > 0 then p5status = petLick(p5status) end
      if p6status[1] > 0 then p6status = petLick(p6status) end
      if p7status[1] > 0 then p7status = petLick(p7status) end
      if p8status[1] > 0 then p8status = petLick(p8status) end
    end
  end
    SpawnPlayer5(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)
    SpawnPlayer6(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)
    SpawnPlayer7(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)
    SpawnPlayer8(state.level_gen.spawn_x, state.level_gen.spawn_y, LAYER.FRONT)
  initSpawns = false
  temp = get_entities_by_type(ENT_TYPE.CHAR_EGGPLANT_CHILD) -- prevent eggplant children from causing unwanted respawns
  if #temp < 1 then return end
  for i=1, #temp do
    hijack = get_entity(temp[i])
    if hijack:get_texture() == 306 then 
      kill_entity(hijack.uid)
    end
  end
  -- hide offscreen player portraits and flag
  --temp = get_entities_by_type(ENT_TYPE.FX_PLAYERINDICATOR)
  AssignCamera(false)

end, ON.POST_LEVEL_GENERATION)



set_callback(function()
  exitLevel()
  for i=1, 4 do
    if get_player(i, true) ~= nil then get_player(i, true).inventory.companion_count = 0 end
  end
  
end, ON.PRE_LOAD_SCREEN)

function petLick(Status)
  Status[1] = Status[1] + 1
  if Status[2] then 
    Status[2] = false
    Status[3] = -1
  end
  if Status[5] then Status[1] = Status[1] + 1 end
return Status
end

set_callback(function()
  --prin("On Reset")
  DieOrder = 0
  init8Players()
end, ON.RESET)

set_callback(function(ctv) -- spawn 1 coffin room for the extra players to be revived
  local CoffinsToSpawn = 0
  local SpawnCoffin = true
  if state.level == 1 and state.theme == THEME.DWELLING then SpawnCoffin = false end
 if CharSelActive[1] and p5status[1] < 1 then CoffinsToSpawn = CoffinsToSpawn + 1 end
 if CharSelActive[2] and p6status[1] < 1 then CoffinsToSpawn = CoffinsToSpawn + 1 end
 if CharSelActive[3] and p7status[1] < 1 then CoffinsToSpawn = CoffinsToSpawn + 1 end
    if CharSelActive[4] and p8status[1] < 1 then CoffinsToSpawn = CoffinsToSpawn + 1 end
 
  if state.theme == THEME.COSMIC_OCEAN then
    SpawnCoffin = false
    if state.level == 9 or state.level == 49 or state.level == 89 then 
      SpawnCoffin = true
    end
  end

  for i=1, 4, 1 do
    if state.items.player_inventory[i].time_of_death > 1 then SpawnCoffin = false break end
  end

  if state.theme == THEME.OLMEC or state.theme == THEME.TIAMAT or state.theme == THEME.ABZU or state.theme == THEME.BASE_CAMP or state.theme == THEME.HUNDUN then
    SpawnCoffin = false
  end
  if DieOrder == 0 then SpawnCoffin = false end
  prin(CoffinsToSpawn)

  --check all player coffins
  local PlayerCoffinSpawned = false
  --print("dead players yo")
  for x=0, state.width-1 do
    for y=0, state.height-1 do
      local room = get_room_template(x, y, 0)
      if room == 26 or room == 25 then -- player coffin room IDs
      --if PlayerCoffinSpawned then prinspect("player coffin found at x:"..x.." y:"..y.." | replaced coffin ") else
        --prinspect("player coffin found at x:"..x.." y:"..y.." | not replacing coffin ") end
        if PlayerCoffinSpawned and room == 26 then ctv:set_room_template(x, y, LAYER.FRONT, ROOM_TEMPLATE.PATH_DROP_NOTOP) end
        if PlayerCoffinSpawned and room == 25 then ctv:set_room_template(x, y, LAYER.FRONT, ROOM_TEMPLATE.PATH_NORMAL) end
        PlayerCoffinSpawned = true
      end
    end
  end
  --and remove all extra ones

  if not SpawnCoffin then return end

  for i=1, CoffinsToSpawn, 1 do
    local Sides = 0
    local SideX = {}
    local SideY = {}
    for x=0, state.width-1 do
      for y=0, state.height-1 do
          local room = get_room_template(x, y, 0)
          if room == 0 then 
            Sides = Sides + 1 
            SideX[Sides] = x
            SideY[Sides] = y
          end
      end
    end
    if Sides < 1 then SpawnCoffin = false end
    if SpawnCoffin then
      Sides = prng:random(Sides)
      if prng:random(2) == 2 then ctv:set_room_template(SideX[Sides], SideY[Sides], LAYER.FRONT, ROOM_TEMPLATE.COFFIN_UNLOCKABLE)
      else ctv:set_room_template(SideX[Sides], SideY[Sides], LAYER.FRONT, ROOM_TEMPLATE.COFFIN_UNLOCKABLE_LEFT) end
      return -- only spawn 1 coffin
    end
  end
end, ON.POST_ROOM_GENERATION)

--control hired hands
set_callback(function()

  --force player 1-4 thru door
  for i=1, 8, 1 do
    local nubby = nil
    if i <= 4 then nubby = get_player(i)
    else 
      if i == 5 then nubby = get_entity(p5uid) end 
      if i == 6 then nubby = get_entity(p6uid) end 
      if i == 7 then nubby = get_entity(p7uid) end 
      if i == 8 then nubby = get_entity(p8uid) end 
    end
    if nubby ~= nil and nubby.health > 0 and nubby.state == 21 and nubby.color.a == 0 and nubby.animation_frame ~= 0 and ExtractBit(nubby.input.buttons, 11) >= 1 then
      nubby:set_layer((nubby.layer+1)%2)
      nubby.emitted_light.enabled = true
    end

  end


  FrontSurvivors = false
  survivors = false
  state.world2_coffin_spawned = true
  state.world4_coffin_spawned = true
  state.world6_coffin_spawned = true


  if HiredMan1 then p5Buttons = ProcessInput(p5Buttons, 1, HiredMan1, options.AutoRun5) end
  if HiredMan2 then p6Buttons = ProcessInput(p6Buttons, 2, HiredMan2, options.AutoRun6) end
  if HiredMan3 then p7Buttons = ProcessInput(p7Buttons, 3, HiredMan3, options.AutoRun7) end
  if HiredMan4 then p8Buttons = ProcessInput(p8Buttons, 4, HiredMan4, options.AutoRun8) end
  for i=1, 4 do
    Online.UIDs[i] = get_player(i, true) -- get UIDs of front players.
    if get_player(i, true) == nil then Online.UIDs[i] = 0 end

    if state.items.player_inventory[i].time_of_death > 0 and DeadPlayer[i] == false then 
      DeathTableAdd(i)
    end
    CheckSurvivors(i)
    if players[i] then players[i].inventory.companion_count = 0 end

  end
  coffinHijack()
  coffinHijackRespawn()
  HiredMan1, p5status, p5Inv, p5uid = ExtraPlayer(HiredMan1, p5status, p5Inv, p5uid, p5Buttons, txt_Player5, 1)
  HiredMan2, p6status, p6Inv, p6uid = ExtraPlayer(HiredMan2, p6status, p6Inv, p6uid, p6Buttons, txt_Player6, 2)
  HiredMan3, p7status, p7Inv, p7uid = ExtraPlayer(HiredMan3, p7status, p7Inv, p7uid, p7Buttons, txt_Player7, 3)
  HiredMan4, p8status, p8Inv, p8uid = ExtraPlayer(HiredMan4, p8status, p8Inv, p8uid, p8Buttons, txt_Player8, 4)
  if not Online.Active then fixCamera() end

  OnlineCamera()
  if survivors == true then
    set_level_logic_enabled(false)
    if state.screen == 12 and game_manager.music.death_transition then game_manager.music.death_transition.playing = false end 
    CheckLayer()
  else
    set_level_logic_enabled(true)
  end
  -- if (players[1].state == 20) or (players[2].state == 20) or (players[3].state == 20) or (players[4].state == 20) then exitLevel() end
end, ON.GAMEFRAME)

function drawHeart(render_ctx, Player, Color, Label, Status, ID)
  if Player then 
    if entity_has_item_type(Player.uid, ENT_TYPE.ITEM_POWERUP_KAPALA) then 
      HudYOffset = HudYOffset + -0.018
      HudXOffset = HudXOffset + -0.0093
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 4, 0+Player:kapala_blood_amount(), -0.965+HudXOffset, 0.837-0.036+HudYOffset, -0.886-0.021+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- kapala
      HudXOffset = HudXOffset + 0.0093 + 0.013
      HudYOffset = HudYOffset + 0.018
    end
       
    if Status[7] == false and Player.health > 0 and HudCrown[ID] == 1 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 2, 7, -0.965+HudXOffset, 0.837+0.05+HudYOffset, -0.886+HudXOffset, 0.7+0.05+HudYOffset, HUD_Opacity) end --hedjet
    if Status[7] == false and Player.health > 0 and HudCrown[ID] == 2 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 2, 6, -0.965+HudXOffset, 0.837+0.05+HudYOffset, -0.886+HudXOffset, 0.7+0.05+HudYOffset, HUD_Opacity) end --vlad crown
    if Status[7] == false and Player.health > 0 and HudCrown[ID] == 3 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 4, -0.965+HudXOffset, 0.837+0.05+HudYOffset, -0.886+HudXOffset, 0.7+0.05+HudYOffset, HUD_Opacity) end --eggplant crown
    if Status[7] == false and Player.health > 0 and HudCrown[ID] == 4 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 5, -0.965+HudXOffset, 0.837+0.05+HudYOffset, -0.886+HudXOffset, 0.7+0.05+HudYOffset, HUD_Opacity) end --true crown

    if test_flag(Player.more_flags, 15) then -- cursed
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 2, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- cursed heart
    else
       render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 0, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, Color) -- actual heart
    end
    if test_flag(Player.more_flags, 16) then -- purple 
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 7, 4, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- elixir
    end
    if Player:is_poisoned() then -- posioned
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 1, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- poison heart 
    end
    if Status[7] == true or Player.health == 0 then -- dead
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 3, 3, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, HUD_Opacity) 
    else -- alive and well (debatable)
        --print "P5 text over player's head"
      if HasAnkh[ID] and HideHudAnkh[ID] == false then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 0, 7, -0.965+HudXOffset, 0.837+HudYOffset, -0.886+HudXOffset, 0.7+HudYOffset, HUD_Opacity) end
      if state.screen == 12 then
        drawIconOverPlayer(Player, Label, render_ctx, Color)
      end
      temp = Player:get_powerups()
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 1, 2, -0.965+0.1+HudXOffset, 0.837+HudYOffset, -0.886+0.1+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- bomb
      render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_0, 1, 3, -0.965+0.18+HudXOffset, 0.837+HudYOffset, -0.886+0.18+HudXOffset, 0.7+HudYOffset, HUD_Opacity) -- bomb
      render_ctx:draw_text(tostring(Player.health), -0.895+HudXOffset, 0.74+HudYOffset, 0.001, 0.001, HUD_Opacity, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.BOLD) -- health number
      render_ctx:draw_text(tostring(Player.inventory.bombs), -0.903+0.1+HudXOffset, 0.73+HudYOffset, 0.0006, 0.0006, HUD_Opacity, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.BOLD) -- bomb number
      render_ctx:draw_text(tostring(Player.inventory.ropes), -0.899+0.18+HudXOffset, 0.73+HudYOffset, 0.0006, 0.0006, HUD_Opacity, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.BOLD) -- rope number
      local j = 1
      if entity_has_item_type(Player.uid, ENT_TYPE.ITEM_POWERUP_KAPALA) then HudXOffset = HudXOffset - 0.013 end -- fix kapala offset for rendered items
      HudYOffset = HudYOffset + 0.03
      for i=1, #Hud_Inventory, 1 do
        if Hud_Inventory[i] == temp[j] then
          if Hud_Inventory[i] == 545 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 0, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- paste
          if Hud_Inventory[i] == 546 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 2, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- climbers
          if Hud_Inventory[i] == 547 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 4, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- spikes
          if Hud_Inventory[i] == 548 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 5, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- boingers
          if Hud_Inventory[i] == 550 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 7, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- glasses
          if Hud_Inventory[i] == 551 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 3, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- brown climbers
          if Hud_Inventory[i] == 552 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 1, 3, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- eye of rah
          if Hud_Inventory[i] == 553 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 6, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- para tute
          if Hud_Inventory[i] == 554 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 0, 1, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- come pass
          if Hud_Inventory[i] == 555 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 1, 2, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- spes shial come pass
          if Hud_Inventory[i] == 561 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 1, 1, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- tablet of describing
          if Hud_Inventory[i] == 562 then render_ctx:draw_screen_texture(TEXTURE.DATA_TEXTURES_HUD_1, 1, 0, -0.947+HudXOffset, 0.67+HudYOffset, -0.907+HudXOffset, 0.6+HudYOffset, HUD_Opacity) end -- skeleton key
          HudXOffset = HudXOffset + 0.03
            --if #temp > 7 then HudXOffset = HudXOffset - 0.0035*(#temp-7) end DOESN'T WORK BECAUSE #TEMP ALSO INCLUDES CROWNS, ANKH, KAPALA
            -- thankfully i don't need it to work because i have plenty of real estate at the bottom of the screen
          j = j + 1
          if temp[j] == 549 then j = j + 1 end
          if j > #temp then break end
        end
      end  
    end
  end
end



--render p5 hud
  set_callback(function(render_ctx, hud)
    if state.screen ~= 12 and state.screen ~= 11 then return end
    if state.screen == 12 then --draw icons for regular players, too.
      for i=1, 4, 1 do if get_player(i) and get_player(i).health > 0 then drawIconOverPlayer(get_player(i), "P"..i, render_ctx, "none") end end
    end
    local Center = 0.13
    p5Heart.a = hud.opacity*0.8
    p6Heart.a = hud.opacity*0.8
    p7Heart.a = hud.opacity*0.8
    p8Heart.a = hud.opacity*0.8
    HUD_Opacity.a = hud.opacity*0.8
    HudXOffset = 0+Center
    HudYOffset = -0.75 + -hud.y
    drawHeart(render_ctx, HiredMan1, p5Heart, "P5", p5status, 1)
    
    HudXOffset = 0.45+Center
    HudYOffset = -0.75 + -hud.y
    drawHeart(render_ctx, HiredMan2, p6Heart, "P6", p6status, 2)

    HudXOffset = 0.90+Center
    HudYOffset = -0.75 + -hud.y
    drawHeart(render_ctx, HiredMan3, p7Heart, "P7", p7status, 3)

    HudXOffset = 1.35+Center
    HudYOffset = -0.75 + -hud.y
    drawHeart(render_ctx, HiredMan4, p8Heart, "P8", p8status, 4)
    --prin(hud.y)
    GlobalHudy = hud.y

    
    
  end, ON.RENDER_POST_HUD)

set_callback(function(render_ctx)
    if state.screen == 9 then P8CharSelect(render_ctx) end
    if Online.Active then return end
    if state.screen == 4 then
      for i=1, 4, 1 do
        CharSelActive[i] = false
        CharSel[i] = 284+i
      end
    end
end, ON.RENDER_POST_GAME)

--render char select for extra players
function P8CharSelect(render_ctx) -- this function shouldn't run while 8 player is active
    if Online.Active then -- online mode
      CharSelActive = Online.ActiveSlots
      CharSel[1] = Online.Chars[1]
      CharSel[2] = Online.Chars[2]
      CharSel[3] = Online.Chars[3]
      CharSel[4] = Online.Chars[4]

      --prinspect("P8 Local (Online Active) : "..CharSel[1].." "..CharSel[2].." "..CharSel[3].." "..CharSel[4].." ")
      return
    end



    local white = Color:white()
    local gray = Color:gray()
    for i=1, 4, 1 do
      local color = gray
        local x = -0.17
        local y = 0.5
      if CharSelActive[i] then color = white end
        local Label = "P5"
        if i == 2 then Label, x = "P6", 0.17 end
        if i == 3 then Label, y = "P7", -0.15 end
        if i == 4 then Label, x, y = "P8", 0.17, -0.15 end
        render_ctx:draw_text(Label, x, y, 0.002, 0.002, color, VANILLA_TEXT_ALIGNMENT.CENTER, VANILLA_FONT_STYLE.BOLD) 



        -- grab inputs for player
        local input = ProcessInput(0, i, nil, false, true)
        prin(input)
        if ExtractBit(input, 1) >= 1 and CharSelActive[i] == false then -- activate char selector
          play_sound(VANILLA_SOUND.MENU_SELECTION, -1)
          CharSelActive[i] = true
        end 
        if ExtractBit(input, 3) >= 1 and CharSelActive[i] then -- deactivate char selector
          play_sound(VANILLA_SOUND.MENU_CANCEL, -1)
          CharSelActive[i] = false
        end 
        if ExtractBit(input, 9) >= 1 and CharSelActive[i] and CharSelCooldown[i] < 1  then -- scroll left
          play_sound(VANILLA_SOUND.MENU_CHARSEL_NAVI, -1)
          CharSel[i] = CharSel[i] - 1
          if CharSel[i] < 285 then CharSel[i] = 304 end
          CharSelCooldown[i] = 30
          
        end 
        if ExtractBit(input, 10) >= 1 and CharSelActive[i] and CharSelCooldown[i] < 1 then -- scroll right
          play_sound(VANILLA_SOUND.MENU_CHARSEL_NAVI, -1)
          CharSel[i] = CharSel[i] + 1
          if CharSel[i] > 304 then CharSel[i] = 285 end
          CharSelCooldown[i] = 30
        end 
        CharSelCooldown[i] = CharSelCooldown[i] - 1

        -- draw character
        local size = 0.3
        local xOffset = -0.078
        local yOffset = -0.13
        if CharSelActive[i] then render_ctx:draw_screen_texture(CharSel[i], 0, 0, x+xOffset, y+yOffset, (x+size*0.55)+xOffset, (y-size)+yOffset, Color:white()) end
    end


   
end
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
 -- ------------
 --TODO: 
 -- figure out a way to draw the player icons or just use an alternate system entirely
 -- get ghist door working with cursed players 5 thru 8
 -- investigate why coffin respawn was wrong
 -- keep camera size change, but make it focus on players only.
 -- Prevent either daily challenge from being playable or coffins from spawning in daily challenge.
 -- get level bounds and enforce them since if players 1-4 are dead on level start, the camera ignores them.
 -- fix duat altar ankh transition crashing the game
 -- figure out how to get music working properly. you can hijack the death music transition, but then when players 1-4 start existing again, the music breaks until you go back to the menu.
 -- write a tutorial on how to set up the mod for in person play sessions 
 -- make char selection actually work for extra players
 -- fix ankh crashing the game for higher players
 -- fix ankh not teleporting players back correctly




 -- worry about online mode after finishing the local co-op version first
 -- Online mode:
 -- connect to a server that uses delay based netcode and host input authority
 --[[
 server host commands -

local
  start - creates server
  end - ends all connections and deletes the server
  disconnect - disconnects IP



send



recieve
 
 
 
 ]]
