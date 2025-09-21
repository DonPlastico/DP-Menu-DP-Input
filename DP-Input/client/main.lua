local properties = nil

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    Wait(1000)
    SendNUIMessage({
        action = 'SET_STYLE',
        data = Config.Style
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SendNUIMessage({
        action = 'SET_STYLE',
        data = Config.Style
    })
end)

RegisterNUICallback('buttonSubmit', function(data, cb)
    SetNuiFocus(false)
    properties:resolve(data.data)
    properties = nil
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false)
    properties:resolve(nil)
    properties = nil
    cb('ok')
end)

local function ShowInput(data)
    Wait(150)
    if not data then
        return
    end
    if properties then
        return
    end

    properties = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_MENU',
        data = data
    })

    return Citizen.Await(properties)
end

exports('ShowInput', ShowInput)

-- Añade esto al final de tu main.lua
RegisterCommand('testinput', function()
    local inputData = {
        header = "LSPD MENU TEST", -- Título estilo LSPD
        inputs = {{ -- Text input
            text = "Nombre del sospechoso", -- placeholder
            name = "nombre", -- name id
            type = "text", -- type
            isRequired = true -- optional
        }, { -- Password
            text = "Contraseña de acceso",
            name = "pass",
            type = "password"
        }, { -- Number input
            text = "Edad",
            name = "edad",
            type = "number",
            isRequired = true
        }, { -- Radio input (like toggle options)
            text = "Estado del caso",
            name = "estado",
            type = "radio",
            options = {{
                value = "abierto",
                text = "Abierto"
            }, {
                value = "investigacion",
                text = "En investigación"
            }, {
                value = "cerrado",
                text = "Cerrado"
            }}
        }, { -- Select input
            text = "Tipo de delito",
            name = "delito",
            type = "select",
            options = {{
                value = "menor",
                text = "Delito menor"
            }, {
                value = "grave",
                text = "Delito grave"
            }, {
                value = "felonia",
                text = "Felonía"
            }}
        }, { -- Checkbox
            text = "Opciones adicionales",
            name = "opciones",
            type = "checkbox",
            options = {{
                value = "arma",
                text = "Portaba arma",
                checked = false
            }, {
                value = "resistencia",
                text = "Ofreció resistencia",
                checked = true
            }, {
                value = "fuga",
                text = "Intentó fuga",
                checked = false
            }}
        }, { -- Color picker
            text = "Color del vehículo",
            name = "color",
            type = "color",
            default = "#0ea021"
        }},
        submitText = "Confirmar" -- Texto del botón de submit
    }

    local result = exports['DP-Input']:ShowInput(inputData)

    if result then
        print("Resultados del formulario:")
        for k, v in pairs(result) do
            print(k .. ": " .. tostring(v))
        end
    else
        print("Formulario cancelado")
    end
end, false)
