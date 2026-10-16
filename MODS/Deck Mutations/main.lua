local P=PortraitGameplay
local M=P.register(SMODS.current_mod)
local defaults=assert(SMODS.load_file('config.lua'))()
for key,value in pairs(defaults) do
    if M.mod.config[key]==nil then M.mod.config[key]=type(value)=='table' and copy_table(value) or value end
end
for id,weight in pairs(defaults.mutation_weights) do
    if M.mod.config.mutation_weights[id]==nil then M.mod.config.mutation_weights[id]=weight end
end
local order=assert(SMODS.load_file('mutations.lua'))()
local rules=assert(SMODS.load_file('run_rules.lua'))()
for _,d in ipairs(assert(SMODS.load_file('expansion.lua'))()) do d.expansion=true;rules[#rules+1]=d end
for _,d in ipairs(assert(SMODS.load_file('expansion48.lua'))()) do rules[#rules+1]=d end
for _,d in ipairs(rules) do
    d.icon64=true;order[#order+1]=d
    if M.mod.config.mutation_weights[d.id]==nil then M.mod.config.mutation_weights[d.id]=6 end
end
local defs={};for _,d in ipairs(order) do defs[d.id]=d end
local function levels() local s=M.state();s.levels=s.levels or {};return s.levels end
local function level(id) return levels()[id] or 0 end
local Unlocks=assert(SMODS.load_file('unlocks.lua'))()(P,M,order)
local Rules=assert(SMODS.load_file('run_effects.lua'))()(P,M,level,rules)
for _,d in ipairs(rules) do local def=d;def.apply=function() Rules.apply(def) end end
assert(SMODS.load_file('scoring.lua'))()(M,level)
local function name(id,n)
    return localize('k_dm_'..id)..(defs[id].levels and ' '..({'I','II','III'})[n] or '')
end
local function vars(id,n)
    local d,c=defs[id],M.config()
    if id=='boss_dividend' then return {3} end
    return {d.value and (c[d.value] or defaults[d.value])*n or id=='interest_rate' and n or
        id=='enhanced_genetics' and c.genetics_chance*100 or id=='lucky_deck' and (c.lucky_multiplier-1)*100 or 1}
end
function M.required_offer() return M.state() and M.state().pending~=nil end
function M.offer()
    local pending=M.state().pending
    if not pending then return end
    -- Keep a saved offer immutable; discard invalid entries without drawing replacements.
    local valid={}
    for _,id in ipairs(pending) do
        if defs[id] and Unlocks.unlocked(id) and level(id)<(defs[id].levels and M.config().max_level or 1) then valid[#valid+1]=id end
    end
    M.state().pending=#valid>0 and valid or nil;pending=M.state().pending
    if not pending then save_run();return end
    M.selecting=nil
    local cells={}
    for _,id in ipairs(pending) do cells[#cells+1]=M.choice(id,level(id)+1) end
    local Scroll=require('portrait_run_scroll')
    G.SETTINGS.paused=true
    local view=Scroll({{n=G.UIT.R,config={align='cm',padding=0.18},nodes=cells}},9.2,4.0)
    G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{
        no_back=true,colour=G.C.BLACK,outline_colour=G.C.UI.OUTLINE_LIGHT,padding=0.15,
        contents={P.text(localize('k_dm_choose'),0.5),
            {n=G.UIT.R,config={align='cm',padding=0.25},nodes={{n=G.UIT.O,config={object=view}}}}}}}
    return true
end
G.FUNCS.dm_choose=function(e)
    local id,s=e.config.ref_table,M.state()
    if not s or M.selecting then return end
    local valid=false;for _,key in ipairs(s.pending or {}) do if key==id then valid=true end end
    if not valid or not defs[id] or not Unlocks.unlocked(id) or level(id)>=(defs[id].levels and M.config().max_level or 1) then return end
    M.selecting=id;s.pending=nil
    if e.config.dm_sprite then e.config.dm_sprite:juice_up(0.35,0.2) end
    play_sound('card1',1.05,0.6)
    levels()[id]=level(id)+1
    if defs[id].apply then defs[id].apply() end
    if PortraitCollection then PortraitCollection.mark('mutations',id,level(id)) end
    save_run()
    G.E_MANAGER:add_event(Event{trigger='after',delay=0.22,func=function()
        save_run();G.FUNCS.exit_overlay_menu();M.selecting=nil;P.schedule_offers();return true
    end})
end
M.mod.calculate=function(self,context)
    Unlocks.context(context)
    if not M.state() then return end
    if context.initial_scoring_step and P.real(context) then M.reset_sequence() end
    local rule_effect=Rules.calculate(context)
    if rule_effect then return rule_effect end
    if context.joker_main and not context.blueprint and not context.retrigger_joker and
        not context.retrigger_joker_check and level('overload')>0 then
        local chips=math.max(0,100-20*(G.GAME.current_round.hands_played or 0))
        if chips>0 then return {chips=chips,message_card=G.deck,
            chip_message=M.feedback({'overload'},localize{type='variable',key='a_chips',vars={chips}},G.C.CHIPS)} end
    end
    if P.won(context) and context.beat_boss and M.enabled() and P.once(M.state(),'last_boss',P.token()) then
        if level('boss_dividend')>0 then
            local amount=3
            ease_dollars(amount,true)
            card_eval_status_text(G.deck,'extra',nil,nil,nil,M.feedback({'boss_dividend'},'+$'..amount,G.C.MONEY,0.75))
        end
        local eligible={}
        for _,d in ipairs(order) do
            if Unlocks.unlocked(d.id) and level(d.id)<(d.levels and M.config().max_level or 1) then eligible[#eligible+1]=d.id end
        end
        local choices={}
        for i=1,3 do
            local id=P.choose(eligible,function(k)
                local weights=M.config().mutation_weights or {}
                -- Older run snapshots predate newly registered entries; explicit zero stays disabled.
                return weights[k]~=nil and weights[k] or M.mod.config.mutation_weights[k] or 6
            end,'mutation_'..i)
            if not id then break end
            choices[#choices+1]=id
            for j=#eligible,1,-1 do if eligible[j]==id then table.remove(eligible,j) end end
        end
        if #choices>0 then M.state().pending=choices end
    end
    if context.individual and not context.retrigger_joker and not context.retrigger_joker_check and
        context.cardarea==G.play and context.other_card and not context.other_card.debuff then
        local card,c=context.other_card,M.config()
        local chips,mult=0,0
        local chip_icons,mult_icons={},{}
        local function add(id,amount,is_mult)
            if amount<=0 then return end
            local icons=is_mult and mult_icons or chip_icons
            icons[#icons+1]=id
            if is_mult then mult=mult+amount else chips=chips+amount end
        end
        if Rules.has('empowered_cards') then add('empowered_cards',5) end
        if Rules.has('strong_seals') and card.seal then add('strong_seals',5) end
        local chain,resonance=M.sequence_bonus(card)
        add('chain_reaction',chain)
        add('resonance',resonance,true)
        if card:is_suit('Hearts') then add('heavy_hearts',level('heavy_hearts')*c.hearts_chips) end
        if card:is_suit('Spades') then add('sharp_spades',level('sharp_spades')*c.spades_mult,true) end
        if card:is_suit('Clubs') then add('steady_clubs',level('steady_clubs')*(c.clubs_mult or 2),true) end
        if card:is_suit('Diamonds') then add('diamond_reserve',level('diamond_reserve')*(c.diamonds_chips or 6)) end
        local rank=card:get_id()
        if not SMODS.has_no_rank(card) then
            if rank==14 then add('ace_up_sleeve',level('ace_up_sleeve')*(c.ace_chips or 12)) end
            if rank>=11 and rank<=13 then add('royal_blood',level('royal_blood')*c.royal_chips) end
            if rank>=2 and rank<=5 then add('low_life',level('low_life')*c.low_mult,true) end
        end
        -- Resolve in SMODS' individual-card slot, including legitimate red-seal
        -- repetitions. no_retrigger would suppress the entire mod effect in
        -- the pinned loader; guard Joker retriggers explicitly instead.
        if chips>0 or mult>0 then return {chips=chips>0 and chips or nil,mult=mult>0 and mult or nil,
            juice_card=card,message_card=card,
            chip_message=M.feedback(chip_icons,localize{type='variable',key='a_chips',vars={chips}},G.C.CHIPS),
            mult_message=M.feedback(mult_icons,localize{type='variable',key='a_mult',vars={mult}},G.C.MULT)} end
    end
end
local probability=SMODS.get_probability_vars
function SMODS.get_probability_vars(obj,n,d,id,from_roll,no_mod)
    local a,b=probability(obj,n,d,id,from_roll,no_mod)
    if not no_mod and M.state() and level('lucky_deck')>0 and M.config().safe_probabilities[id] then
        a=math.max(a,math.min(a*M.config().lucky_multiplier,b*M.config().lucky_cap))
    end
    return a,b
end
local function enhance(card)
    if not M.state() or level('enhanced_genetics')==0 or not card or card.ability.pg_genetics_checked then return card end
    card.ability.pg_genetics_checked=true
    if card.config.center==G.P_CENTERS.c_base and P.roll('genetics')<M.config().genetics_chance then
        local pool=P.pool('Enhanced')
        local key=P.choose(pool,function() return 1 end,'genetics_enhancement')
        if key then
            card:set_ability(G.P_CENTERS[key])
            card_eval_status_text(card,'extra',nil,nil,nil,M.feedback({'enhanced_genetics'},'',G.C.GREEN,0.75))
        end
    end
    return card
end
local create=create_playing_card
local function enhance_results(card,...)
    enhance(card)
    return card,...
end
function create_playing_card(...) return enhance_results(create(...)) end
local create_other=create_card
function create_card(set,...)
    -- Jokers/consumables use the original call, including all nil arguments
    -- and return values. Only newly created playing cards need genetics.
    if set~='Base' and set~='Enhanced' then return create_other(set,...) end
    return enhance_results(create_other(set,...))
end

assert(SMODS.load_file('ui.lua'))()(P,M,order,level,name,vars)
require('expansion48.mutations')(P,M,Rules,order)
