-- Read-only presentation of the current run. Preview sprites never own cards.
local V={columns=4,icon_size=1.85,card_height=2.15,cell_width=2.25,gap=0.08}
local labels={
    es={effects='EFFECTS',until_ante='Vigente hasta el final del Ante',mutations='MUTATIONS',upg='UPG JOKERS',risk='RISK JOKERS',
        contract='CONTRACT',fusion='FUSIONS',market='BLACK MARKET',other='EXTRA JOKERS',
        level='Nivel',next='Siguiente',final='Forma final',progress='Progreso',
        cooldown='Tiendas de bloqueo restantes',rerolls='Cambios en esta visita',open='Toca para abrir',
        empty='Sin contenido custom activo',history='HISTORIAL',round='Ronda',jokers='JOKERS',run='RUN',
        failed='Falla si: ',failures={clean_hands='descartas.',one_shot='necesitas mÃ¡s de una mano.',
            monochrome='la mano ganadora puntÃºa varios palos.',high_roller='sales de la siguiente tienda sin gastar el objetivo.',
            no_safety_net='usas un consumible durante la ciega jefe.',execution='ganas al jefe sin destruir las cartas requeridas.',
            debt_collector='terminas la apuesta inicial sin el dinero requerido.'}},
    en={effects='EFFECTS',until_ante='Active until the end of Ante',mutations='MUTATIONS',upg='UPG JOKERS',risk='RISK JOKERS',
        contract='CONTRACT',fusion='FUSIONS',market='BLACK MARKET',other='EXTRA JOKERS',
        level='Level',next='Next',final='Final form',progress='Progress',
        cooldown='Locked shops remaining',rerolls='Rerolls this visit',open='Tap to open',
        empty='No active custom content',history='HISTORY',round='Round',jokers='JOKERS',run='RUN',
        failed='Fails if: ',failures={clean_hands='you discard.',one_shot='you need more than one hand.',
            monochrome='the winning hand scores multiple suits.',high_roller='you leave the next shop below the spending target.',
            no_safety_net='you use a consumable during the Boss Blind.',execution='you beat the boss without destroying enough cards.',
            debt_collector='you finish the ante without the required money.'}},
}
local function words() return labels[(G.SETTINGS.language or ''):sub(1,2)=='es' and 'es' or 'en'] end
function V.wrap(lines,limit)
    local out={}
    for _,text in ipairs(lines or {}) do
        local line=''
        for word in tostring(text):gmatch('%S+') do
            if #line>0 and #line+#word+1>limit then out[#out+1]=line;line='' end
            line=line=='' and word or line..' '..word
        end
        if line~='' then out[#out+1]=line end
    end
    return out
end
local function row(text,scale)
    return {n=G.UIT.R,config={align='cm',padding=0.035},nodes={
        {n=G.UIT.T,config={text=text,scale=scale or 0.34,colour=G.C.WHITE,shadow=true}}}}
end
local function sprite(atlas,pos,w,h)
    local art=Sprite(0,0,w,h or w,assert(G.ASSET_ATLAS[atlas],atlas),pos or {x=0,y=0})
    art.created_on_pause=true
    art.states.collide.can=false;art.states.hover.can=false;art.states.drag.can=false
    return {n=G.UIT.O,config={object=art}}
end
-- All custom families share the native presentation components.
V.item_tooltip=require('portrait_tooltips').item
local function tooltip(info)
    if info.class then return V.item_tooltip(info) end
    return create_popup_UIBox_tooltip{title=info.title,text=V.wrap(info.text,38)}
end
V.tooltip=tooltip
local function tile(art,tip,tier,title)
    local nodes={{n=G.UIT.R,config={align='cm',minh=V.card_height+0.1},nodes={art}}}
    if tier then nodes[#nodes+1]=row(tier,0.3) end
    local names={}
    for _,line in ipairs(V.wrap({title or ''},14)) do
        local name=row(line,0.38);name.config.maxw=V.cell_width;names[#names+1]=name
    end
    nodes[#nodes+1]={n=G.UIT.R,config={align='cm',minh=0.8,maxw=V.cell_width},nodes=names}
    return {n=G.UIT.C,config={align='cm',padding=V.gap,minw=V.cell_width,maxw=V.cell_width,minh=3.15,
        colour=G.C.CLEAR,hover=true,on_demand_tooltip={},pg_visual_tooltip=tip,
        button='pg_gallery_inspect'},nodes=nodes}
end
V.tile=tile
V.sprite=sprite
local function joker_tile(card)
    local center=card.config.center
    local source=card.children.center
    local pos=source.sprite_pos
    local def=center.upg_id and UPGJokers.registry.entries[center.upg_id]
    if def then pos=def.stages[card.ability.extra.stage or 1].sprite end
    local name_key=def and def.stages[card.ability.extra.stage or 1].loc_key or center.key
    return tile(sprite(source.atlas.name,pos,V.card_height*71/95,V.card_height),function()
        -- Native tooltip reads the actual instance, including editions and debuffs.
        local preview=setmetatable({ability_UIBox_table=card:generate_UIBox_ability_table()},{__index=card})
        local popup=G.UIDEF.card_h_popup(preview)
        return popup
    end,nil,localize{type='name_text',set='Joker',key=name_key})
end
V.joker_tile=joker_tile
function V.groups(filter)
    local P=PortraitGameplay
    local groups={}
    local function add(key,items,columns) if #items>0 and (not filter or filter==key) then groups[#groups+1]={key=key,items=items,columns=columns} end end
    -- Accepted contract state is independent of module availability/configuration.
    local C=P and P.modules.contracts
    local state=C and C.state()
    local items={}
    if not filter or filter=='contract' then
        local active=C and C.active() or {}
        for _,a in ipairs(active) do
            items[#items+1]=tile(C.icon(a.id,V.icon_size),function() return tooltip(C.info(a)) end,nil,localize('k_ct_'..a.id))
        end
        if #active==0 then
            items[1]=row(localize('k_pg_none'),0.32)
        end
        if state and (state.pending_spectral or 0)>0 then
            items[#items+1]=P.button(localize('b_ct_claim'),'ct_claim')
        end
    end
    add('contract',items)
    local M=P and P.modules.deck_mutations
    items={}
    if M and (not filter or filter=='mutations') then
        for _,id in ipairs(M.active_visuals()) do
            local info=M.visual_info(id)
            items[#items+1]=tile(M.icon(id,V.icon_size),function()
                local data=M.visual_info(id)
                if data.tier then data.secondary[#data.secondary+1]=words().level..': '..data.tier..' / '..data.max_tier end
                return tooltip(data)
            end,info.tier,localize('k_dm_'..id))
        end
    end
    add('mutations',items)
    local jokers={upg={},risk={},fusion={},other={}}
    for _,card in ipairs(G.jokers and G.jokers.cards or {}) do
        local c=card.config.center
        local key=c.upg_id and 'upg' or c.risk_id and 'risk' or c.rarity=='fuse_fusion' and 'fusion'
            or c.mod and c.mod.id=='incremental_joker' and 'other'
        if key and (not filter or filter==key) then jokers[key][#jokers[key]+1]=joker_tile(card) end
    end
    add('upg',jokers.upg);add('risk',jokers.risk)
    local F=P and P.modules.joker_fusion
    if not filter or filter=='fusion' then
        add('fusion',F and F.run_rows and F.run_rows(V,jokers.fusion) or jokers.fusion,F and F.run_rows and 1 or nil)
    end
    add('other',jokers.other)
    local bm=G.GAME.portrait_events and G.GAME.portrait_events.black_market
    items={}
    if bm and ((bm.heat or 0)>0 or (bm.cooldown or 0)>0) and (not filter or filter=='market') then
        items[1]=tile(sprite('evt_dealer',nil,V.icon_size*80/72,V.icon_size),function()
            local lines={localize('k_evt_heat')..': '..tostring(bm.heat or 0),words().cooldown..': '..tostring(bm.cooldown or 0)}
            if bm.current then lines[#lines+1]=words().rerolls..': '..tostring(bm.current.rerolls or 0) end
            return tooltip{title=words().market,text=lines}
        end,nil,localize('k_evt_heat')..': '..tostring(bm.heat or 0))
    end
    add('market',items)
    items={}
    local B=PortraitEvents and PortraitEvents.black_market
    if bm and B and (not filter or filter=='effects') then
        local ante=G.GAME.round_resets.ante
        local function effect(id,extra)
            local center=G.P_CENTERS['cb_evt_'..id]
            if not center then return end
            local name=localize{type='name_text',set='Contraband',key=center.key}
            items[#items+1]=tile(sprite(center.atlas,center.pos,V.card_height*71/95,V.card_height),function()
                local c=B.config()
                local lines=localize{type='raw_descriptions',set='Contraband',key=center.key,
                    vars={2,center.cost}}
                local secondary={words().until_ante..' '..tostring(ante)}
                if extra then secondary[#secondary+1]=extra end
                return tooltip{title=name,text=lines,loc={set='Contraband',key=center.key,vars={2,center.cost}},secondary=secondary,class=center.set}
            end,nil,name)
        end
        if bm.dice_ante==ante then effect('loaded_dice') end

    end
    add('effects',items)
    return groups
end
function V.panel()
    local layout=G.F_PORTRAIT and (require('portrait_run_info').active or require('portrait_run_info').metrics())
    local width=layout and layout.content-.24 or V.columns*(V.cell_width+2*V.gap)+.25
    local per_row=math.max(1,math.min(V.columns,math.floor((width-.16-V.gap)/(V.cell_width+3*V.gap))))
    local nodes={}
    for _,group in ipairs(V.groups()) do
        nodes[#nodes+1]=row(words()[group.key],0.34)
        local columns=math.min(group.columns or V.columns,per_row)
        for first=1,#group.items,columns do
            local cells={}
            for i=first,math.min(first+columns-1,#group.items) do cells[#cells+1]=group.items[i] end
            nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=V.gap},nodes=cells}
        end
    end
    local Scroll=require('portrait_run_scroll')
    local height=layout and layout.height-.24 or math.min(10.8,G.ROOM.T.h*0.57)
    local view=Scroll(nodes,width,height)
    return {n=G.UIT.ROOT,config={id='pg_gallery',align='cm',padding=0.12,colour=G.C.CLEAR,
        minw=layout and layout.content,portrait_run_content=layout and {width=layout.content,height=layout.height}},
        nodes={{n=G.UIT.R,config={align='cm',padding=0},nodes={
            {n=G.UIT.O,config={id='pg_run_scroll',object=view}}}}}}
end
function V.refresh()
    local overlay=G.OVERLAY_MENU
    local root=overlay and overlay:get_UIE_by_ID('pg_gallery')
    local host=root and overlay:get_UIE_by_ID('tab_contents')
    if not host then return end
    local view=overlay:get_UIE_by_ID('pg_run_scroll').config.object
    local offset=view.offset
    V.dismiss()
    host.config.object:remove()
    host.config.object=UIBox{definition=V.panel(),config={offset={x=0,y=0},parent=host,type='cm'}}
    overlay:recalculate()
    local next_root=overlay:get_UIE_by_ID('pg_gallery')
    overlay:get_UIE_by_ID('pg_run_scroll').config.object:scroll(offset)
end
function V.dismiss()
    if V.inspected and not V.inspected.REMOVED then Node.stop_hover(V.inspected) end
    V.inspected=nil
end
function V.open()
    V.dismiss()
    PortraitGameplay.open_run_tab=true
    G.FUNCS.run_info()
    PortraitGameplay.open_run_tab=nil
end
function V.install()
    if PortraitRunGallery then return end
    PortraitRunGallery=V
    require('portrait_run_scroll').install()
    G.FUNCS.pg_gallery_inspect=function(e)
        if e.config.pg_hold_only then return end
        if V.inspected==e then V.dismiss();return end
        V.dismiss();V.inspected=e;e:hover()
    end
    local hover=UIElement.hover
    function UIElement:hover()
        if not self.config.pg_visual_tooltip then return hover(self) end
        if self.config.pg_hold_only and not self.config.pg_run_holding then return end
        if V.inspected and V.inspected~=self then V.dismiss() end
        self.config.h_popup=self.config.pg_visual_tooltip()
        self.config.h_popup_config={align=self.T.y>G.ROOM.T.h/2 and 'tm' or 'bm',
            offset={x=0,y=self.T.y>G.ROOM.T.h/2 and -0.1 or 0.1},parent=self,
            fit_to_room=true,snap_to_fit=true,can_drag=false}
        Node.hover(self)
    end
    local stop_hover,click=UIElement.stop_hover,UIElement.click
    function UIElement:stop_hover()
        if V.inspected==self and not self.REMOVED then return end
        return stop_hover(self)
    end
    function UIElement:click(...)
        if self.config.button~='pg_gallery_inspect' then V.dismiss() end
        return click(self,...)
    end
end
return V
