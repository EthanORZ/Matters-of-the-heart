require "/scripts/util.lua"
-- Code courtesy of the sxb team because making this myself would give me an aneurysm

--- Returns a table consisting of identifying information about the entity.
function buildIdentity()
    local identity = {
        gender = player.gender() or "male",
        species = player.species() or "human",
        name = world.entityName(player.id()) or "",
        bodyDirectives = "",
        emoteDirectives = "",
        facialHairDirectives = "",
        facialMaskDirectives = "",
        hairDirectives = "",
        facialHairFolder = "",
        facialHairGroup = "",
        facialHairType = "",
        facialMaskFolder = "",
        facialMaskGroup = "",
        facialMaskType = "",
        hairFolder = "hair",
        hairGroup = "hair",
        hairType = "1"
    }

    util.each(world.entityPortrait(player.id(), "fullnude"), function(k, v)
        -- Attempt to find facial mask
        if identity.facialMaskGroup ~= nil and identity.facialMaskGroup ~= "" and
            string.find(v.image, "/" .. identity.facialMaskGroup) ~= nil then
            identity.facialMaskFolder, identity.facialMaskType =
                string.match(v.image, '^.*/(' .. identity.facialMaskGroup .. '.*)/(.*)%.png:.-$')
            identity.facialMaskDirectives = filterReplace(v.image)
        end

        -- Attempt to find facial hair
        if identity.facialHairGroup ~= nil and identity.facialHairGroup ~= "" and
            string.find(v.image, "/" .. identity.facialHairGroup) ~= nil then
            identity.facialHairFolder, identity.facialHairType =
                string.match(v.image, '^.*/(' .. identity.facialHairGroup .. '.*)/(.*)%.png:.-$')
            identity.facialHairDirectives = filterReplace(v.image)
        end

        -- Attempt to find body identity
        if (string.find(v.image, "body.png") ~= nil) then
            identity.bodyDirectives = string.match(v.image, '%?replace.*')
        end

        -- Attempt to find emote identity
        if (string.find(v.image, "emote.png") ~= nil) then
            identity.emoteDirectives = filterReplace(v.image)
        end

        -- Attempt to find hair identity
        if (string.find(v.image, "/hair") ~= nil) then
            identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png:.-$')

            identity.hairDirectives = filterReplace(v.image)
        end
    end)

    return identity
end

--- Returns a filtered string. Used to filter desired data out of directive strings.
-- @param image
function filterReplace(image)
    if (string.find(image, "?addmask")) then
        if (string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')) then
            return string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')
        else
            return string.match(image, '^.*(%?replace.*)%?addmask.-$')
        end
    else
        if (string.match(image, '^.*(%?replace.*%?replace.*)')) then
            return string.match(image, '^.*(%?replace.*%?replace.*)')
        else
            return string.match(image, '^.*(%?replace.*)')
        end
    end
end