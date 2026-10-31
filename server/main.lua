local resourceName = GetCurrentResourceName()
exports.pl_lib:CheckVersion(resourceName, true)

function _debug(...)
    if Config.Debug then
        print(...)
    end
end

-- AddItem with per-inventory metadata support (pl_lib:AddItem omits metadata)
local function AddItem(src, amount, imageName)
    local info = { id = imageName }
    if GetResourceState('ox_inventory') == 'started' then
        -- Store as table so GetSlot returns metadata.type correctly
        exports.ox_inventory:AddItem(src, Config.ItemName, amount, { type = imageName })
    elseif GetResourceState('qb-inventory') == 'started' then
        exports['qb-inventory']:AddItem(src, Config.ItemName, amount, false, info)
    elseif GetResourceState('tgiann-inventory') == 'started' then
        exports['tgiann-inventory']:AddItem(src, Config.ItemName, amount, nil, info, false)
    end
end

RegisterServerEvent('pl_printer:insertImageData')
AddEventHandler('pl_printer:insertImageData', function(imageUrl, amount)
    local src = source

    -- Validate amount: must be a positive integer within a reasonable ceiling
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > 100 then
        _debug('[DEBUG] Rejected invalid amount: ' .. tostring(amount))
        return
    end

    -- Validate imageUrl is a non-empty string
    imageUrl = tostring(imageUrl or '')
    if imageUrl == '' then return end
    -- reject oversized payloads and anything that is not a plain http(s) URL,
    -- so bogus/abusive strings can't be stored and later handed to clients
    if #imageUrl > 512 or not imageUrl:match('^https?://') then
        _debug('[DEBUG] Rejected image URL (length/scheme)')
        return
    end

    local account   = Config.Print.Account
    local TotalBill = Config.Print.Price * amount

    if exports.pl_lib:GetPlayerAccountMoney(src, account, TotalBill) then
        local imageName = imageUrl:match('.+/(.-)$')
        if not imageName or imageName == '' then
            _debug('[DEBUG] Invalid image URL — no filename component')
            return
        end

        AddItem(src, amount, imageName)
        MySQL.Async.execute(
            'INSERT INTO printer (image_name, image_link) VALUES (@image_name, @image_link)',
            { ['@image_name'] = imageName, ['@image_link'] = imageUrl },
            function() end
        )
        exports.pl_lib:RemovePlayerMoney(src, account, TotalBill)
        TriggerClientEvent('pl_printer:notification', src, Locale('Money_Removed') .. TotalBill, 'success')
    else
        TriggerClientEvent('pl_printer:notification', src, Locale('not_enough'), 'error')
    end
end)


RegisterServerEvent('pl_printer:fetchImageLink')
AddEventHandler('pl_printer:fetchImageLink', function(imageName, playerSource)
    -- When triggered from a client TriggerServerEvent, source > 0 and is authoritative.
    -- When triggered via internal TriggerEvent (usable-item callbacks), source == 0 so
    -- we fall back to the explicitly-passed playerSource.
    local src = source > 0 and source or playerSource
    if not src or src <= 0 then return end

    if Config.CheckItem and exports.pl_lib:HasItem(src, Config.ItemName) < 1 then return end

    MySQL.Async.fetchScalar(
        'SELECT image_link FROM printer WHERE image_name = @imageName',
        { ['@imageName'] = tostring(imageName) },
        function(imageLink)
            if imageLink then
                TriggerClientEvent('pl_printer:showImage', src, imageLink)
            else
                _debug('[DEBUG] No image link found for ' .. tostring(imageName))
            end
        end
    )
end)


local function registerOxInventoryItem()
    if GetResourceState('ox_inventory') ~= 'started' then return end
    exports(Config.ItemName, function(event, item, inventory, slot)
        if event ~= 'usingItem' then return end
        local slotData = exports.ox_inventory:GetSlot(inventory.id, slot)
        if slotData and slotData.metadata and slotData.metadata.type then
            TriggerEvent('pl_printer:fetchImageLink', slotData.metadata.type, inventory.id)
        end
    end)
end

AddEventHandler('onServerResourceStart', function(startedResource)
    if startedResource == resourceName then
        -- Register usable item for esx / qb / qbox frameworks
        exports.pl_lib:RegisterUsableItem(Config.ItemName, function(src, item)
            if item and item.info and item.info.id then
                TriggerEvent('pl_printer:fetchImageLink', item.info.id, src)
            end
        end)
        registerOxInventoryItem()
    elseif startedResource == 'ox_inventory' then
        -- Re-register when ox_inventory hot-reloads
        registerOxInventoryItem()
    end
end)


SetTimeout(1500, function()
    print('^1[' .. resourceName .. '] ^2Thank you for Downloading the Script^0')
    print('^1[' .. resourceName .. '] ^2If you encounter any issues please Join the discord https://discord.gg/c6gXmtEf3H to get support..^0')
    print('^1[' .. resourceName .. '] ^2Enjoy a secret 20%% OFF any script of your choice on https://pulsescripts.com/^0')
    print('^1[' .. resourceName .. '] ^2Using the coupon code: SPECIAL20 (one-time use coupon, choose wisely)^0')
end)
