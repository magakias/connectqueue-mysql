Config = {
    Priority = {},
    RequireSteam = false,
    PriorityOnly = false,
    DisableHardCap = true,
    ConnectTimeOut = 600,
    QueueTimeOut = 90,
    EnableGrace = false,
    GracePower = 2,
    GraceTime = 480,
    JoinDelay = 30000,
    ShowTemp = false,
    Language = {
        joining = '\xF0\x9F\x8E\x89Joining...',
        connecting = '\xE2\x8F\xB3Connecting...',
        idrr = "\xE2\x9D\x97[Queue] Error: Couldn't retrieve any of your id's, try restarting.",
        err = '\xE2\x9D\x97[Queue] There was an error',
        pos = '\xF0\x9F\x90\x8CYou are %d/%d in queue \xF0\x9F\x95\x9C%s',
        connectingerr = '\xE2\x9D\x97[Queue] Error: Error adding you to connecting list',
        timedout = '\xE2\x9D\x97[Queue] Error: Timed out?',
        wlonly = '\xE2\x9D\x97[Queue] You must be whitelisted to join this server',
        steam = '\xE2\x9D\x97 [Queue] Error: Steam must be running'
    }
}

--[[

    Load The Database Into the table.
    This is called every time someone is removed and added. 
    Plus every server time the server is started.

    This note is from nemesi incase one of you fat neeks are in here.

]]--

function LoadDatabase()
    Citizen.CreateThread(
        function()
            exports.ghmattimysql:execute(
                'SELECT * FROM `queue`',
                {},
                function(result)
                    if (result[1] ~= nil) then
                        for _, data in ipairs(result) do
                            Config.Priority[data.steamid] = data.priority
                        end
                    end
                end
            )
        end
    )
end

-- Loads the data from the DB to the priority table. 
LoadDatabase()

--[[

    Functions

]]--

function AddPriorityFromId(id, level, admin)
    print(admin)
    print(json.encode(Config.Priority))
    local player = exports['np-base']:getModule('Player'):GetUser(tonumber(id))
    local steamid = player:getVar('steamid')
    print(steamid .. ' <-- STEAMID')
    if (admin ~= 0) then
        local adminPlayer = exports['np-base']:getModule('Player'):GetUser(admin)
        local adminRank = adminPlayer:getVar('rank')
    else
        adminRank = 'owner'
    end
    if (adminRank == 'owner' or adminRank == 'dev') and (player ~= nil and steamid ~= nil) then
        Citizen.CreateThread(
            function()
                exports.ghmattimysql:execute(
                    'DELETE FROM `queue` WHERE `steamid` = @steamid',
                    {['steamid'] = steamid},
                    function(result)
                    end
                )

                Citizen.Wait(50)

                exports.ghmattimysql:execute(
                    'INSERT INTO `queue` (`steamid`, `priority`) VALUES (@steamid, @priority)',
                    {['steamid'] = steamid, ['priority'] = level},
                    function(result)
                        LoadDatabase()
                    end
                )
            end
        )
    end
end

function RemovePriorityFromId(id, admin)
    local player = exports['np-base']:getModule('Player'):GetUser(id)
    local adminPlayer = exports['np-base']:getModule('Player'):GetUser(admin)

    local adminRank = adminPlayer:getVar('rank')

    if (adminRank == 'owner' or adminRank == 'dev') and (player ~= nil and adminPlayer ~= nil) then
        exports.ghmattimysql:execute(
            'DELETE FROM `queue` WHERE `steamid` = @steamid',
            {['steamid'] = GetPlayerIdentifiers(id)[1]},
            function(result)
                LoadDatabase()
            end
        )
    end
end

function AddPriorityBySteamID(steamId, level)
    Citizen.CreateThread(
        function()
            exports.ghmattimysql:execute(
                'INSERT INTO `queue` (`steamid`, `priority`) VALUES (@steamid, @priority)',
                {['steamid'] = steamId, ['priority'] = level},
                function(result)
                    LoadDatabase()
                end
            )
        end
    )
end

function RemoveBySteamId(steamId)
    Citizen.CreateThread(
        function()
            exports.ghmattimysql:execute(
                'DELETE FROM `queue` WHERE `steamid` = @steamid',
                {['steamid'] = steamId},
                function()
                    LoadDatabase()
                end
            )
        end
    )
end

--[[

    Commands

]]--

RegisterCommand(
    'addpriority',
    function(source, args)
        local src = source
        local target = args[1]
        local priority = args[2]

        AddPriorityFromId(target, priority, src)
    end,
    false
)

RegisterCommand(
    'removepriority',
    function(source, args)
        local src = source
        local target = args[1]

        RemovePriorityFromId(target, src)
    end,
    false
)

RegisterCommand(
    'addprioritysteam',
    function(source, args)
        print(src)
        local target = args[1]
        local priority = args[2]

        AddPriorityBySteamID(target, priority)
    end,
    true
)

RegisterCommand(
    'removeprioritysteam',
    function(source, args)
        local target = args[1]

        RemoveBySteamId(target)
    end,
    true
)
