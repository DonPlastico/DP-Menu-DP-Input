local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('QBCore:Client:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

local headerShown = false
local sendData = nil
local isMenuOpen = false -- Nueva variable para rastrear el estado del menú

-- Functions

local function sortData(data, skipfirst)
    local header = data[1]
    local tempData = data
    if skipfirst then
        table.remove(tempData, 1)
    end
    table.sort(tempData, function(a, b)
        return a.header < b.header
    end)
    if skipfirst then
        table.insert(tempData, 1, header)
    end
    return tempData
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Si el menú está abierto, deshabilitar la tecla Escape.
        if isMenuOpen then
            DisableControlAction(0, 200, true) -- 200 es el código para la tecla Escape
            
            -- Captura la pulsación de la tecla Escape
            if IsControlJustReleased(0, 200) then
                closeMenu()
            end
        end

        DisplayAmmoThisFrame(false) -- Desactivar la munición
    end
end)

local function openMenu(data, sort, skipFirst)
    if not data or not next(data) then
        return
    end
    if sort then
        data = sortData(data, skipFirst)
    end
    for _, v in pairs(data) do
        if v["icon"] then
            if QBCore.Shared.Items[tostring(v["icon"])] then
                if not string.find(QBCore.Shared.Items[tostring(v["icon"])].image, "//") and
                    not string.find(v["icon"], "//") then
                    v["icon"] = "nui://qb-inventory/html/images/" .. QBCore.Shared.Items[tostring(v["icon"])].image
                end
            end
        end
    end
    headerShown = false
    sendData = data
    isMenuOpen = true -- Establecer el estado del menú a abierto
    SendNUIMessage({
        action = 'OPEN_MENU',
        data = table.clone(data)
    })
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
end

local function closeMenu()
    sendData = nil
    headerShown = false
    isMenuOpen = false -- Establecer el estado del menú a cerrado
    SendNUIMessage({
        action = 'CLOSE_MENU'
    })

    -- Restaurar controles al cerrar el menú
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    -- Habilitar controles de cámara nuevamente
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 200, true) -- Habilitar la tecla Escape
end

local function showHeader(data)
    if not data or not next(data) then
        return
    end
    headerShown = true
    sendData = data

    CreateThread(function()

        while headerShown do
            SetNuiFocus(true, true)
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            Wait(0)
        end
    end)

    SendNUIMessage({
        action = 'SHOW_HEADER',
        data = table.clone(data)
    })
end

-- Events

RegisterNetEvent('DP-Menu:client:openMenu', function(data, sort, skipFirst)
    openMenu(data, sort, skipFirst)
end)

RegisterNetEvent('DP-Menu:client:closeMenu', function()
    closeMenu()
end)

-- NUI Callbacks

RegisterNUICallback('clickedButton', function(option, cb)
    if headerShown then
        headerShown = false
    end
    PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', 1)
    SetNuiFocus(false)
    if sendData then
        local data = sendData[tonumber(option)]
        sendData = nil
        if data.action ~= nil then
            data.action()
            cb('ok')
            return
        end
        if data then
            if data.params.event then
                if data.params.isServer then
                    TriggerServerEvent(data.params.event, data.params.args)
                elseif data.params.isCommand then
                    ExecuteCommand(data.params.event)
                elseif data.params.isQBCommand then
                    TriggerServerEvent('QBCore:CallCommand', data.params.event, data.params.args)
                elseif data.params.isAction then
                    data.params.event(data.params.args)
                else
                    TriggerEvent(data.params.event, data.params.args)
                end
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    headerShown = false
    sendData = nil
    SetNuiFocus(false)
    cb('ok')
    TriggerEvent("DP-Menu:client:menuClosed")
end)

-- Exports
exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)
exports('sortData', sortData)

-- Exports para funciones de menú
RegisterCommand("qbmenutest", function()
    exports["DP-Menu"]:openMenu({{
        header = "DÉCIGNER STAYO",
        isMenuHeader = true -- Título sin icono
    }, -- Primeros 3 items con submenús
    {
        header = "A3 INSON",
        txt = "Ésta es la piel de sémener",
        icon = "fa-solid fa-user",
        params = {
            event = "DP-Menu:client:testMenu2",
            args = {
                pedName = "A3 INSON",
                message = "Menú de A3 INSON abierto"
            }
        }
    }, {
        header = "BENNETDOR",
        txt = "Ésta es la piel de superbloc",
        icon = "fa-solid fa-user-tie",
        params = {
            event = "DP-Menu:client:testMenu2",
            args = {
                pedName = "BENNETDOR",
                message = "Menú de BENNETDOR abierto"
            }
        }
    }, {
        header = "FAMILIEUR",
        txt = "Ésta es la piel de sémener",
        icon = "fa-solid fa-users",
        params = {
            event = "DP-Menu:client:testMenu2",
            args = {
                pedName = "FAMILIEUR",
                message = "Menú de FAMILIEUR abierto"
            }
        }
    }, -- Resto de items (9 más)
    {
        header = "MARINO",
        txt = "Ésta es la piel de marino",
        icon = "fa-solid fa-ship",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado MARINO"
            }
        }
    }, {
        header = "CAMARA",
        txt = "Ésta es la piel de cámara",
        icon = "fa-solid fa-camera",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado CAMARA"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, {
        header = "TIBURON",
        txt = "Ésta es la piel de tiburón",
        icon = "fa-solid fa-fish",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Has seleccionado TIBURON"
            }
        }
    }, -- Footer
    {
        header = "Cerrar",
        icon = "fa-solid fa-xmark",
        params = {
            event = "DP-Menu:closeMenu"
        }
    } -- {
    --     header = "Contactez",
    --     isMenuHeader = true
    -- }
    })
end)

-- Evento para submenús
RegisterNetEvent('DP-Menu:client:testMenu2', function(data)
    exports["DP-Menu"]:openMenu({{
        header = data.pedName,
        txt = "Opciones avanzadas",
        isMenuHeader = true
    }, {
        header = "Cambiar skin",
        icon = "fa-solid fa-user-pen",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Cambiando skin de " .. data.pedName
            }
        }
    }, {
        header = "Personalizar",
        icon = "fa-solid fa-sliders",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Personalizando " .. data.pedName
            }
        }
    }, {
        header = "Eliminar",
        icon = "fa-solid fa-trash",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Eliminando " .. data.pedName
            }
        }
    }, {
        header = "Información",
        icon = "fa-solid fa-info-circle",
        params = {
            event = "DP-Menu:client:testButton",
            args = {
                message = "Información de " .. data.pedName
            }
        }
    }, {
        header = "< Volver",
        params = {
            event = "qbmenutest" -- Vuelve al menú principal
        }
    }})
end)

-- Evento para acciones simples
RegisterNetEvent('DP-Menu:client:testButton', function(data)
    TriggerEvent('QBCore:Notify', data.message)
end)
