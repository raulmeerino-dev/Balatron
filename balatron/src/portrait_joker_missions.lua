-- Mission counters live in the native run save. Unlocks, profile isolation,
-- locked collection text and notifications belong to vanilla/Steamodded.
local J={}
function J.real(c)
    return not (c.blueprint or c.retrigger_joker or c.repetition or c.individual)
end
function J.count(t) local n=0;for _ in pairs(t or {}) do n=n+1 end;return n end
function J.blind_token()
    local g=G.GAME
    return tostring(g.round)..':'..tostring(g.round_resets.ante)..':'..tostring(g.blind.config.blind.key)
end
function J.hand_token() return J.blind_token()..':'..tostring(G.GAME.hands_played) end
local conditions={
    scorched_earth=function(s) return s.destroyed>=12 end,
    powder_keg=function(s) return s.last_hand_boss==true end,
    graft=function(s) return s.enhancements>=3 end,
    intermission=function(s) return s.blind_consumables>=5 end,
    wayfinder=function(s) return J.count(s.ante_hands)>=5 end,
    orrery=function(s) return J.count(s.planets)>=4 end,
}
function J.decorate(def,id)
    def.unlocked=false;def.discovered=false
    def.unlock_condition={type='portrait_joker_mission'}
    def.check_for_unlock=function(_,args)
        return args.type=='portrait_joker_mission' and args.stats and conditions[id](args.stats)
    end
    return def
end
function J.track(c)
    if not G.GAME or G.STAGE~=G.STAGES.RUN or not J.real(c) or G.GAME.seeded or G.GAME.challenge then return end
    local g=G.GAME
    g.portrait_joker_missions=g.portrait_joker_missions or {
        destroyed=0,destroyed_ids={},enhancements=0,blind_consumables=0,ante_hands={},planets={}}
    local s=g.portrait_joker_missions;local changed=false
    if c.before and c.scoring_name then
        if s.ante~=g.round_resets.ante then s.ante=g.round_resets.ante;s.ante_hands={} end
        s.ante_hands[c.scoring_name]=true
        local types={}
        for _,card in ipairs(c.scoring_hand or {}) do
            if not card.debuff and card.config.center.set=='Enhanced' then types[card.config.center.key]=true end
        end
        s.enhancements=math.max(s.enhancements,J.count(types));changed=true
    end
    if c.remove_playing_cards then
        for _,card in ipairs(c.removed or {}) do
            if card.playing_card and card.ability then
                -- Reuse UPG's saved destruction receipt; copy_card already clears
                -- it on physical copies. Playing-card IDs can be renumbered.
                local id=card.ability.upg_destruction_token
                if not id then
                    g.upg_destruction_serial=(g.upg_destruction_serial or 0)+1
                    id=tostring(g.upg_destruction_serial)
                    card.ability.upg_destruction_token=id
                end
                if not s.destroyed_ids[id] then s.destroyed_ids[id]=true;s.destroyed=s.destroyed+1 end
            end
        end
        changed=true
    end
    if c.using_consumeable and c.consumeable then
        if c.consumeable.ability.set=='Planet' then s.planets[c.consumeable.config.center.key]=true end
        if g.facing_blind then s.blind_consumables=s.blind_consumables+1 end
        changed=true
    end
    if c.end_of_round and c.main_eval and not c.game_over and g.facing_blind and g.blind.boss and
        g.current_round.hands_left==0 and g.chips>=2*g.blind.chips then
        s.last_hand_boss=true;changed=true
    end
    if changed then check_for_unlock{type='portrait_joker_mission',stats=s} end
end
function J.atlas(key)
    SMODS.Atlas{key=key,path=key..'.png',px=71,py=95,disable_mipmap=true,
        inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
end
return J
