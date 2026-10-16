local P={modules={},order={}}
PortraitGameplay=P
local core_mod=SMODS.current_mod
local core_toggle=create_toggle
function create_toggle(args)
    if args and args.ref_table==core_mod and args.ref_value=='should_enable' then
        return {n=G.UIT.R,config={align='cm'},nodes={
            {n=G.UIT.T,config={text=localize('k_pg_required'),scale=0.28,colour=G.C.UI.TEXT_LIGHT}}}}
    end
    return core_toggle(args)
end
function P.register(mod)
    mod.affects_gameplay=true
    mod.qol_snapshot=function() return PortraitQOL.config_snapshot(G.GAME[mod.id..'_config']) end
    local m={mod=mod,id=mod.id}
    P.modules[mod.id]=m; P.order[#P.order+1]=mod.id
    function m.config() return G.GAME and G.GAME[m.id..'_config'] or mod.config end
    function m.state() return G.GAME and G.GAME[m.id] end
    function m.enabled() return m.config().enabled==true end
    mod.config_tab=function()
        return {n=G.UIT.ROOT,config={align='cm',padding=0.15,colour=G.C.CLEAR},nodes={
            create_toggle{label=mod.name,ref_table=mod.config,ref_value='enabled',callback=function() SMODS.save_mod_config(mod) end},
            P.text(localize('k_pg_next_run'),0.28),
        }}
    end
    local toggle=create_toggle
    function create_toggle(args)
        if args and args.ref_table==mod and args.ref_value=='should_enable' then
            args.ref_table=mod.config;args.ref_value='enabled'
            args.callback=function() SMODS.save_mod_config(mod) end
        end
        return toggle(args)
    end
    return m
end
function P.begin_run(loading)
    P.offer_queued=false; P.fusion_selection=nil
    for _,id in ipairs(P.order) do
        local m=P.modules[id]
        if not loading or not G.GAME[id..'_config'] then
            G.GAME[id..'_config']=copy_table(m.mod.config)
            if loading then G.GAME[id..'_config'].enabled=false end
        end
        G.GAME[id]=G.GAME[id] or {}
    end
end
function P.token()
    local g=G.GAME
    return tostring(g.round)..':'..tostring(g.round_resets.ante)..':'..tostring(g.blind.config.blind.key)
end
function P.real(c)
    return not c.blueprint and not c.retrigger_joker and not c.repetition and not c.individual
end
function P.won(c)
    local g=G.GAME
    return P.real(c) and c.end_of_round and c.main_eval and not c.game_over and
        g.facing_blind and g.blind and g.blind.chips>0 and g.chips>=g.blind.chips
end
function P.once(s,key,token)
    if s[key]==token then return false end
    s[key]=token;return true
end
function P.roll(key) return pseudorandom(pseudoseed('pg_'..key)) end
function P.choose(entries,weight,key)
    local total=0
    for _,id in ipairs(entries) do total=total+math.max(0,weight(id) or 0) end
    if total<=0 then return end
    local r=P.roll(key)*total
    for _,id in ipairs(entries) do r=r-math.max(0,weight(id) or 0);if r<0 then return id end end
end
function P.pool(set,rarity)
    local pool=get_current_pool(set,rarity,false,'pg_reward')
    local native_rarities={Common=1,Uncommon=2,Rare=3,Legendary=4}
    local expected=native_rarities[rarity] or rarity
    local out={}
    for _,key in ipairs(pool) do
        local c=G.P_CENTERS[key]
        if c and c.set==set and (set~='Joker' or not rarity or
            (native_rarities[c.rarity] or c.rarity)==expected) and
            c.unlocked~=false and not G.GAME.banned_keys[key] and
            SMODS.add_to_pool(c,{source='pg_reward'}) then out[#out+1]=key end
    end
    return out
end
function P.reward_card(set,rarity,key)
    local area=set=='Joker' and G.jokers or G.consumeables
    local buffer=set=='Joker' and (G.GAME.joker_buffer or 0) or (G.GAME.consumeable_buffer or 0)
    local full=#area.cards+buffer>=area.config.card_limit
    if full and not (set=='Joker' and P.defer_fusion_reward and PortraitFusion.enabled()) then return false end
    local pool=P.pool(set,rarity)
    if #pool==0 then return false end
    local chosen
    if set=='Joker' and RiskJokers and RiskJokers.registry.is_risk_pool(pool) then
        chosen=RiskJokers.registry.choose(pool,P.roll(key))
    elseif set=='Joker' and UPGJokers and UPGJokers.registry.is_upg_pool(pool) then
        chosen=UPGJokers.registry.choose(pool,P.roll(key))
    else chosen=P.choose(pool,function() return 1 end,key) end
    if not chosen then return false end
    local card=SMODS.create_card{set=set,key=chosen,area=area,key_append=key}
    if full then
        local deferred=P.defer_fusion_reward(card)
        card:remove()
        return deferred,card
    end
    card:add_to_deck();area:emplace(card);card:start_materialize()
    return true,card
end
function P.feedback(key,colour)
    attention_text{text=localize(key),scale=0.55,hold=1,colour=colour or G.C.GOLD,
        major=G.jokers,align='cm',offset={x=0,y=0}}
end
assert(SMODS.load_file('ui.lua'))()(P)
assert(SMODS.load_file('roulette.lua'))()(P)
local expansion=require('portrait_expansion48')
require('expansion48.hooks')(expansion)
require('expansion48.missions')(expansion)
core_mod.calculate=function(_,context)
    require('portrait_joker_missions').track(context)
    expansion.track(context)
    if context.first_hand_drawn then expansion.track{exp48_initial_hand=true} end
end
