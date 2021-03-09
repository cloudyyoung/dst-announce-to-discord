

local TheSim = GLOBAL.TheSim
local STRINGS = GLOBAL.STRINGS
local json = GLOBAL.json
local url = nil

local character_icons = {
    unknown = "https://cdn.discordapp.com/attachments/242336026251493376/735280247464788028/avatar_unknown.png",
    charlie = "https://media.discordapp.net/attachments/381234050632908801/735364619551637646/avatar_charlie.png",
    wagstaff = "https://cdn.discordapp.com/attachments/735356544174260255/735358342112870430/avatar_wagstaff.png",
    walani = "https://cdn.discordapp.com/attachments/242336026251493376/735280248593186927/avatar_walani.png",
    walter = "https://cdn.discordapp.com/attachments/242336026251493376/735280250539343902/avatar_walter.png",
    warly = "https://cdn.discordapp.com/attachments/242336026251493376/735280252397289552/avatar_warly.png",
    waxwell = "https://cdn.discordapp.com/attachments/242336026251493376/735280253974478858/avatar_waxwell.png",
    wearger = "https://cdn.discordapp.com/attachments/242336026251493376/735280255673172018/avatar_wearger.png",
    webber = "https://cdn.discordapp.com/attachments/242336026251493376/735280257107755078/avatar_webber.png",
    weerclops = "https://cdn.discordapp.com/attachments/242336026251493376/735280258617573386/avatar_weerclops.png",
    wendy = "https://cdn.discordapp.com/attachments/242336026251493376/735280259863281775/avatar_wendy.png",
    wes = "https://cdn.discordapp.com/attachments/242336026251493376/735280260903469166/avatar_wes.png",
    wheeler = "https://cdn.discordapp.com/attachments/735356544174260255/735358338656763965/avatar_wheeler.png",
    wickerbottom = "https://cdn.discordapp.com/attachments/242336026251493376/735280261994119218/avatar_wickerbottom.png",
    wathgrithr = "https://cdn.discordapp.com/attachments/242336026251493376/735280263139033108/avatar_wigfrid.png",
    wilba = "https://cdn.discordapp.com/attachments/735356544174260255/735358331748745266/avatar_wilba.png",
    wilbur = "https://cdn.discordapp.com/attachments/242336026251493376/735280264405843988/avatar_wilbur.png",
    willow = "https://cdn.discordapp.com/attachments/242336026251493376/735280365790429194/avatar_willow.png",
    wilson = "https://cdn.discordapp.com/attachments/242336026251493376/735280368583966810/avatar_wilson.png",
    winona = "https://cdn.discordapp.com/attachments/242336026251493376/735280371343556678/avatar_winona.png",
    wolfgang = "https://cdn.discordapp.com/attachments/242336026251493376/735280374325837974/avatar_wolfgang.png",
    woodie = "https://cdn.discordapp.com/attachments/242336026251493376/735280376796282981/avatar_woodie.png",
    woodlegs = "https://cdn.discordapp.com/attachments/242336026251493376/735280379270922310/avatar_woodlegs.png",
    woose = "https://cdn.discordapp.com/attachments/242336026251493376/735280382332633179/avatar_woose.png",
    wormot = "https://media.discordapp.net/attachments/381234050632908801/735363977118482442/avatar_wormot.png",
    wormwood = "https://cdn.discordapp.com/attachments/242336026251493376/735280384891289721/avatar_wormwood.png",
    wortox = "https://cdn.discordapp.com/attachments/242336026251493376/735280387378380890/avatar_wortox.png",
    wragonfly = "https://cdn.discordapp.com/attachments/242336026251493376/735280392768323654/avatar_wragonfly.png",
    wurt = "https://cdn.discordapp.com/attachments/242336026251493376/735280434950176778/avatar_wurt.png",
    wx78 = "https://cdn.discordapp.com/attachments/242336026251493376/735280438947610754/avatar_wx78.png"
}

TheSim:GetPersistentString("discord_webhook_url", function(res, content)
	if res then
		url = content
	else
		url = nil
	end
end)

local function SendMessage(inst, message)
    print("discord send", inst, message)

    if not url then
        return
    end

    if not inst:GetDisplayName() then
        return
    end

    message = message:gsub(inst:GetDisplayName(), "")
    message = message:gsub("^%s*(.-)%s*$", "%1")
    message = message:gsub("^%l", string.upper)

    TheSim:QueryServer(
		url,
		function(json, res, code)
			print("Announced to Discord", json)
		end,
		"POST",
		json.encode({
			username = inst:GetDisplayName(),
			content = message,
            avatar_url = character_icons[inst.prefab] or character_icons.unknown
		})
	) 
end

-- player_common_extensions.lua

local function OnPlayerDeath(inst, data)
    if not inst:HasTag("player") then
        return
    end

    inst.deathcause = data ~= nil and data.cause or "unknown"

    if data == nil or data.afflicter == nil then
        inst.deathpkname = nil
    elseif data.afflicter.overridepkname ~= nil then
        inst.deathpkname = data.afflicter.overridepkname
        inst.deathbypet = data.afflicter.overridepkpet
    else
        local killer = data.afflicter.components.follower ~= nil and data.afflicter.components.follower:GetLeader() or nil
        if killer ~= nil and
            killer.components.petleash ~= nil and
            killer.components.petleash:IsPet(data.afflicter) then
            inst.deathbypet = true
        else
            killer = data.afflicter
        end
        inst.deathpkname = killer:HasTag("player") and killer:GetDisplayName() or nil
    end
    
    local announcement = GLOBAL.GetNewDeathAnnouncementString(inst, inst.deathcause, inst.deathpkname, inst.deathbypet)
    SendMessage(inst, announcement)
end

local function OnRespawnFromGhost(inst, data)
    if inst.rezsource ~= nil then
        local announcement = GLOBAL.GetNewRezAnnouncementString(inst, inst.rezsource)
        SendMessage(inst, announcement)
    end
end

local function OnPlayerJoinedLobby(world, inst)
    local announcement = string.format(STRINGS.UI.NOTIFICATION.JOINEDGAME, "")

    -- Has to do this, otherwise `inst` would be a world updater instead of player, and crash
    inst:DoTaskInTime(0, function()
        SendMessage(inst, announcement)
    end)
end

local function OnPlayerLeftLobby(world, inst)
    local announcement = string.format(STRINGS.UI.NOTIFICATION.LEFTGAME, "")
    SendMessage(inst, announcement)
end

local function OnPlayerEnteredWorld(world, inst)
    -- STRINGS.UI.SERVERCREATIONSCREEN.WORLD_LONG_FMT
    -- STRINGS.UI.SANDBOXMENU.LOCATION.FOREST
    local type = STRINGS.UI.SANDBOXMENU.LOCATION[world.worldprefab:upper()] or STRINGS.NAMES.UNKNOWN
    local announcement = string.gsub(STRINGS.UI.SERVERCREATIONSCREEN.WORLD_LONG_FMT, "{location}", type)
    SendMessage(inst, announcement)
end

local function OnPlayerLeftWorld(world, inst)
    -- Unused
end


AddPrefabPostInit("world", function(world)
    if not world.ismastersim then
		return
	end

    world:ListenForEvent("ms_playerspawn", OnPlayerJoinedLobby)
    world:ListenForEvent("ms_playerdespawn", OnPlayerLeftLobby)
    world:ListenForEvent("ms_playerjoined", OnPlayerEnteredWorld)
    -- world:ListenForEvent("ms_playerleft", OnPlayerLeftWorld)
end)

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("death", OnPlayerDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
end)

local function SetDiscordWebhook(_url)
    url = _url
    TheSim:SetPersistentString("discord_webhook_url", url, false, nil)
    print("set webhook")
end

GLOBAL.SetDiscordWebhook = SetDiscordWebhook

-- AddUserCommand("webhook", {
--     aliases = { "discordwebhook", "discord" },
--     prettyname = "Set Discord Webhook",
--     desc = "Set Discord webhook URL for this server, url should begin with \"https://discordapp.com/api/webhooks/\"",
--     permission = COMMAND_PERMISSION.MODERATOR,
--     confirm = false,
--     slash = true,
--     usermenu = false,
--     servermenu = false,
--     params = {"channel_id", "token"},
--     vote = false,
--     serverfn = function(param, caller)
--         url = "https://discordapp.com/api/webhooks/" .. param.channel_id .. "/" .. param.token
--         TheSim:SetPersistentString("discord_webhook_url", url, false, nil)
--         print("set webhook")
--     end,
-- })



-- makeplayerghost
-- respawnfromghost
-- ghostdissipated
-- respawnfromcorpse
-- playerdied
-- gotnewitem
-- killed (pvp)

-- TheWorld:
-- ms_playerjoined
-- playerentered
-- ms_playerleft
-- playerexited
-- ms_newplayerspawned
-- deactivateworld
-- ms_save
-- deactivateworld
-- ms_simunpaused
-- ms_playerdisconnected
-- ms_playerdespawn
-- ms_worldreset
-- ms_clientdisconnected
-- entity_death
-- ms_newplayercharacterspawned
-- playeractivated
-- playerdeactivated
-- ms_setseason
-- ms_save
-- ms_respawnedfromghost
-- ms_becameghost
-- entercharacterselect