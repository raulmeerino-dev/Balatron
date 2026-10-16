-- Presentation adapters only: every switch still calls its original callback.
local M={config_pages={},selection_tabs={}}
local modules={
    incremental_joker={key='extra',snapshot='incj_config',children={'compound_interest','tax_collector','hipster','world_record','excessive_force','collector','olympico'}},
    upgraded_jokers={key='upgraded',snapshot='upg_jokers_config',children={'metamorphosis','bottomless'}},
    risk_jokers={key='risk',snapshot='risk_jokers_config',children={'russian_joker','burning_fuse','greed','glass_cannon'}},
    portrait_events={key='black_market',snapshot='portrait_events'},
    contracts={key='contracts',snapshot='contracts_config'},
    deck_mutations={key='deck_mutations',snapshot='deck_mutations_config'},
    joker_fusion={key='joker_fusion',snapshot='joker_fusion_config'},
    portrait_horizons={key='horizons',snapshot='portrait_horizons_config'},
}
local visuals={change_animated_background='animated_background',qol_haptics='haptics'}
local categories={animated_background='VISUAL',haptics='VISUAL / QOL'}
local function strings()
    local lang=(G.SETTINGS.language or ''):sub(1,2)=='es' and 'es_ES' or 'en-us'
    if M.language~=lang or M.localization~=G.localization then
        local data=assert(love.filesystem.load('assets/localization/mod_info/'..lang..'.lua'))()
        for key,value in pairs(data) do G.localization.misc.dictionary[key]=value end
        M.language=lang;M.localization=G.localization
    end
end
local function label(key) strings();return localize('pmi_'..key) end
local function entry(key) return label('defs')[key] end
function M.module_description(id)
    local spec=modules[id]
    return spec and entry(spec.key)
end
local function family_spec(id,key)
    local mod=SMODS.Mods[id]
    local families=mod and mod.portrait_families or {}
    local center=mod and mod.prefix and G.P_CENTERS['j_'..mod.prefix..'_'..key]
    local family=families[key] and key or center and center.portrait_family
    return family and families[family],family
end
local function master(config,spec)
    if not config then return false end
    local enabled=spec and config[spec.enabled_field]
    if enabled==nil then enabled=config.enabled end
    return enabled==true
end
local function control_key(mod,spec,ref)
    for key,family in pairs(mod.portrait_families or {}) do
        if family.enabled_field==ref then return key end
    end
    return ref=='enabled' and spec.key or ref
end
local function value(config,id,key)
    if not config then return false end
    if id=='portrait_events' then return config.events and config.events.black_market==true end
    local spec,family=family_spec(id,key)
    if family==key then return master(config,spec) end
    if key~=modules[id].key then return config.jokers and config.jokers[key]==true end
    return config.enabled==true
end
function M.pending(id,key)
    if not id or not (G.STAGE==G.STAGES.RUN and G.GAME) then return false end
    local spec,mod=modules[id],SMODS.Mods[id]
    local snapshot=G.GAME[spec.snapshot]
    if id=='portrait_events' then snapshot=snapshot and snapshot.config end
    -- Compare existing run data; never refresh or write its snapshot.
    if value(mod.config,id,key)~=value(snapshot,id,key) then return true end
    if key==spec.key then
        for _,child in ipairs(spec.children or {}) do
            if value(mod.config,id,child)~=value(snapshot,id,child) then return true end
        end
    end
    return false
end
local function text(str,scale,width,config)
    local c={text=str,scale=scale or 0.3,colour=G.C.UI.TEXT_LIGHT,shadow=true}
    for k,v in pairs(config or {}) do c[k]=v end
    return {n=G.UIT.R,config={align='cl',padding=0.01,maxw=width},nodes={{n=G.UIT.T,config=c}}}
end
local function width() return math.min(9.5,G.ROOM.T.w-PORTRAIT_CONFIG.mod_list_margin-0.45) end
local function view_state(v)
    local enabled
    if v.control.kind=='toggle' then
        local a=v.control.args;enabled=a.ref_table[a.ref_value]
    else enabled=value(SMODS.Mods[v.id].config,v.id,v.key) end
    v.status=label(enabled and 'on' or 'off')
    v.enabled=enabled
    local spec,family
    if v.id then spec,family=family_spec(v.id,v.key) end
    v.disabled=v.id and v.key~=modules[v.id].key and v.key~=family and not master(SMODS.Mods[v.id].config,spec)
    v.text_colour=v.text_colour or {}
    local colour=v.disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT
    for i=1,4 do v.text_colour[i]=colour[i] end
    v.badge=(categories[v.key] or 'GAMEPLAY')..(M.pending(v.id,v.key) and ' · '..label('next_run') or '')
end
function M.row(id,key,control,back,open)
    local def=entry(key);local w=width()
    local v={id=id,key=key,control=control,back=back or 'mods_button'}
    view_state(v)
    local family
    if id then local spec;spec,family=family_spec(id,key) end
    local child=id and key~=modules[id].key and key~=family
    local title={n=G.UIT.C,config={align='cl',minw=w-3.3,maxw=w-3.3,minh=portrait_touch_height(0.8),
        button=open or 'pmi_details',ref_table=v,hover=true,r=0.1},nodes={text((child and '  ' or '')..def.name,0.44,w-3.3,{colour=v.text_colour})}}
    local nodes={{n=G.UIT.R,config={align='cm',padding=0.025},nodes={title,
        {n=G.UIT.C,config={align='cm',minw=portrait_touch_height(0.8),minh=portrait_touch_height(0.8),
            button='pmi_details',ref_table=v,hover=true,r=0.1,colour=G.C.GREY},nodes={text('i',0.4)}},
        {n=G.UIT.C,config={align='cm',minw=1.65,minh=portrait_touch_height(0.8),r=0.1,
            button='pmi_toggle',func='pmi_switch_state',ref_table=v,hover=true,colour=G.C.RED},nodes={
            text(v.status,0.44,nil,{ref_table=v,ref_value='status',no_recalc=true,colour=v.text_colour}),
        }},
    }}}
    for _,line in ipairs(def.short) do nodes[#nodes+1]=text(line,0.36,w) end
    nodes[#nodes+1]=text(v.badge,0.3,w,{ref_table=v,ref_value='badge',no_recalc=true})
    return {n=G.UIT.R,config={align='cm',padding=0.10,minw=w,maxw=w,r=0.1,colour=G.C.BLACK},nodes={
        {n=G.UIT.C,config={align='cl',padding=0.025},nodes=nodes}}}
end
local function walk(node,fn)
    fn(node)
    for _,child in ipairs(node.nodes or {}) do walk(child,fn) end
end
-- Read the native controls before their presentation adapters paginate them.
-- Settings can show every registered switch, including newly added Jokers.
function M.selection_entries()
    local out={}
    for _,mod in ipairs(SMODS.mod_list) do
        local spec=modules[mod.id]
        local group={id=mod.id,mod=mod,spec=spec,items={}}
        local build=M.selection_tabs[mod.id]
        if spec and mod.can_load and not mod.disabled and build then
            local original=build();local seen={}
            walk(original,function(n)
                local c=n.config or {};local a=c.ref_table
                if not a or seen[a] then return end
                local key,control
                if c.button=='toggle_button' then
                    key=control_key(mod,spec,a.ref_value)
                    control={kind='toggle',args=a,callback=c.toggle_callback}
                elseif c.button=='option_cycle' and a.opt_callback then
                    key=a.opt_callback:match('^upg_toggle_(.+)$') or a.opt_callback:match('^risk_toggle_(.+)$')
                        or a.opt_callback:match('^evt_toggle_(.+)$')
                    if key=='family' then key=spec.key end
                    control={kind='cycle',args=a}
                end
                if key and control then
                    seen[a]=true
                    local center=G.P_CENTERS['j_'..mod.prefix..'_'..key]
                    local d=entry(key) or {name=center and localize{type='name_text',set='Joker',key=center.key} or key,
                        short={mod.description or ''}}
                    group.items[#group.items+1]={id=mod.id,key=key,control=control,definition=d,center=center,
                        mod=mod,spec=spec,child=key~=spec.key}
                end
            end)
            walk(original,function(n) if n.config and n.config.object then n.config.object:remove() end end)
        end
        if #group.items==0 then
            group.items[1]={id=mod.id,key=spec and spec.key or mod.id,mod=mod,spec=spec,
                definition=spec and entry(spec.key) or {name=mod.name,short={mod.description or ''}}}
        end
        local split={}
        for _,v in ipairs(group.items) do
            local spec,family=family_spec(mod.id,v.key)
            if spec then
                if not split[family] then
                    split[family]={id=family,mod=mod,spec={key=family,snapshot=group.spec.snapshot,
                        enabled_field=spec.enabled_field},items={}}
                end
                local target=split[family]
                v.spec=target.spec;v.family_id=family;v.child=v.key~=family
                if not v.child then v.center=G.P_CENTERS[spec.representative] end
                target.items[#target.items+1]=v
            end
        end
        for i=#group.items,1,-1 do if group.items[i].family_id then table.remove(group.items,i) end end
        out[#out+1]=group
        for _,family in pairs(split) do
            table.sort(family.items,function(a,b) if a.child~=b.child then return not a.child end;return a.key<b.key end)
            out[#out+1]=family
        end
    end
    return out
end
function M.decorate_entry(node)
    local id,control
    walk(node,function(n)
        local c=n.config or {}
        if c.button and c.button:find('^openModUI_') then id=c.button:sub(11) end
        if c.button=='toggle_button' then control={kind='toggle',args=c.ref_table,callback=c.toggle_callback} end
    end)
    local required=id=='portrait_gameplay'
    if not (SMODS.Mods[id] and SMODS.Mods[id].can_load and (required or modules[id] and control)) then return node end
    -- The discarded native box owns sprites/text; release them, not controls or config.
    walk(node,function(n) if n.config and n.config.object then n.config.object:remove() end end)
    if required then
        -- The shared dependency has no toggle. Its upstream desktop box was
        -- wider than the adjacent Fusion row and stretched the whole page.
        local w=width();local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
        return {n=G.UIT.R,config={align='cm',padding=0.10,minw=w,maxw=w,r=0.1,colour=G.C.BLACK},nodes={
            {n=G.UIT.C,config={align='cl',padding=0.025},nodes={
                {n=G.UIT.R,config={align='cl',minw=w-0.2,minh=portrait_touch_height(0.8),
                    button='openModUI_'..id,hover=true,r=0.1},nodes={text(SMODS.Mods[id].name,0.44,w-0.2)}},
                text(es and 'Base compartida de los mods de esta partida.' or 'Shared support for this run\'s gameplay mods.',0.36,w-0.2),
                text(localize('k_pg_required'),0.3,w-0.2,{colour=G.C.GOLD}),
            }},
        }}
    end
    return M.row(id,modules[id].key,control,'mods_button','openModUI_'..id)
end
local function config_panel(id,original)
    local rows,seen={},{}
    walk(original,function(n)
        local c=n.config or {};local a=c.ref_table
        if not a or seen[a] then return end
        local control,key
        if c.button=='toggle_button' then
            key=control_key(SMODS.Mods[id],modules[id],a.ref_value)
            control={kind='toggle',args=a,callback=c.toggle_callback}
        elseif c.button=='option_cycle' and a.opt_callback then
            key=a.opt_callback:match('^upg_toggle_(.+)$') or a.opt_callback:match('^risk_toggle_(.+)$') or a.opt_callback:match('^evt_toggle_(.+)$')
            if key=='family' then key=modules[id].key end
            control={kind='cycle',args=a}
        end
        if key and entry(key) then
            seen[a]=true
            rows[#rows+1]=M.row(id,key,control,'openModUI_'..id)
        end
    end)
    if #rows==0 then return original end
    walk(original,function(n) if n.config and n.config.object then n.config.object:remove() end end)
    if G.F_PORTRAIT and #rows>5 then
        -- Keep the master switch visible and reuse the native cycle control.
        -- Three children per page also leave room for Back on small iPhones.
        local pages=math.ceil((#rows-1)/3)
        local page=math.min(pages,M.config_pages[id] or 1)
        local shown,options={rows[1]},{}
        for i=2+(page-1)*3,math.min(#rows,1+page*3) do shown[#shown+1]=rows[i] end
        for i=1,pages do options[i]=i..' / '..pages end
        shown[#shown+1]=create_option_cycle{options=options,current_option=page,
            opt_callback='pmi_config_page',mod_id=id,w=width()-2,h=portrait_touch_height(0.8)}
        rows=shown
    end
    return {n=G.UIT.ROOT,config={align='cm',padding=0.07,colour=G.C.CLEAR},nodes=rows}
end
-- Use the existing pager for vertical swipes/wheel; no clipped or off-screen
-- controls. Defer taps until release so scrolling never toggles a mod.
function M.scroll_page(direction)
    local overlay=G.OVERLAY_MENU
    if not overlay or not overlay:get_UIE_by_ID('modsList') then return end
    local function visit(node)
        local c=node.config or {};local a=c.ref_table
        if c.button=='option_cycle' and type(a)=='table' and a.opt_callback=='update_mod_list'
            and c.ref_value==(direction>0 and 'r' or 'l') then
            if a.current_option+direction>=1 and a.current_option+direction<=#a.options then G.FUNCS.option_cycle(node) end
            return true
        end
        for _,child in pairs(node.children or {}) do if visit(child) then return true end end
        if c.object and c.object.UIRoot and visit(c.object.UIRoot) then return true end
    end
    visit(overlay.UIRoot)
end
local function over_list(x,y)
    if not G.F_PORTRAIT or not G.OVERLAY_MENU then return end
    local host=G.OVERLAY_MENU:get_UIE_by_ID('modsList')
    local box=host and host.config.object
    if not box or not box.VT then return end
    local t,unit=box.VT,G.TILESCALE*G.TILESIZE
    local px,py=x/unit-G.ROOM.T.x,y/unit-G.ROOM.T.y
    return px>=t.x and px<=t.x+t.w and py>=t.y and py<=t.y+t.h
end
local function scrolling()
    local pressed,moved,released,update,wheel=love.mousepressed,love.mousemoved,love.mousereleased,love.update,love.wheelmoved
    local gesture,pending
    love.mousepressed=function(x,y,button,touch,...)
        if button==1 and over_list(x,y) then gesture={x=x,y=y,touch=touch,overlay=G.OVERLAY_MENU};return end
        return pressed(x,y,button,touch,...)
    end
    love.mousemoved=function(x,y,dx,dy,touch,...)
        if gesture then return end
        return moved(x,y,dx,dy,touch,...)
    end
    love.mousereleased=function(x,y,button,touch,...)
        if gesture and button==1 then
            local g=gesture;gesture=nil
            if G.OVERLAY_MENU~=g.overlay then return end
            if math.abs(y-g.y)>28 and math.abs(y-g.y)>math.abs(x-g.x) then
                M.scroll_page(y<g.y and 1 or -1)
            elseif math.abs(x-g.x)<28 and math.abs(y-g.y)<28 then
                pressed(g.x,g.y,button,g.touch)
                pending={x=x,y=y,button=button,touch=touch,overlay=g.overlay}
            end
            return
        end
        return released(x,y,button,touch,...)
    end
    love.update=function(dt,...)
        update(dt,...)
        if gesture and (gesture.overlay~=G.OVERLAY_MENU or gesture.overlay.REMOVED) then gesture=nil end
        if pending then
            local p=pending;pending=nil
            if p.overlay==G.OVERLAY_MENU and not p.overlay.REMOVED then released(p.x,p.y,p.button,p.touch) end
        end
    end
    love.wheelmoved=function(x,y,...)
        local mx,my=love.mouse.getPosition()
        if y~=0 and over_list(mx,my) then M.scroll_page(y<0 and 1 or -1);return end
        if wheel then return wheel(x,y,...) end
    end
end
function M.install()
    if M.installed then return end;M.installed=true
    G.FUNCS.pmi_config_page=function(args)
        local id=args.cycle_config.mod_id
        M.config_pages[id]=args.to_key
        SMODS.LAST_SELECTED_MOD_TAB='config'
        G.FUNCS['openModUI_'..id]()
    end
    -- Fusion's desktop description had one long text node and a 50-character
    -- wrap. Build this tab from the existing localized copy at phone width.
    local description_tab=buildModDescTab
    function buildModDescTab(mod)
        local tab=description_tab(mod)
        if not G.F_PORTRAIT or mod.id~='joker_fusion' then return tab end
        tab.tab_definition_function=function()
            SMODS.LAST_SELECTED_MOD_TAB='mod_desc'
            local d=M.module_description(mod.id)
            local nodes={text(d.name,0.46,width()),text(table.concat(mod.author,', '),0.34,width())}
            for _,line in ipairs(d.short) do
                for _,part in ipairs(PortraitRunGallery.wrap({line},42)) do nodes[#nodes+1]=text(part,0.35,width()) end
            end
            for _,line in ipairs(d.detail or {}) do
                for _,part in ipairs(PortraitRunGallery.wrap({line},42)) do nodes[#nodes+1]=text(part,0.32,width()) end
            end
            return {n=G.UIT.ROOT,config={align='cm',minw=width(),maxw=width(),padding=0.12,colour=G.C.CLEAR},nodes=nodes}
        end
        return tab
    end
    G.FUNCS.pmi_switch_state=function(e)
        local v=e.config.ref_table
        view_state(v)
        e.config.button=not v.disabled and 'pmi_toggle' or nil
        e.config.colour=not v.disabled and v.enabled and G.C.GREEN or G.C.GREY
    end
    G.FUNCS.pmi_toggle=function(e)
        local v=e.config.ref_table;local c=v.control
        view_state(v)
        if v.disabled then return end
        if c.kind=='toggle' then
            G.FUNCS.toggle_button{config={ref_table=c.args,toggle_callback=c.callback}}
        else
            local next_key=value(SMODS.Mods[v.id].config,v.id,v.key) and 2 or 1
            G.FUNCS[c.args.opt_callback]({to_key=next_key,to_val=c.args.options[next_key],cycle_config=c.args})
        end
        view_state(v)
    end
    G.FUNCS.pmi_back=function()
        local back=M.back or 'mods_button'
        if back:find('^openModUI_') then SMODS.LAST_SELECTED_MOD_TAB='config' end
        G.FUNCS[back]()
    end
    G.FUNCS.pmi_details=function(e)
        local v=e.config.ref_table;local d=entry(v.key);M.back=v.back
        local nodes={text(d.name,0.46,8)}
        for _,line in ipairs(d.short) do nodes[#nodes+1]=text(line,0.34,8) end
        for _,line in ipairs(d.detail or {}) do nodes[#nodes+1]=text(line,0.32,8) end
        nodes[#nodes+1]=text(categories[v.key] or 'GAMEPLAY',0.26,8)
        if categories[v.key] then nodes[#nodes+1]=text(label('unmodded'),0.3,8)
        elseif M.pending(v.id,v.key) then nodes[#nodes+1]=text(label('next_run'),0.3,8) end
        G.SETTINGS.paused=true
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='pmi_back',contents={
            {n=G.UIT.R,config={align='cm',padding=0.08},nodes=nodes},
        }}}
    end
    for id in pairs(modules) do
        local mod=SMODS.Mods[id]
        if mod and mod.config_tab then
            local key,original=id,mod.config_tab
            M.selection_tabs[id]=original
            mod.config_tab=function(...) return config_panel(key,original(...)) end
        end
    end
    local cycle=create_option_cycle
    function create_option_cycle(args)
        local key=visuals[args and args.opt_callback]
        if not key then return cycle(args) end
        local d=entry(key);args.label=d.name
        local control=cycle(args)
        local nodes={control}
        for _,line in ipairs(d.short) do nodes[#nodes+1]=text(line,0.34,8) end
        nodes[#nodes+1]=text(categories[key]..' · '..label('unmodded'),0.28,8)
        return {n=G.UIT.R,config={align='cm',padding=0.02},nodes=nodes}
    end
    scrolling()
end
return M
