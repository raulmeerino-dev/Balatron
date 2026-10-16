-- Profile-owned discoveries. Collection availability never depends on gameplay toggles.
local C={filter=1,page_size=6}
local category_info=require('portrait_collection_info')
local family_view=require('portrait_collection_family')
local categories={'mutations','contracts','contraband'}
local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
local function label(key)
    local names={mutations='Mutations',contracts='Contracts',contraband='Contraband'}
    return names[key]
end
local function profile()
    return G.PROFILES and G.PROFILES[G.SETTINGS.profile]
end
function C.known(kind,id)
    local p=profile();local data=p and p.portrait_collection
    local X=PortraitExpansion48;local expansion_id=X and X.catalog_id(kind,id)
    if expansion_id then return X.discovered(expansion_id) and 1 or nil end
    if kind=='mutations' and PortraitModifierUnlocks then
        if not PortraitModifierUnlocks.discovered(id) then return nil end
        return data and data[kind] and data[kind][id] or 1
    end
    if p and p.all_unlocked then
        local m=PortraitGameplay and PortraitGameplay.modules.deck_mutations
        return kind=='mutations' and m and m.mod.config.max_level or 1
    end
    return data and data[kind] and data[kind][id]
end
function C.mark(kind,id,value)
    local p=profile();if not p or not id then return end
    value=value or 1
    local X=PortraitExpansion48;local expansion_id=X and X.catalog_id(kind,id)
    if expansion_id then X.discover(expansion_id) end
    if kind=='mutations' and PortraitModifierUnlocks then PortraitModifierUnlocks.discover(id) end
    local previous=p.portrait_collection and p.portrait_collection[kind] and p.portrait_collection[kind][id] or 0
    if previous>=value then return end
    p.portrait_collection=p.portrait_collection or {}
    local data=p.portrait_collection
    data[kind]=data[kind] or {};data[kind][id]=value
    G:save_progress()
    G.FILE_HANDLER.force=true -- Flush discoveries through the native profile writer next frame.
end
local function modules()
    local p=PortraitGameplay
    return p and p.modules.deck_mutations,p and p.modules.contracts,
        PortraitEvents and PortraitEvents.black_market
end
function C.entries(kind)
    local M,K,B=modules();local out={}
    if kind=='mutations' and M then
        for _,def in ipairs(M.definitions or {}) do out[#out+1]=def.id end
    elseif kind=='contracts' and K then
        for _,id in ipairs(K.order) do out[#out+1]=id end
    elseif kind=='contraband' and B then
        for _,id in ipairs(B.contraband.order) do out[#out+1]=id end
    end
    return out
end
function C.count(kind)
    local count={tally=0,of=0}
    for _,id in ipairs(C.entries(kind)) do
        count.of=count.of+1
        if C.known(kind,id) then count.tally=count.tally+1 end
    end
    return count
end
local function upg(card)
    local center=card.config and card.config.center
    if center and center.upg_id then
        C.mark('upg_forms',center.upg_id..':'..tostring(card.ability.extra.stage or 1))
    end
end
function C.migrate()
    -- Only recover evidence still present in an existing run; never reveal an entire registry.
    if G.STAGE~=G.STAGES.RUN then return end
    local M,K,B=modules()
    local state=M and M.state()
    for id,level in pairs(state and state.levels or {}) do if level>0 then C.mark('mutations',id,level) end end
    state=K and K.state()
    if state then for _,a in ipairs(K.active()) do C.mark('contracts',a.id) end end
    if state and state.last_result then C.mark('contracts',state.last_result.id) end
    if state and state.offer_shown and state.offer then C.mark('contracts',state.offer) end
    for _,card in ipairs(G.jokers and G.jokers.cards or {}) do upg(card) end
    local bm=G.GAME.portrait_events and G.GAME.portrait_events.black_market
    if bm then
        if bm.dice_ante then C.mark('contraband','loaded_dice') end
        if bm.reservation then C.mark('contraband','inside_information') end
        local saved=bm.current and bm.current.inventory
        for _,area in pairs(saved or {}) do
            for _,card in pairs(area.cards or {}) do
                local key=card.save_fields and card.save_fields.center
                local center=key and G.P_CENTERS[key]
                if center and center.bm_contraband then C.mark('contraband',center.bm_contraband) end
            end
        end
    end
end
local function row(text)
    return {n=G.UIT.R,config={align='cm',padding=0.08},nodes={
        {n=G.UIT.T,config={text=text,scale=0.4,colour=G.C.WHITE,shadow=true}}}}
end
local function info(kind,id)
    local M,K,B=modules()
    if kind=='mutations' then
        local data=M.visual_info(id,1)
        data.title=localize('k_dm_'..id)
        if data.max_tier then
            local tier=({'I','II','III'})[C.known(kind,id)] or tostring(C.known(kind,id))
            data.secondary[#data.secondary+1]=(es() and 'Nivel descubierto: ' or 'Level discovered: ')..tier..' / '..data.max_tier
        end
        return data,M.icon(id,1.85)
    elseif kind=='contracts' then
        return K.info({id=id},K.mod.config),K.icon(id,1.85)
    else
        local center=G.P_CENTERS['cb_evt_'..id]
        return {title=localize{type='name_text',set='Contraband',key=center.key},class=center.set,
            loc={set='Contraband',key=center.key,vars={2,center.cost}},
            text=localize{type='raw_descriptions',set='Contraband',key=center.key,
                vars={2,center.cost}}},
            PortraitRunGallery.sprite(center.atlas,center.pos,2.15*71/95,2.15)
    end
end
function C.open(kind,page)
    G.SETTINGS.paused=true
    if PortraitExpansion48 then PortraitExpansion48.sync_centers() end
    PortraitRunGallery.dismiss();C.migrate()
    C.category=kind
    local entries=C.entries(kind);local pages=math.max(1,math.ceil(#entries/C.page_size))
    page=math.max(1,math.min(page or 1,pages))
    local count=C.count(kind)
    local nodes={{n=G.UIT.R,config={align='cm'},nodes={
        {n=G.UIT.C,config={align='cm'},nodes={row(label(kind)..'  '..count.tally..' / '..count.of)}},
        category_info.button(kind)}}}
    local cells={}
    for i=(page-1)*C.page_size+1,math.min(page*C.page_size,#entries) do
        local id=entries[i];local known=C.known(kind,id)
        local data,art
        local X=PortraitExpansion48;local expansion_id=X and X.catalog_id(kind,id)
        local locked=expansion_id and not X.unlocked(expansion_id) or kind=='mutations' and PortraitModifierUnlocks and not PortraitModifierUnlocks.unlocked(id)
        if expansion_id and locked then
            local d=X.catalog[expansion_id]
            data={title=known and X.text(d.name,d.name_en) or '???',text={X.text('Bloqueado','Locked'),X.text(d.unlock,d.unlock_en or d.unlock)}}
            art={n=G.UIT.R,config={align='cm',minw=1.6,minh=2.15,r=0.12,colour=G.C.BLACK},nodes={row('?')}}
        elseif known and locked then
            local unlock=PortraitModifierUnlocks.info(id)
            local M=modules()
            data=M.visual_info(id,1)
            data.secondary=unlock.text
            art=M.locked_icon(id,1.85)
        elseif known then data,art=info(kind,id)
        else
            data={title='???',text={'???'}}
            art={n=G.UIT.R,config={align='cm',minw=1.6,minh=2.15,r=0.12,colour=G.C.BLACK},nodes={row('?')}}
        end
        if kind=='mutations' then data.class='Mutation'
        elseif kind=='contraband' then data.class='Contraband'
        elseif kind=='contracts' then data.class='Contract' end
        local details=data
        local tile=PortraitRunGallery.tile(art,function()
            return PortraitRunGallery.tooltip(details)
        end,nil,data.title)
        if known and not locked and kind=='mutations' and family_view.mutation_levels(id)>1 then
            tile.config.button='pc_family'
            tile.config.ref_table={kind=kind,id=id}
        end
        cells[#cells+1]=tile
        if #cells==3 or i==math.min(page*C.page_size,#entries) then
            nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.08},nodes=cells};cells={}
        end
    end
    if pages>1 then
        local options={};for i=1,pages do options[i]=i..' / '..pages end
        nodes[#nodes+1]=create_option_cycle{options=options,current_option=page,opt_callback='pc_page',w=6,h=portrait_touch_height(0.8)}
    end
    G.SETTINGS.paused=true
    G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='your_collection',contents={
        {n=G.UIT.C,config={align='cm',padding=0.08},nodes=nodes}}}}
end
local function family(center)
    if center.portrait_family=='doubles' then return 7 end
    if center.upg_id then return 4 end
    if center.risk_id then return 5 end
    if center.rarity=='fuse_fusion' then return 6 end
    return center.mod and 3 or 2
end
function C.jokers()
    if PortraitExpansion48 then PortraitExpansion48.sync_centers() end
    C.migrate()
    local F=PortraitGameplay and PortraitGameplay.modules.joker_fusion
    if F then F.sync_discovery() end
    if portrait_hook_smods_collection then portrait_hook_smods_collection() end
    local pool={};local count={tally=0,of=0}
    for _,center in ipairs(SMODS.collection_pool(G.P_CENTER_POOLS.Joker)) do
        if C.filter==1 or family(center)==C.filter then
            pool[#pool+1]=center;count.of=count.of+1
            if center.discovered then count.tally=count.tally+1 end
        end
    end
    local def=SMODS.card_collection_UIBox(pool,{4,4,4},{no_materialize=true,h_mod=0.95,hide_single_page=true,collapse_single_page=true,
        modify_card=function(card,center)
            card.sticker=get_joker_win_sticker(center)
            if center.upg_id and center.unlocked~=false then
                -- Only these temporary Collection cards open the family view.
                -- Owned/shop cards keep their native click and scoring behavior.
                function card:click()
                    if G.OVERLAY_MENU and not G.OVERLAY_MENU.pc_collection_underlay then
                        self:stop_hover()
                        family_view.open('upg',center.upg_id)
                    end
                end
            end
        end})
    local contents=def.nodes[1].nodes[1].nodes[1].nodes
    local filter_nodes={{n=G.UIT.C,config={align='cm'},nodes={create_option_cycle{
        options={es() and 'TODOS' or 'ALL','VANILLA','EXTRA','UPG','RISK','FUSION',es() and 'DOBLES' or 'DOUBLES'},
        current_option=C.filter,opt_callback='pc_joker_filter',w=6,h=portrait_touch_height(0.8)}}}}
    local help_key=({[3]='extra',[4]='upg',[5]='risk',[6]='fusion',[7]='doubles'})[C.filter]
    if help_key then filter_nodes[#filter_nodes+1]=category_info.button(help_key) end
    table.insert(contents,1,{n=G.UIT.R,config={align='cm'},nodes=filter_nodes})
    table.insert(contents,2,row(count.tally..' / '..count.of))
    return def
end
function C.install()
    if PortraitCollection or not (SMODS and PortraitGameplay) then return end
    PortraitCollection=C
    category_info.install()
    G.FUNCS.pc_family=function(e)
        local target=e.config.ref_table
        family_view.open(target.kind,target.id)
    end
    local M,K,B=modules()
    if M then
        local choice=M.choice
        function M.choice(id,n) C.mark('mutations',id,n);return choice(id,n) end
        local choose=G.FUNCS.dm_choose
        G.FUNCS.dm_choose=function(e)
            choose(e)
            local level=M.state().levels and M.state().levels[e.config.ref_table]
            if level then C.mark('mutations',e.config.ref_table,level) end
        end
    end
    if K then
        local offer=K.offer
        function K.offer(...)
            local result=offer(...)
            if result then C.mark('contracts',K.state().offer) end
            return result
        end
    end
    if B then
        local checkpoint=B.checkpoint
        function B.checkpoint(...)
            if B.active then
                for _,card in ipairs(G.shop_booster and G.shop_booster.cards or {}) do
                    C.mark('contraband',card.config.center.bm_contraband)
                end
            end
            return checkpoint(...)
        end
    end
    local add=Card.add_to_deck
    function Card:add_to_deck(...)
        local result=add(self,...);upg(self);return result
    end
    if UPGJokers then
        local evolve=UPGJokers.evolution.upgrade
        function UPGJokers.evolution.upgrade(def,card,...)
            local result=evolve(def,card,...);if result then upg(card) end;return result
        end
    end
    local start=Game.start_run
    function Game:start_run(...) local result=start(self,...);C.migrate();return result end
    G.FUNCS.pc_page=function(e) C.open(C.category,e.to_key) end
    for _,kind in ipairs(categories) do
        local key=kind;G.FUNCS['pc_'..key]=function() C.open(key) end
    end
    G.FUNCS.pc_joker_filter=function(e)
        C.filter=e.to_key;G.FUNCS.your_collection_jokers()
    end
    create_UIBox_your_collection_jokers=C.jokers
    -- Keep the old Fusion link usable, but point it at the shared Joker collection.
    G.FUNCS.fuse_collection=function() C.filter=6;G.FUNCS.your_collection_jokers() end
    local collection=create_UIBox_your_collection
    function create_UIBox_your_collection(...)
        C.migrate();C.filter=1
        local def=collection(...)
        local buttons={}
        local function collect(node)
            local child=node.nodes and node.nodes[1]
            if child and child.config and child.config.button then
                local button=child.config.button
                if button:find('^your_collection_') then
                    buttons[#buttons+1]={n=node.n,config=node.config,nodes={child}};return
                end
            end
            for _,n in ipairs(node.nodes or {}) do collect(n) end
        end
        collect(def)
        for _,kind in ipairs(categories) do
            buttons[#buttons+1]=UIBox_button{button='pc_'..kind,label={label(kind)},count=C.count(kind),minw=4.4}
        end
        -- Skins remain in the existing native Customize Deck system.
        if CardSkins then
            buttons[#buttons+1]=UIBox_button{button='customize_deck',label={es() and 'Skins de baraja' or 'Deck skins'},minw=4.4}
        end
        local function resize(node,w)
            local c=node.config or {}
            if c.minw then c.minw=w end
            if c.maxw then c.maxw=w-0.2 end
            if c.button then c.minh=portrait_touch_height(0.9) end
            if c.scale then c.scale=math.min(c.scale,0.4) end
            for _,n in ipairs(node.nodes or {}) do resize(n,w) end
        end
        local rows={}
        for i=1,#buttons,2 do
            local cells={}
            for j=i,math.min(i+1,#buttons) do
                local button=buttons[j]
                resize(button,4.4)
                cells[#cells+1]={n=G.UIT.C,config={align='cm',padding=0.08},nodes={button}}
            end
            rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=cells}
        end
        return create_UIBox_generic_options{back_func=G.STAGE==G.STAGES.RUN and 'options' or 'exit_overlay_menu',contents={
            {n=G.UIT.C,config={align='cm',padding=0.05},nodes=rows}}}
    end

end
return C
