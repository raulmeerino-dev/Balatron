-- Main Mods screen. Only generation preferences are edited here.
-- Saved runs, loader switches and Collection discovery remain owned by their modules.
local M={}
local copy={
    es={title='Mods',system='Sistema',
        enable='Activar todos',disable='Desactivar todos',
        on='Activo',off='Inactivo',required='Obligatorio',readonly='Solo lectura',unavailable='No disponible',
        waiting='Padre apagado',next='Siguiente run',close='Cerrar',class='Clase: ',selected=' seleccionados',
        applies='Los cambios se aplican a una nueva run.',for_next='Selección para la próxima run',
        core='Permite usar juntos los sistemas de juego adicionales.',
        loader='Permite añadir contenido y funciones a Balatro.',
        failed='Error al guardar: selección restaurada.',
        partial='Algunos cambios no se guardaron.',
        saved='Selección guardada',empty='No hay mods disponibles.'},
    en={title='Mods',system='System',
        enable='Enable all',disable='Disable all',
        on='Active',off='Inactive',required='Required',readonly='Read only',unavailable='Unavailable',
        waiting='Parent inactive',next='Next run',close='Close',class='Class: ',selected=' selected',
        applies='Changes apply to a new run.',for_next='Selection for the next run',
        core='Lets the additional gameplay systems work together.',
        loader='Adds support for new content and features in Balatro.',
        failed='Save failed: selection restored.',
        partial='Some changes could not be saved.',
        saved='Selection saved',empty='No mods available.'},
}
local function words() return copy[(G.SETTINGS.language or ''):sub(1,2)=='es' and 'es' or 'en'] end
local families={incremental_joker='EXTRA',upgraded_jokers='UPG',risk_jokers='RISK',joker_fusion='FUSION',
    contracts='CONTRACTS',deck_mutations='MUTATIONS',portrait_events='CONTRABAND',portrait_gameplay='SYSTEM',portrait_horizons='HORIZONS'}
local order={'incremental_joker','doubles','upgraded_jokers','risk_jokers','joker_fusion','contracts','deck_mutations','portrait_events','portrait_horizons','portrait_gameplay'}
local function row(str,scale,width,colour,ref,key,align)
    if ref then
        return {n=G.UIT.R,config={align=align or 'cm',padding=0.025,minw=width,minh=0.34},nodes={
            {n=G.UIT.O,config={object=DynaText{string={{ref_table=ref,ref_value=key}},scale=scale or 0.34,
                colours={colour or G.C.WHITE},maxw=width,silent=true,shadow=true,non_recalc=true}}}}}
    end
    return {n=G.UIT.R,config={align=align or 'cm',padding=0.025,maxw=width},nodes={
        {n=G.UIT.T,config={text=str,scale=scale or 0.34,colour=colour or G.C.WHITE,shadow=true,
            ref_table=ref,ref_value=key,no_recalc=true}}}}
end
local function read(v,config)
    if not config or not v.spec then return false end
    if v.field then
        local parent=v.id=='portrait_events' and config.events and config.events.black_market==true or
            v.id~='portrait_events' and config.enabled==true
        local item=config[v.field] and config[v.field][v.key]
        return parent and (v.weight and (item or 0)>0 or not v.weight and item~=false) or false
    end
    if v.id=='portrait_events' then return config.events and config.events[v.key]==true or false end
    local enabled=config[v.spec.enabled_field or 'enabled']
    if enabled==nil then enabled=config.enabled end
    if v.child then
        local weights=v.id=='risk_jokers' and config.risk_weights or v.id=='upgraded_jokers' and config.upg_weights
        return not v.unavailable and (not weights or (weights[v.key] or 0)>0) and
            enabled==true and config.jokers and config.jokers[v.key]==true or false
    end
    return enabled==true
end
local function chosen(v)
    if not v.control then return v.mod.can_load and not v.mod.disabled end
    if v.field then
        local item=v.mod.config[v.field] and v.mod.config[v.field][v.key]
        return v.weight and (item or 0)>0 or not v.weight and item~=false
    end
    if v.control.kind=='toggle' then local a=v.control.args;return a.ref_table[a.ref_value]==true end
    if v.child then return v.mod.config.jokers[v.key]==true end
    return read(v,v.mod.config)
end
local function snapshot(v)
    if not v.spec or G.STAGE~=G.STAGES.RUN or not G.GAME then return end
    local c=G.GAME[v.spec.snapshot]
    if v.id=='portrait_events' then c=c and c.config end
    return c
end
local function refresh(v)
    local w=words()
    local weights=v.child and (v.id=='risk_jokers' and v.mod.config.risk_weights or v.id=='upgraded_jokers' and v.mod.config.upg_weights)
    v.zero_weight=weights and (weights[v.key] or 0)<=0
    v.enabled=v.control and read(v,v.mod.config) or not v.control and chosen(v)
    v.blocked=v.child and v.parent and not read(v.parent,v.mod.config)
    local run=snapshot(v)
    v.pending=v.control and G.STAGE==G.STAGES.RUN and v.enabled~=read(v,run) or false
    v.status=(not v.mod.can_load or v.unavailable or v.zero_weight) and w.unavailable or v.required and w.required or
        not v.control and w.readonly or v.blocked and w.waiting or v.enabled and w.on or w.off
    v.note=v.pending and w.next or ''
    local ink=v.enabled and G.C.WHITE or G.C.UI.TEXT_INACTIVE
    for i=1,4 do v.ink[i]=ink[i] end
    local fill=v.enabled and {0.19,0.23,0.25,1} or {0.07,0.09,0.10,1}
    for i=1,4 do v.fill[i]=fill[i] end
    local mark=v.enabled and v.colour or G.C.UI.TEXT_INACTIVE
    for i=1,4 do v.mark[i]=mark[i] end
    -- Family accents stay quieter than the artwork; OFF also dims the frame.
    local edge=mix_colours(mark,fill,v.enabled and (v.child and 0.38 or 0.62) or 0.18)
    for i=1,4 do v.edge[i]=edge[i] end
end
local function colour(v)
    -- Keep the family colours consistent with the visual mod selection.
    if v.family_id=='doubles' then return HEX('8198C0') end
    if v.id=='risk_jokers' then return G.C.RED end
    if v.id=='joker_fusion' then return G.C.GOLD end
    if v.id=='upgraded_jokers' then return G.C.PURPLE end
    if v.id=='deck_mutations' then return HEX('A5BDB9') end
    if v.id=='portrait_events' then return G.C.SET.Contraband or HEX('65233d') end
    return v.mod.badge_colour or G.C.GREY
end
local function art(v,size)
    size=size or 1.65
    local p=PortraitGameplay and PortraitGameplay.modules
    local center=v.center
    if not v.child then
        local keys={incremental_joker='j_incj_compound_interest',upgraded_jokers='j_upg_metamorphosis',
            risk_jokers='j_risk_russian_joker',joker_fusion='j_fuse_glitch'}
        center=v.family_id and v.center or keys[v.id] and G.P_CENTERS[keys[v.id]]
    end
    local node
    if v.id=='portrait_horizons' and PortraitHorizons then return PortraitHorizons.icon(v.child and v.key or 'PX01',size,true) end
    if center and G.ASSET_ATLAS[center.atlas or 'Joker'] then
        node=PortraitRunGallery.sprite(center.atlas or 'Joker',center.pos,size*71/95,size)
    elseif v.id=='contracts' and p and p.contracts then
        node=p.contracts.icon(v.child and v.key or p.contracts.order[1],size)
    elseif v.id=='deck_mutations' and p and p.deck_mutations then
        node=p.deck_mutations.icon(v.child and v.key or p.deck_mutations.definitions[1].id,size)
    elseif v.id=='portrait_events' and G.ASSET_ATLAS.evt_dealer then
        node=PortraitRunGallery.sprite('evt_dealer',nil,size*80/72,size)
    end
    if not node then return row(v.family,0.25,size*1.1,v.ink) end
    local sprite=node.config.object;local draw=sprite.draw
    local dim={0.32,0.32,0.32,1}
    function sprite:draw() draw(self,v.enabled and G.C.WHITE or dim) end
    return node
end
local function tile(v,width)
    -- Collection-like slots: artwork carries identity, hold reveals the full label.
    -- Keep a minimum touch target even on narrow portrait displays.
    local size=math.min(1.55,(width-0.2)/1.12)
    return {n=G.UIT.C,config={align='cm',padding=0.05,minw=width,maxw=width,minh=portrait_touch_height(1.95),
        r=0.08,colour=v.fill,outline=1,outline_colour=v.edge,emboss=0.015,hover=true,
        button='pms_toggle',ref_table=v,pg_run_action=true,pg_hold_action='pms_details'},nodes={
        {n=G.UIT.R,config={align='cm',minh=1.65},nodes={art(v,size)}},
    }}
end
local function heading(v,width)
    return {n=G.UIT.R,config={align='cm',padding=0.08,minw=width-0.18,maxw=width-0.18,
        minh=portrait_touch_height(1.15),r=0.08,colour=v.fill,outline=1,outline_colour=v.edge,hover=true,
        button='pms_toggle',ref_table=v,pg_run_action=true,pg_hold_action='pms_details'},nodes={
        {n=G.UIT.C,config={align='cm',minw=1.15},nodes={art(v,0.85)}},
        {n=G.UIT.C,config={align='cl',minw=width-1.7,maxw=width-1.7},nodes={
            row(v.definition.name,0.36,width-1.8,v.ink,nil,nil,'cl'),
            row(v.summary,0.25,width-1.8,v.mark,v,'summary','cl')}},
    }}
end
local function update()
    local active,total=0,0
    for _,v in ipairs(M.entries) do
        refresh(v)
        if v.control and not v.unavailable and not v.zero_weight then total=total+1;if v.enabled then active=active+1 end end
    end
    for _,group in ipairs(M.groups) do
        local parent=group.items[1];local count,total,pending=0,0,parent.pending
        for _,v in ipairs(group.items) do
            if v.child then total=total+1;if v.enabled then count=count+1 end end
            pending=pending or v.pending
        end
        parent.summary=parent.status..(total>0 and ' · '..count..' / '..total or '')
        if pending then parent.note=words().next;parent.summary=parent.summary..' · '..words().next end
    end
    M.count=active..' / '..total..words().selected
end
local function apply(v,target)
    if chosen(v)==target then return end
    local c=v.control
    if v.field then
        local config=v.mod.config
        config[v.field]=config[v.field] or {}
        if v.weight then
            config.portrait_disabled_weights=config.portrait_disabled_weights or {}
            local remembered=config.portrait_disabled_weights
            if target then config[v.field][v.key]=remembered[v.key] or v.default_weight
            else remembered[v.key]=config[v.field][v.key];config[v.field][v.key]=0 end
        else config[v.field][v.key]=target end
    elseif c.kind=='toggle' then
        G.FUNCS.toggle_button{config={ref_table=c.args,toggle_callback=c.callback}}
    else
        local index=target and 1 or 2
        G.FUNCS[c.args.opt_callback]{to_key=index,to_val=c.args.options[index],cycle_config=c.args}
    end
end
local function restore(to,from)
    for key in pairs(to) do if from[key]==nil then to[key]=nil end end
    for key,value in pairs(from) do
        if type(value)=='table' then
            if type(to[key])~='table' then to[key]={} end
            restore(to[key],value)
        else to[key]=value end
    end
end
local function change(changes)
    -- Run original setters. Check the actual native config file, since the upstream
    -- writer does not propagate NFS.write failures. Roll back only this mod's switches.
    local groups,ordered={},{}
    for _,c in ipairs(changes) do
        if c.v.control and not c.v.unavailable and not c.v.zero_weight and c.v.mod.can_load and not c.v.mod.disabled then
            if not groups[c.v.id] then groups[c.v.id]={};ordered[#ordered+1]=c.v.id end
            groups[c.v.id][#groups[c.v.id]+1]=c
        end
    end
    local failed=false
    for _,id in ipairs(ordered) do
        local list=groups[id];local mod=list[1].v.mod;local previous=copy_table(mod.config);local dirty=false
        for _,c in ipairs(list) do if chosen(c.v)~=c.target then dirty=true end end
        if dirty then
            local ok=pcall(function()
                for _,c in ipairs(list) do apply(c.v,c.target) end
                SMODS.save_mod_config(mod)
                local expected='return '..serialize(mod.config)
                assert(NFS.read(('config/%s.jkr'):format(id))==expected,'Preferences were not saved')
            end)
            if not ok then
                failed=true
                restore(mod.config,previous)
                SMODS.save_mod_config(mod)
            end
        end
    end
    M.message=failed and (#ordered>1 and words().partial or words().failed) or words().saved
    update()
    if PortraitQOL then PortraitQOL.haptic(failed and 'deselect' or 'select') end
end
function M.details(v)
    local w=words();local width=math.min(6.9,G.ROOM.T.w-1.2);local nodes={}
    local classes={doubles=(G.SETTINGS.language or ''):sub(1,2)=='es' and 'Joker doble' or 'Double Joker',incremental_joker='Joker',upgraded_jokers='Upgraded Joker',risk_jokers='Risk Joker',
        joker_fusion='Fusion Joker',contracts='Contract',deck_mutations='Mutation',portrait_events='Contraband'}
    local function lines(str,scale,ink)
        for _,line in ipairs(PortraitRunGallery.wrap({str},32)) do nodes[#nodes+1]=row(line,scale,width-0.6,ink) end
    end
    local description=v.id=='portrait_gameplay' and w.core or v.id=='Steamodded' and w.loader
        or table.concat(v.definition.short or {},' ')
    if v.child and v.center and (v.center.upg_id or v.center.portrait_family=='doubles' or v.center.set=='Contraband') then
        nodes[#nodes+1]=require('portrait_tooltips').preview(v.center)
    elseif v.child and v.id=='contracts' then
        nodes[#nodes+1]=require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(PortraitGameplay.modules.contracts.info({id=v.key},v.mod.config)))
    elseif v.child and v.id=='portrait_horizons' then
        nodes[#nodes+1]=require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(PortraitHorizons.info(v.key)))
    elseif v.child and (v.id=='deck_mutations' or v.id=='portrait_events') then
        nodes[#nodes+1]=require('portrait_tooltips').embedded(PortraitRunGallery.tooltip{
            title=v.definition.name,text=v.definition.short,secondary=v.definition.secondary,loc=v.definition.loc,
            class=classes[v.id],width=width-0.6})
    else
        lines(v.definition.name,0.44,v.colour)
        lines(w.class..(v.child and classes[v.family_id or v.id] or w.system),0.28,G.C.UI.TEXT_LIGHT)
        nodes[#nodes+1]={n=G.UIT.R,config={minh=0.12,padding=0},nodes={}}
        lines(description,0.35)
    end
    nodes[#nodes+1]={n=G.UIT.R,config={minh=0.16,padding=0},nodes={}}
    nodes[#nodes+1]=UIBox_button{label={w.close},button='pc_category_info_close',minw=3,
        minh=portrait_touch_height(0.85),scale=0.38,colour=G.C.RED}
    require('portrait_collection_info').show(nodes,width)
end
local function content(group)
    local p=PortraitGameplay and PortraitGameplay.modules
    local module=p and p[group.id]
    local market=PortraitEvents and PortraitEvents.black_market
    local kind=group.id
    if not group.items[1].control then return end
    if kind=='portrait_horizons' and PortraitHorizons then
        local ids={};for id in pairs(PortraitHorizons.meta) do ids[#ids+1]=id end;table.sort(ids)
        for _,id in ipairs(ids) do
            local info=PortraitHorizons.info(id)
            group.items[#group.items+1]={id=kind,key=id,mod=group.mod,spec=group.spec,child=true,
                control={kind='preference'},field='items',definition={name=info.title,short=info.text}}
        end
        return
    end
    if kind~='joker_fusion' and kind~='contracts' and kind~='deck_mutations' and kind~='portrait_events' then return end
    local defaults=assert(SMODS.load_file(group.mod.config_file or 'config.lua',kind))()
    local ids={}
    if kind=='deck_mutations' then for _,d in ipairs(module.definitions) do ids[#ids+1]=d.id end
    elseif kind=='portrait_events' then ids=market.contraband.order
    else ids=module.order end
    for _,id in ipairs(ids) do
        local v={id=kind,key=id,mod=group.mod,spec=group.spec,child=true,control={kind='preference'}}
        local data
        if kind=='joker_fusion' then
            v.field='recipes';v.center=G.P_CENTERS['j_fuse_'..id]
            local c=group.mod.config
            local vars=id=='midas' and {c.midas_xmult,c.midas_money_per_step,c.midas_money_step,c.midas_max_reward} or
                id=='banana_cannon' and {c.banana_xmult,c.banana_odds,c.banana_first_hand_odds} or
                {c.last_meal_initial,c.last_meal_decay,c.last_meal_min,c.last_meal_restore,c.last_meal_max}
            data={title=localize{type='name_text',set='Joker',key=v.center.key},
                text=localize{type='raw_descriptions',set='Joker',key=v.center.key,vars=vars}}
            v.ingredients={}
            for _,key in ipairs(module.entries[id].components) do
                v.ingredients[#v.ingredients+1]=localize{type='name_text',set='Joker',key=key}
            end
        elseif kind=='contracts' then
            v.field='contracts';data=module.info({id=id})
        elseif kind=='deck_mutations' then
            v.field='mutation_weights';v.weight=true;v.default_weight=defaults.mutation_weights[id]
            data=module.visual_info(id,1);data.title=localize('k_dm_'..id)
        else
            v.field='contraband_weights';v.weight=true;v.default_weight=defaults.contraband_weights[id]
            v.center=G.P_CENTERS['cb_evt_'..id]
            data={title=localize{type='name_text',set='Contraband',key=v.center.key},
                text=localize{type='raw_descriptions',set='Contraband',key=v.center.key,
                    vars={(group.mod.config.loaded_dice_probability_multiplier-1)*100,v.center.cost}}}
        end
        v.definition={name=data.title,short=data.text,secondary=data.secondary,loc=data.loc}
        group.items[#group.items+1]=v
    end
end
local function grid(width,height)
    local nodes={};local w=words()
    local columns=math.max(2,math.min(5,math.floor((width-0.42)/(portrait_touch_height(1.6)+0.16))))
    local cell=(width-0.42)/columns-0.16
    for _,group in ipairs(M.groups) do
        local visible={}
        for _,v in ipairs(group.items) do if v.child then visible[#visible+1]=v end end
        if #nodes>0 then nodes[#nodes+1]={n=G.UIT.R,config={minh=0.30,padding=0},nodes={}} end
        nodes[#nodes+1]=heading(group.items[1],width-0.2)
        if #visible>0 then nodes[#nodes+1]={n=G.UIT.R,config={minh=0.08,padding=0},nodes={}} end
        for first=1,#visible,columns do
            local cells={}
            for i=first,math.min(first+columns-1,#visible) do cells[#cells+1]=tile(visible[i],cell) end
            -- Complete the last row so every section uses the same columns.
            while #cells<columns do cells[#cells+1]={n=G.UIT.C,config={minw=cell,minh=portrait_touch_height(1.95)},nodes={}} end
            nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.08},nodes=cells}
        end
    end
    if #nodes==0 then nodes[1]=row(w.empty,0.35,width-0.3) end
    local Scroll=require('portrait_run_scroll')
    local view=Scroll(nodes,width,height)
    view.accept_input=function() return G.OVERLAY_MENU and G.OVERLAY_MENU.pms_screen end
    -- Skip offscreen row drawing; sprites are lightweight previews, never Card instances.
    for _,node in ipairs(view.content.UIRoot.children) do
        for _,method in ipairs({'draw_self','draw_children'}) do
            local draw=node[method]
            node[method]=function(self,...)
                if self.VT.y+self.VT.h>=view.VT.y and self.VT.y<=view.VT.y+view.VT.h then return draw(self,...) end
            end
        end
    end
    return view
end
function M.open()
    local w=words()
    M.message=w.applies
    M.groups=require('portrait_mod_info').selection_entries();M.entries={}
    local rank={};for i,id in ipairs(order) do rank[id]=i end
    table.sort(M.groups,function(a,b)
        local ra,rb=rank[a.id] or 99,rank[b.id] or 99
        return ra==rb and a.id<b.id or ra<rb
    end)
    for _,group in ipairs(M.groups) do
        content(group)
        local parent
        for _,v in ipairs(group.items) do if not v.child then parent=v;break end end
        for _,v in ipairs(group.items) do
            v.parent=v.child and parent or nil
            v.unavailable=v.child and (v.id=='risk_jokers' or v.id=='upgraded_jokers') and not v.center
            v.required=v.id=='portrait_gameplay' or v.id=='Steamodded'
            v.family=v.family_id=='doubles' and ((G.SETTINGS.language or ''):sub(1,2)=='es' and 'DOBLES' or 'DOUBLES') or families[v.id] or v.mod.display_name or v.mod.name
            v.colour=colour(v);v.ink={};v.fill={};v.mark={};v.edge={}
            M.entries[#M.entries+1]=v
        end
    end
    update()
    local width=math.min(10.2,G.ROOM.T.w-1.4)
    local height=math.max(2.8,math.min(16.5,G.ROOM.T.h-6.8))
    local view=grid(width,height)
    local nodes={row(w.title,0.50,width),row(w.for_next,0.25,width,G.C.UI.TEXT_LIGHT),
        {n=G.UIT.R,config={minh=0.10,padding=0},nodes={}},
        {n=G.UIT.R,config={align='cm',padding=0.08},nodes={
            UIBox_button{label={w.enable},button='pms_all_on',col=true,minw=(width-0.5)/2,
                minh=portrait_touch_height(0.9),scale=0.34,colour=mix_colours(G.C.GREEN,G.C.L_BLACK,0.65)},
            UIBox_button{label={w.disable},button='pms_all_off',col=true,minw=(width-0.5)/2,
                minh=portrait_touch_height(0.9),scale=0.34,colour=G.C.GREY}}},
        {n=G.UIT.R,config={minh=0.14,padding=0},nodes={}},
        {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={object=view}}}},
        row(M.message,0.24,width,G.C.UI.TEXT_LIGHT,M,'message'),
    }
    G.SETTINGS.paused=true
    SMODS.LAST_SELECTED_MOD_TAB=nil
    SMODS.IN_MODS_TAB=true
    local definition=create_UIBox_generic_options{back_func='exit_mods',back_colour=G.C.GREY,padding=0.06,minw=width,
        contents={{n=G.UIT.C,config={align='cm',padding=0.04},nodes=nodes}}}
    -- Keep the native back action/controller focus, with a compact centred face.
    local panel=definition.nodes[1].nodes[1]
    local back=panel.nodes[2]
    back.n=G.UIT.C
    back.config.minw=3.2
    back.nodes[1].nodes[1].config.scale=0.36
    panel.nodes[2]={n=G.UIT.R,config={align='cm',padding=0.06},nodes={back}}
    G.FUNCS.overlay_menu{definition=definition}
    G.OVERLAY_MENU.pms_screen=true
    -- Measure native fonts/touch controls before choosing the final viewport.
    -- The full-screen dimmer is intentionally huge; measure its visible frame.
    local overlay=G.OVERLAY_MENU;local frame=overlay.UIRoot.children[1]
    local safe_h=G.ROOM.T.h-0.5
    if love.system.getOS()=='iOS' and love.window.getSafeArea then
        local _,_,_,h=love.window.getSafeArea()
        safe_h=math.min(safe_h,h/(G.TILESCALE*G.TILESIZE)-0.5)
    end
    local excess=math.max(0,frame.T.h-safe_h)
    if excess>0 then
        view.T.h=math.max(1.5,view.T.h-excess);view.VT.h=view.T.h
        view.limit=math.max(0,view.content.T.h-view.T.h)
        overlay:recalculate();overlay:align_to_major()
    end
    -- Centre this menu in the actual iPhone safe area, rather than the taller
    -- game room. Child frame coordinates are still local during construction.
    if G.F_PORTRAIT and love.system.getOS()=='iOS' and love.window.getSafeArea then
        local _,y,_,h=love.window.getSafeArea()
        local major=overlay.alignment.major or overlay.role.major
        local unit=G.TILESCALE*G.TILESIZE
        if major and h>0 and unit>0 then
            overlay.alignment.offset.y=(y+h/2)/unit-(G.ROOM.T.y or 0)-(major.T.y+major.T.h/2)
            overlay:align_to_major()
        end
    end
end
function M.install()
    if M.installed then return end;M.installed=true
    G.FUNCS.mods_button=function() M.open() end
    G.FUNCS.pms_details=function(e) M.details(e.config.ref_table) end
    G.FUNCS.pms_toggle=function(e)
        local v=e.config.ref_table
        if not v.control then return end
        refresh(v)
        if v.blocked or v.unavailable or v.zero_weight then return end
        change({{v=v,target=not v.enabled}})
        if not G.SETTINGS.reduced_motion then e:juice_up(0.15,0.08) end
    end
    local function all(target)
        local changes={}
        for _,v in ipairs(M.entries) do if v.control then changes[#changes+1]={v=v,target=target} end end
        change(changes)
    end
    G.FUNCS.pms_all_on=function() all(true) end
    G.FUNCS.pms_all_off=function() all(false) end
end
return M
