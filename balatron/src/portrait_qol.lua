-- Run metadata, scoped records and presentation preferences. No gameplay rolls.
local Q = {stats_scope='vanilla', rarity_colours={UPG='8b358c',RISK='7e233f',FUSION='c79838'}}
PortraitQOL = Q
local fields={'high_scores','career_stats','joker_usage','consumeable_usage','voucher_usage','hand_usage','deck_usage'}
local labels={
    active={'Active Mods','Mods activos'},evolutions={'Evolutions','Evoluciones'},fusions={'Fusions','Fusiones'},
    modded_run={'MODDED RUN','PARTIDA CON MODS'},vanilla_run={'VANILLA RUN','PARTIDA VANILLA'},
    active_count={'gameplay mods active','mods de juego activos'},round={'Round','Ronda'},
    empty={'No evolutions yet','Sin evoluciones'},evolution_count={'UPG Evolutions','Evoluciones UPG'},
    haptics={'Haptics','Vibración'},speed={'Animation Speed','Velocidad de animación'},
    off={'OFF','NO'},low={'LOW','BAJA'},normal={'NORMAL','NORMAL'},fast={'FAST','RÁPIDA'},
    statistics={'Statistics','Estadísticas'},modded={'Modded','Con mods'},
    runs={'Runs','Partidas'},wins={'Wins','Victorias'},losses={'Losses','Derrotas'},
    hand={'Left or Right Hand','Mano principal'},left={'Left Hand','Izquierda'},right={'Right Hand','Derecha'},
    controls={'Controls','Controles'},swipe={'Swipe Only (hide Play/Discard)','Solo gestos (ocultar botones)'},
    classic={'Run Info/Options (Classic Only)','Info/Opciones (solo clásico)'},
}
function Q.label(key)
    local entry=assert(labels[key],key)
    return entry[(G.SETTINGS.language or ''):sub(1,2)=='es' and 2 or 1]
end

-- Legacy FAST preferences must not accelerate native UI, juice or events.
function Q.speed() return 1 end
function Q.duration(seconds) return seconds/Q.speed() end

-- Only explicitly wrapped presentation paths opt in. Logical clocks, update
-- dt, conditions and unmarked mod events retain native timing.
function Q.animation(fn)
    return function(...)
        local depth=Q.presentation_depth or 0;Q.presentation_depth=depth+1
        local result={pcall(fn,...)}
        Q.presentation_depth=depth
        if not result[1] then error(result[2],0) end
        return unpack(result,2)
    end
end
function Q.presentation_event(event,config)
    if config.presentation==false or not ((Q.presentation_depth or 0)>0 or config.presentation) then return end
    if event.trigger=='before' or event.trigger=='after' or event.trigger=='ease' then
        event.delay=Q.duration(event.delay)
    end
    event.func=Q.animation(event.func)
end

function Q.config_snapshot(config, children)
    if not config or config.enabled==false then return end
    if config.recipes then
        local any=false;for _,enabled in pairs(config.recipes) do any=any or enabled==true end
        if not any then return end
    end
    local out={children={}}
    for key,name in pairs(children or {}) do
        if config.jokers and config.jokers[key] then out.children[#out.children+1]=name end
    end
    table.sort(out.children)
    if children and #out.children==0 then return end
    return out
end

function Q.begin_run(loading)
    local game=G.GAME
    require('portrait_score').begin_run(loading)
    if not game.active_mods_snapshot then
        local snapshot={}
        for id,mod in pairs(SMODS and SMODS.Mods or {}) do
            if mod.affects_gameplay and mod.can_load and not mod.disabled then
                local state
                if mod.qol_snapshot then state=mod.qol_snapshot(loading)
                elseif not loading and mod.should_enable~=false then
                    state=Q.config_snapshot(mod.config or {})
                end
                if state then
                    for _,group in ipairs(state.groups or {state}) do
                        snapshot[#snapshot+1]={id=group.id or id,name=group.name or mod.name,children=group.children or {}}
                    end
                end
            end
        end
        table.sort(snapshot,function(a,b) return a.name<b.name end)
        game.active_mods_snapshot=snapshot
    end
    game.run_is_modded=#game.active_mods_snapshot>0
    game.evolution_history=game.evolution_history or {}
    game.fusion_history=game.fusion_history or {}
    Q.haptic_times={}
    Q.scoring_haptic=nil
    Q.init_stats()
    if not loading then
        local stats=Q.stats().career_stats
        stats.c_runs=(stats.c_runs or 0)+1
        G:save_settings()
    end
end

function Q.init_stats()
    local profile=G.PROFILES[G.SETTINGS.profile]
    if not profile.qol_stats then
        local vanilla,modded={},{}
        for _,field in ipairs(fields) do
            vanilla[field]=copy_table(profile[field] or {})
            modded[field]={}
        end
        for key,value in pairs(profile.high_scores) do
            modded.high_scores[key]=copy_table(value);modded.high_scores[key].amt=0
        end
        modded.high_scores.collection=nil
        local runs=0;for _,entry in pairs(vanilla.deck_usage) do runs=runs+(entry.count or 0) end
        vanilla.career_stats.c_runs=math.max(runs,(vanilla.career_stats.c_wins or 0)+(vanilla.career_stats.c_losses or 0))
        profile.qol_stats={vanilla=vanilla,modded=modded}
    end
    -- Legacy career/usage tables remain shared for unlocks and sticker progress.
    -- Legacy records continue to refer exclusively to the Vanilla namespace.
    profile.high_scores=profile.qol_stats.vanilla.high_scores
    return profile.qol_stats
end
function Q.stats(scope)
    scope=scope or (G.GAME and G.GAME.run_is_modded and 'modded' or 'vanilla')
    return Q.init_stats()[scope]
end
function Q.records() return Q.stats().high_scores end
function Q.view_stats() return Q.stats(Q.stats_scope) end
function Q.career(stat, amount)
    local stats=Q.stats().career_stats
    stats[stat]=(stats[stat] or 0)+(amount or 0)
end

local function has_delta(before,after)
    for key,value in pairs(after) do
        if type(value)=='table' then
            if has_delta(before[key] or {},value) then return true end
        elseif key~='order' and type(value)=='number' and value~=(before[key] or 0) then return true end
    end
    return false
end
local function merge_delta(target,before,after)
    for key,value in pairs(after) do
        if type(value)=='table' then
            if has_delta(before[key] or {},value) then
                target[key]=target[key] or {}; merge_delta(target[key],before[key] or {},value)
            end
        elseif key=='order' or type(value)~='number' then target[key]=value
        else target[key]=(target[key] or 0)+value-(before[key] or 0) end
    end
end

function Q.history(kind,entry)
    local game=G.GAME
    local list=game[kind..'_history'] or {};game[kind..'_history']=list
    entry.ante=game.round_resets.ante;entry.round=game.round
    list[#list+1]=entry
end
function Q.evolution(def,card,old,new)
    Q.history('evolution',{name=def.name,
        from=localize{type='name_text',set='Joker',key=def.stages[old].loc_key},
        to=localize{type='name_text',set='Joker',key=def.stages[new].loc_key}})
end

local haptics={
    select={style=0,intensity=0.2,interval=0.07},deselect={style=0,intensity=0.2,interval=0.07},
    buy={style=0,intensity=0.5,low=true,interval=0.15},sell={style=2,intensity=0.3,interval=0.15},
    reroll={style=0,interval=0.2},joker={style=1,interval=2.0},
    evolution={style=1,low=true,interval=0},fusion={style=2,low=true,interval=0},
    boss={style=2,low=true,interval=0.5},
    record={style=0,intensity=0.35,low=true,interval=1},
    overkill={style=0,intensity=0.45,low=true,interval=1},
    overkill_big={style=1,intensity=0.55,low=true,interval=1},
    contract_complete={style=1,intensity=0.6,low=true,interval=0.5},
    contract_failed={style=0,intensity=0.45,low=true,interval=0.5},
}
function Q.haptic(kind)
    local mode=G.SETTINGS.haptics_mode or (G.SETTINGS.haptic_enabled==false and 'OFF' or 'NORMAL')
    local spec=haptics[kind]
    if not spec or mode=='OFF' or (mode=='LOW' and not spec.low) or love.system.getOS()~='iOS' then return end
    if kind=='joker' then
        local token=tostring(G.GAME.round)..':'..tostring(G.GAME.current_round.hands_played)
        if Q.scoring_haptic==token then return end
        Q.scoring_haptic=token
    end
    Q.haptic_times=Q.haptic_times or {}
    local now=love.timer.getTime()
    local key=(kind=='select' or kind=='deselect') and 'selection' or kind
    if now-(Q.haptic_times[key] or -100)<spec.interval then return end
    Q.haptic_times[key]=now
    require('portrait_ios').haptic(mode=='LOW' and math.max(0,spec.style-1) or spec.style,
        mode=='LOW' and 0.4 or spec.intensity or 0.75)
end

function Q.text(text,scale,colour)
    return {n=G.UIT.R,config={align='cm',padding=0.04},nodes={
        {n=G.UIT.O,config={object=DynaText{string={text},scale=scale or 0.32,
            maxw=7,colours={colour or G.C.WHITE},silent=true}}}}}
end
function Q.panel(nodes) return {n=G.UIT.ROOT,config={align='cm',padding=0.08,colour=G.C.CLEAR},nodes=nodes} end
function Q.paged(lines,page,callback)
    local nodes={};local size=10;page=page or 1
    for i=(page-1)*size+1,math.min(page*size,#lines) do nodes[#nodes+1]=Q.text(lines[i]) end
    if #lines>size then
        local options={};for i=1,math.ceil(#lines/size) do options[i]=tostring(i) end
        nodes[#nodes+1]=create_option_cycle{options=options,current_option=page,opt_callback=callback,w=4,scale=0.7}
    end
    return Q.panel(nodes)
end
function Q.active_mods(page)
    local game=G.GAME;local lines={Q.label(game.run_is_modded and 'modded_run' or 'vanilla_run'),
        tostring(#(game.active_mods_snapshot or {}))..' '..Q.label('active_count')}
    for _,mod in ipairs(game.active_mods_snapshot or {}) do
        lines[#lines+1]=mod.name
        for _,name in ipairs(mod.children) do lines[#lines+1]='  '..name end
    end
    return Q.paged(lines,page,'qol_active_page')
end
function Q.history_panel(kind,page)
    local lines={}
    for _,entry in ipairs(G.GAME[kind..'_history'] or {}) do
        lines[#lines+1]=entry.name..'  (Ante '..entry.ante..' / '..Q.label('round')..' '..entry.round..')'
        lines[#lines+1]=entry.from..' > '..entry.to
    end
    if #lines==0 then lines[1]=Q.label('empty') end
    return Q.paged(lines,page,'qol_'..kind..'_page')
end
function Q.summary()
    local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
    return {n=G.UIT.R,config={align='cm',padding=0.025},nodes={
        Q.text(Q.label('evolution_count')..': '..#(G.GAME.evolution_history or {})..'    '..Q.label('fusions')..': '..#(G.GAME.fusion_history or {}),0.3),
        Q.text((es and 'Récord: ' or 'Best hand: ')..number_format(G.GAME.portrait_best_hand or 0)..
            '   OVERKILL +$'..tostring(G.GAME.portrait_overkill and G.GAME.portrait_overkill.dollars or 0),0.3),
    }}
end

function Q.install()
    if Q.installed then return end;Q.installed=true
    require('portrait_run_gallery').install()
    require('portrait_collection').install()
    require('portrait_score').install()
    if SMODS then require('portrait_blind_collection').install() end
    for _,name in ipairs({'delay','draw_card','card_eval_status_text','attention_text','ease_colour','ease_background_colour'}) do
        if _G[name] then _G[name]=Q.animation(_G[name]) end
    end
    for _,name in ipairs({'start_materialize','start_dissolve','explode','open','use_consumeable'}) do
        if Card[name] then Card[name]=Q.animation(Card[name]) end
    end
    for _,name in ipairs({'toggle_shop','reroll_shop','buy_from_shop'}) do
        if G.FUNCS[name] then G.FUNCS[name]=Q.animation(G.FUNCS[name]) end
    end
    if PortraitEvents and PortraitEvents.black_market then
        local market=PortraitEvents.black_market
        for _,name in ipairs({'enter','back','reroll'}) do
            market[name]=Q.animation(market[name]);G.FUNCS['evt_bm_'..name]=market[name]
        end
    end
    -- Mirror only statistic deltas; execute native gameplay/unlock callbacks once.
    for _,field in ipairs({'joker','deck','consumeable','voucher','hand'}) do
        local storage=field..'_usage'
        for _,suffix in ipairs({'usage','win','loss'}) do
            local name='set_'..field..'_'..suffix
            local original=_G[name]
            if original then _G[name]=function(...)
                local bucket=Q.stats()[storage]
                local profile=G.PROFILES[G.SETTINGS.profile]
                local before=copy_table(profile[storage] or {})
                local result=original(...)
                merge_delta(bucket,before,profile[storage] or {})
                G:save_settings()
                return result
            end end
        end
    end
    G.FUNCS.qol_haptics=function(args)
        G.SETTINGS.haptics_mode=({'OFF','LOW','NORMAL'})[args.to_key]
        G.SETTINGS.haptic_enabled=G.SETTINGS.haptics_mode~='OFF'
        if not G.SETTINGS.haptic_enabled then stop_haptics() end
        G:save_settings()
    end
    G.FUNCS.qol_stats_scope=function(args)
        Q.stats_scope=args.to_key==2 and 'modded' or 'vanilla'
        G.FUNCS.overlay_menu{definition=create_UIBox_high_scores()}
    end
    for _,kind in ipairs({'active','evolution','fusion'}) do
        local key=kind
        G.FUNCS['qol_'..key..'_page']=function(args)
            local host=G.OVERLAY_MENU:get_UIE_by_ID('tab_contents')
            if host then
                host.config.object:remove()
                host.config.object=UIBox{definition=key=='active' and Q.active_mods(args.to_key) or Q.history_panel(key,args.to_key),config={offset={x=0,y=0}}}
                G.OVERLAY_MENU:recalculate()
            end
        end
    end
    -- Wrap after Steamodded has installed its final UI entry points.
    local tabs=create_tabs
    function create_tabs(args)
        if Q.in_run_info and not PortraitRunGallery then
            args.tabs[#args.tabs+1]={label=Q.label('evolutions'),tab_definition_function=function() return Q.history_panel('evolution') end}
            if #(G.GAME.fusion_history or {})>0 then
                args.tabs[#args.tabs+1]={label=Q.label('fusions'),tab_definition_function=function() return Q.history_panel('fusion') end}
            end
        end
        return tabs(args)
    end
    local run_info=G.UIDEF.run_info
    function G.UIDEF.run_info(...)
        Q.in_run_info=true;local result=run_info(...);Q.in_run_info=false;return result
    end
end
return Q
