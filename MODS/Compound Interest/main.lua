local mod = SMODS.current_mod
local settings = assert(SMODS.load_file('settings.lua'))()
local logic = assert(SMODS.load_file('logic.lua'))()
IncJoker = {config=settings, logic=logic, key='j_incj_compound_interest'}
local I=IncJoker
I.order={'compound_interest','tax_collector','hipster','world_record','excessive_force','collector','olympico','options','color_call','double_entry','sniper','second_course','graft','intermission'}
-- Families share the loader package, but own independent generation switches.
-- Keep center keys and run snapshots stable across the category migration.
mod.portrait_families={doubles={enabled_field='doubles_enabled',representative='j_incj_options'}}
if mod.config.doubles_enabled==nil then mod.config.doubles_enabled=mod.config.enabled~=false end
function I.family(key)
    local center=G.P_CENTERS and G.P_CENTERS['j_incj_'..key]
    return center and center.portrait_family
end
function I.family_enabled(config,family)
    if not config then return false end
    local spec=family and mod.portrait_families[family]
    local enabled=spec and config[spec.enabled_field]
    -- Old saves inherit their original master switch; never reroll/migrate offers.
    if enabled==nil then enabled=config.enabled end
    return enabled==true
end
-- Merge newly introduced switches into preferences, never into an active run.
mod.config.jokers=mod.config.jokers or {}
for _,key in ipairs(I.order) do
    if mod.config.jokers[key]==nil then mod.config.jokers[key]=true end
end
function I.begin_run(loading)
    if loading and not G.GAME.incj_config then G.GAME.incj_config={enabled=true,jokers={compound_interest=true}} end
    if not loading then G.GAME.incj_config=copy_table(mod.config) end
end
function I.enabled(key)
    local c=G.GAME and G.GAME.incj_config or mod.config
    key=key or 'compound_interest'
    return I.family_enabled(c,I.family(key)) and c.jokers and c.jokers[key]==true
end
local function save_config() SMODS.save_mod_config(mod) end
mod.config_tab=function()
    local nodes={create_toggle{label='Extra Jokers',ref_table=mod.config,ref_value='enabled',callback=save_config}}
    for family,spec in pairs(mod.portrait_families) do
        nodes[#nodes+1]=create_toggle{label=localize('k_incj_'..family),ref_table=mod.config,
            ref_value=spec.enabled_field,callback=save_config}
    end
    for _,key in ipairs(I.order) do
        nodes[#nodes+1]=create_toggle{label=localize{type='name_text',set='Joker',key='j_incj_'..key},
            ref_table=mod.config.jokers,ref_value=key,callback=save_config}
    end
    nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.1},nodes={
        {n=G.UIT.T,config={text=localize('k_incj_next_run'),scale=0.3,colour=G.C.UI.TEXT_LIGHT}}}}
    return {n=G.UIT.ROOT,config={align='cm',padding=0.15,colour=G.C.CLEAR},nodes=nodes}
end
local toggle=create_toggle
function create_toggle(args)
    if args and args.ref_table==mod and args.ref_value=='should_enable' then
        args.ref_table=mod.config;args.ref_value='enabled';args.callback=save_config
    end
    return toggle(args)
end
local function spanish()
    return (G.SETTINGS.language or ''):sub(1,2)=='es'
end
SMODS.Atlas{key='compound_interest',path='compound_interest.png',px=71,py=95}
SMODS.Joker{
    key='compound_interest', atlas='compound_interest', pos={x=0,y=0},
    -- Collection visibility and shop eligibility are independent of discovery.
    -- Card:add_to_deck and the game's profile metadata persist first acquisition.
    rarity=3, cost=settings.base_cost, unlocked=true, discovered=false,
    blueprint_compat=true, eternal_compat=true, perishable_compat=true,
    config={extra={initial_xmult=settings.initial_xmult,growth_per_round=settings.growth_per_round,
                   won_rounds=0,last_won_round=''}},
    -- The sole random entry point is the normal-shop hook in lovely.toml.
    in_pool=function() return false end,
    -- Optional event-pool interface; the ordinary shop's 1% roll is unchanged.
    black_market_weight=settings.shop_probability,
    black_market_in_pool=function(self)
        return I.enabled() and logic.eligible{normal_joker=true,unlocked=self.unlocked,banned=G.GAME.banned_keys[self.key],
            used=G.GAME.used_jokers[self.key],showman=SMODS.showman(self.key)}
    end,
    loc_vars=function(self,info_queue,card)
        local extra=card.ability.extra
        return {vars={logic.format(extra.growth_per_round,spanish()),logic.format(logic.factor(extra),spanish())}}
    end,
    set_badges=function(self,card,badges)
        badges[1]=create_badge(localize('k_incj_ultra'),G.C.PURPLE,G.C.WHITE,1)
    end,
    calculate=function(self,card,context)
        if card.debuff then return end
        local extra=card.ability.extra
        if context.joker_main then return {x_mult=logic.factor(extra)} end
        local game=G.GAME
        local blind=game.blind
        local key=blind and blind.config and blind.config.blind and blind.config.blind.key or ''
        local state={owned=card.area==G.jokers, debuff=card.debuff,
            played=game.facing_blind==true,
            won=blind and blind.chips>0 and game.chips>=blind.chips,
            round=tostring(game.round)..':'..tostring(game.round_resets.ante)..':'..key}
        if logic.advance(extra,context,state) then
            return {message=localize('k_incj_up')..' X'..logic.format(logic.factor(extra),spanish()),colour=G.C.MULT,card=card}
        end
    end,
}

function I.shop_offer(kind,area)
    if not I.enabled() then return end
    local center=G.P_CENTERS[I.key]
    if not center then return end
    local state={normal_joker=kind=='Joker' and area==G.shop_jokers,
        unlocked=center.unlocked, banned=G.GAME.banned_keys[I.key],
        used=G.GAME.used_jokers[I.key], showman=SMODS.showman(I.key)}
    if not logic.eligible(state) then return end
    if logic.roll(pseudorandom('incj_normal_shop_offer'),settings.shop_probability) then return I.key end
end

-- No development shortcut is exposed in the release unless explicitly enabled.
if settings.debug then
    function I.debug_spawn()
        return SMODS.add_card{key=I.key,area=G.jokers}
    end
end

mod.affects_gameplay=true
mod.qol_snapshot=function(loading)
    local groups,by_family={},{}
    for _,key in ipairs(I.order) do
        if I.enabled(key) then
            local family=I.family(key) or 'extra'
            if not by_family[family] then
                local group={id=mod.id..':'..family,name=family=='extra' and 'Extra Jokers' or localize('k_incj_'..family),children={}}
                by_family[family]=group;groups[#groups+1]=group
            end
            local children=by_family[family].children
            children[#children+1]=localize{type='name_text',set='Joker',key='j_incj_'..key}
        end
    end
    if #groups>0 then return {groups=groups} end
end
assert(SMODS.load_file('run_jokers.lua'))()(I)
assert(SMODS.load_file('options.lua'))()(I)
assert(SMODS.load_file('double_jokers.lua'))()(I)
assert(SMODS.load_file('options_challenge.lua'))()(I)

assert(SMODS.load_file('precision_jokers.lua'))()(I)
assert(SMODS.load_file('mission_jokers.lua'))()(I)
assert(SMODS.load_file('expansion48.lua'))()(I,mod)
