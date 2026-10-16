-- Full playing-card skins share the existing Customize Deck screen/settings.
-- Atlas cells remain 71x95 logical units, independent of texture quality.
CardSkins = {
    order = {'default', 'deck1', 'four_realms', 'four_realms_v2', 'velvet_catastrophe', 'dream_circuit', 'carnival_relics'},
    registry = {
        default = {label = 'Default'},
        deck1 = {label = 'Deck 1', path = 'assets/skins/deck1/', dpi = 4},
        four_realms = {label = 'Four Realms', path = 'assets/skins/four_realms/', dpi = 2, partial = true},
        four_realms_v2 = {label = 'Four Realms V2', path = 'assets/skins/four_realms_v2/', dpi = 2, partial = true},
        velvet_catastrophe = {label = 'Velvet Catastrophe', path = 'assets/skins/velvet_catastrophe/', dpi = 2, partial = true},
        dream_circuit = {label = 'Dream Circuit', path = 'assets/skins/dream_circuit/', dpi = 2, partial = true},
        carnival_relics = {label = 'Carnival Relics', path = 'assets/skins/carnival_relics/', dpi = 2, partial = true},
    },
}

function CardSkins.active()
    local id = G.SETTINGS.CUSTOM_DECK and G.SETTINGS.CUSTOM_DECK.skin or 'default'
    return CardSkins.registry[id] and id or 'default'
end

function CardSkins.load_atlases()
    for id, skin in pairs(CardSkins.registry) do
        if skin.partial then
            -- Transparent front overlays retain vanilla paper/enhancements and suit indices.
            for _, contrast in ipairs({'lc','hc'}) do
                local name='skin_'..id..'_'..contrast
                local image=love.graphics.newImage(skin.path..'fronts_'..contrast..'.png',
                    {mipmaps=false,dpiscale=skin.dpi})
                image:setFilter('nearest','nearest')
                G.ASSET_ATLAS[name]={name=name,image=image,px=71,py=95}
            end
        elseif skin.path then
            for _, kind in ipairs({'fronts', 'enhanced', 'back', 'wild'}) do
                local name = 'skin_'..id..'_'..kind
                local image = love.graphics.newImage(skin.path..(kind == 'wild' and 'enhanced' or kind)..'.png', {mipmaps = true, dpiscale = skin.dpi})
                if id == 'deck1' then
                    -- One GPU colour pass on load. Coordinates/alpha and every
                    -- original pip and index remain identical in all card views.
                    local shader = love.graphics.newShader('assets/skins/deck1/contrast.fs')
                    shader:send('suit_tint', kind ~= 'back')
                    local w,h = image:getDimensions()
                    local canvas = love.graphics.newCanvas(w,h,{dpiscale=skin.dpi,mipmaps='auto'})
                    love.graphics.push('all')
                    love.graphics.setCanvas(canvas)
                    love.graphics.origin()
                    love.graphics.setScissor()
                    love.graphics.clear(0,0,0,0)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setBlendMode('replace','premultiplied')
                    love.graphics.setShader(shader)
                    love.graphics.draw(image)
                    love.graphics.pop()
                    shader:release();image:release()
                    image = canvas
                end
                if kind == 'wild' then
                    -- The first atlas load precedes prototype registration.
                    local wild = G.P_CENTERS and G.P_CENTERS.m_wild or {pos={x=3,y=1}}
                    local base = G.P_CENTERS and G.P_CENTERS.c_base or {pos={x=1,y=0}}
                    local native = G.ASSET_ATLAS[wild.atlas or 'centers']
                    local shader = love.graphics.newShader(skin.path..'wild.fs')
                    shader:send('centers', native.image)
                    shader:send('cell_size', {native.px/native.image:getWidth(), native.py/native.image:getHeight()})
                    shader:send('wild_pos', {wild.pos.x, wild.pos.y})
                    shader:send('base_pos', {base.pos.x, base.pos.y})
                    local w,h = image:getDimensions()
                    local canvas = love.graphics.newCanvas(w,h,{dpiscale=skin.dpi,mipmaps='auto'})
                    love.graphics.push('all')
                    love.graphics.setCanvas(canvas)
                    love.graphics.origin()
                    love.graphics.setScissor()
                    love.graphics.clear(0,0,0,0)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setBlendMode('replace','premultiplied')
                    love.graphics.setShader(shader)
                    love.graphics.draw(image)
                    love.graphics.pop()
                    shader:release();image:release()
                    image = canvas
                end
                image:setFilter('linear', 'linear', 1)
                image:setMipmapFilter('linear', 0)
                G.ASSET_ATLAS[name] = {name = name, image = image, px = 71, py = 95}
            end
        end
    end
end

function CardSkins.front(front, card)
    if not (front and front.suit and front.pos) then return end
    local id = CardSkins.active()
    if id == 'default' then return end
    if CardSkins.registry[id].partial then
        return G.ASSET_ATLAS['skin_'..id..'_'..(G.SETTINGS.colourblind_option and 'hc' or 'lc')],front.pos
    end
    local enhanced = card and card.config.center and card.config.center.set == 'Enhanced'
    local wild = card and card.config.center == G.P_CENTERS.m_wild
    local atlas = G.ASSET_ATLAS['skin_'..id..(wild and '_wild' or enhanced and '_enhanced' or '_fronts')]
    if atlas then return atlas, front.pos end
end

function CardSkins.uses_run_back(card)
    local params = card.params or {}
    return G.STAGE == G.STAGES.RUN
        and card.config.card and card.config.card.suit
        and not params.viewed_back and not params.bypass_back
        and card.back ~= 'viewed_back'
        and (card.playing_card or card.skin_run_preview) and true or false
end

function CardSkins.refresh_back(card)
    if not (card.config.card and card.config.card.suit and card.children.back) then return end
    local atlas = CardSkins.uses_run_back(card) and G.ASSET_ATLAS['skin_'..CardSkins.active()..'_back']
    local pos = {x = 0, y = 0}
    if not atlas then
        -- Leave native deck identities/atlases alone, including unlock previews.
        -- Restore only a back that this skin actually replaced.
        if not (card.children.back.atlas.name or ''):match('^skin_') then return end
        local back = G.GAME and G.GAME[card.back]
        local name = back and (back[G.SETTINGS.colourblind_option and 'hc_atlas' or 'lc_atlas'] or back.atlas) or 'centers'
        atlas = G.ASSET_ATLAS[name or 'centers']
        pos = card.params.bypass_back or ((card.playing_card or card.skin_run_preview) and back and back.pos) or G.P_CENTERS.b_red.pos
    end
    card.children.back.atlas = atlas
    card.children.back:set_sprite_pos(pos)
end

function CardSkins.select(index)
    G.SETTINGS.CUSTOM_DECK = G.SETTINGS.CUSTOM_DECK or {Collabs = {}}
    G.SETTINGS.CUSTOM_DECK.skin = CardSkins.order[index] or 'default'
    for _, card in pairs(G.I.CARD) do
        if card.config and card.config.card and card.config.card.suit then
            card:set_sprites(nil, card.config.card)
        end
    end
    G:save_settings()
end

function CardSkins.options()
    local options, current = {}, 1
    for i, id in ipairs(CardSkins.order) do
        options[i] = CardSkins.registry[id].label
        if id == CardSkins.active() then current = i end
    end
    return options, current
end
