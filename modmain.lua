local TheSim = GLOBAL.TheSim
local STRINGS = GLOBAL.STRINGS
local json = GLOBAL.json
local setmetatable = GLOBAL.setmetatable
local getmetatable = GLOBAL.getmetatable
local AllPlayers = GLOBAL.AllPlayers
local ExceptionArrays = GLOBAL.ExceptionArrays

-- local variables
local url = nil
local players = {}

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

local announcement_icons = {
    death = "https://media.discordapp.net/attachments/818578474242670623/819356637457809498/death.png",
    resurrect = "https://media.discordapp.net/attachments/818578474242670623/819355907367370802/resurrect.png",
    boot = "https://media.discordapp.net/attachments/818578474242670623/819359928023646218/boot.png"
}

TheSim:GetPersistentString(
    "discord_webhook_url",
    function(res, content)
        if res then
            url = content
        else
            url = nil
        end
    end
)

local function SendAnnouncementMessage(inst, message, icon)
    print("discord send", inst, message)

    if not url then
        return
    end

    message = message:gsub("^%s*(.-)%s*$", "%1") -- Capitalize first word
    message = message:gsub("^%l", string.upper) -- Remove heading/trailing space

    TheSim:QueryServer(
        url,
        function(json, res, code)
            print("Announced to Discord", json)
        end,
        "POST",
        json.encode(
            {
                username = inst:GetDisplayName(),
                -- content = message,
                embeds = {
                    {
                        author = {
                            name = message,
                            icon_url = announcement_icons[icon] or ""
                        }
                    }
                },
                avatar_url = character_icons[inst.prefab] or character_icons.unknown
            }
        )
    )
end

local function GetAnnouncementString(fn, inst, ...)
    -- Deep copy inst & remove names
    _inst = deepcopy(inst)
    _inst.name = ""
    _inst.displaynamefn = nil
    _inst.nameoverride = nil

    -- Get announcement string
    local announcement = fn(_inst, ...)

    return announcement
end

local function OnPlayerDeath(inst, data)
    -- wait for Game logic to set death values before get announcement string
    inst:DoTaskInTime(
        0,
        function(inst)
            local announcement =
                GetAnnouncementString(
                GLOBAL.GetNewDeathAnnouncementString,
                inst,
                inst.deathcause,
                inst.deathpkname,
                inst.deathbypet
            )
            SendAnnouncementMessage(inst, announcement, "death")
        end
    )
end

local function OnRespawnFromGhost(inst)
    -- wait for Game logic to set spawn values before get announcement string
    inst:DoTaskInTime(
        0,
        function(inst)
            if inst.rezsource ~= nil then
                local announcement = GetAnnouncementString(GLOBAL.GetNewRezAnnouncementString, inst, inst.rezsource)
                SendAnnouncementMessage(inst, announcement, "resurrect")
            end
        end
    )
end

local function OnPlayerJoined(world, inst)
    if table.contains(players, inst.userid) then
        return
    end

    -- Enter the Lobby
    table.insert(players, inst.userid)
    inst:DoTaskInTime(
        0,
        function(inst)
            local announcement = string.format(STRINGS.UI.NOTIFICATION.JOINEDGAME, "")
            SendAnnouncementMessage(inst, announcement, "boot")
        end
    )
end

local function OnPlayerLeft(world, inst)
    if table.contains(AllPlayers, inst) then
        return
    end

    table.removearrayvalue(players, inst.userid)
    local announcement = string.format(STRINGS.UI.NOTIFICATION.LEFTGAME, "")
    SendAnnouncementMessage(inst, announcement, "boot")
end

-- AddGamePostInit(
--     function(inst)
--         -- world prepared
--         print("discord game post")
--     end
-- )

-- AddSimPostInit(
--     function(inst)
--         print("discord sim post")
--     end
-- )

AddPrefabPostInit(
    "world",
    function(world)
        -- This is neccessary, otherwise client would overload memory
        if not world.ismastershard then
            return
        end

        -- Hijack Announcement function
        local _Networking_Announcement = GLOBAL.Networking_Announcement
        GLOBAL.Networking_Announcement = function(message, color, announce_type)
            print("discord send hijack", message, colour, announce_type)

            -- Announce other messages
            local ignore_announce_types = {
                "death",
                "resurrect",
                "join_game",
                "leave_game"
            }
            if not table.contains(ignore_announce_types, announce_type) then
                _Networking_Announcement(message, color, announce_type)
                SendAnnouncementMessage(world, message, announce_type)
            end

            -- Player joined
            if announce_type == "join_game" then
                local new_players = ExceptionArrays(AllPlayers, players)
                for index, player in ipairs(new_players) do
                    _Networking_Announcement(message, color, announce_type)
                    table.insert(players, player)
                    SendAnnouncementMessage(player, message, announce_type)
                end
            end

            -- Player left
            if announce_type == "left_game" then
                local loss_players = ExceptionArrays(players, AllPlayers)
                for index, player in (loss_players) do
                    _Networking_Announcement(message, color, announce_type)
                    table.removearrayvalue(players, player)
                    SendAnnouncementMessage(player, message, announce_type)
                end
            end
        end
    end
)

AddPlayerPostInit(
    function(inst)
        inst:ListenForEvent("death", OnPlayerDeath)
        inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
    end
)

local function SetDiscordWebhook(_url)
    url = _url
    TheSim:SetPersistentString("discord_webhook_url", url, false, nil)
    print("set webhook")
end

GLOBAL.SetDiscordWebhook = SetDiscordWebhook

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
-- ms_clientauthenticationcomplete
-- ms_clientdisconnected
-- player_ready_to_start_dirty
-- ms_requestedlobbycharacter
