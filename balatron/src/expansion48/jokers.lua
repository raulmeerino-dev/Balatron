-- Stateful Jokers from the approved expansion. UI only edits persistent intents;
-- physical card moves happen once, after validating every selected identity.
local X=require('portrait_expansion48')
local J={X=X,actions={}}
function J.state()
    local s=X.state();if not s then return end
    s.jokers=s.jokers or {version=1,shop=0};return s.jokers
end
function J.key(card) return card and card.config and card.config.center and card.config.center.key end
function J.owned(card) return card and G.jokers and card.area==G.jokers and not card.removed and not card.getting_sliced end
function J.active(card) return J.owned(card) and not card.debuff end
function J.cards(key)
    local out={};for _,c in ipairs(G.jokers and G.jokers.cards or {}) do
        if J.active(c) and J.key(c)==key then out[#out+1]=c end
    end;return out
end
function J.find(id)
    return X.find(id,G.playing_cards) or X.find(id,G.jokers and G.jokers.cards) or X.find(id,G.shop_jokers and G.shop_jokers.cards)
end
function J.safe()
    return G.STAGE==G.STAGES.RUN and not G.OVERLAY_MENU and not G.CONTROLLER.locked and
        not (G.GAME.STOP_USE and G.GAME.STOP_USE>0) and not (G.play and #G.play.cards>0)
end
function J.between_hands() return G.STATE==G.STATES.SELECTING_HAND and J.safe() and G.GAME.facing_blind end
function J.hand_token() return X.blind()..':'..tostring(G.GAME.hands_played or 0) end
function J.reserve_area()
    if not G.exp48_reserve then
        G.exp48_reserve=CardArea(-30,-30,G.CARD_W,G.CARD_H,{card_limit=9999,type='deck',highlight_limit=0})
    end
    return G.exp48_reserve
end
function J.move(card,area)
    if card.area==area then return end
    if card.area then card.area:remove_card(card) end
    area:emplace(card)
end
function J.release_reserve(owner)
    local reserve=G.exp48_reserve;if not reserve then return end
    local list={};for _,c in ipairs(reserve.cards) do
        if not owner or c.ability.x48_reserved==owner then list[#list+1]=c end
    end
    for _,c in ipairs(list) do c.ability.x48_reserved=nil;J.move(c,G.deck) end
end
function J.prepare_reserve()
    local s=J.state();if not s then return end
    local token=X.blind();if s.reserve_blind==token then return end
    s.reserve_blind=token
    local minimum=math.max(1,G.hand.config.card_limit)
    for _,owner in ipairs(J.cards('j_incj_backstage')) do
        for _,id in ipairs(owner.ability.extra.reserve or {}) do
            local card=X.find(id)
            if card and card.area==G.deck and #G.deck.cards>minimum then
                card.ability.x48_reserved=X.id(owner);J.move(card,J.reserve_area())
            end
        end
        owner.ability.extra.reserve={}
    end
end
function J.final_score()
    local s=J.state();if not s then return end
    local token=J.hand_token();if s.final_hand==token then return end;s.final_hand=token
    local chips=SMODS.get_scoring_parameter('chips');local mode_a=false
    for _,card in ipairs(J.cards('j_incj_pendulum')) do
        local e=card.ability.extra
        if e.selected=='A' then e.bank=(e.bank or 0)+chips;mode_a=true
        else chips=chips+(e.bank or 0);e.bank=0 end
    end
    SMODS.Scoring_Parameters.chips.current=mode_a and 0 or chips
    -- The vanilla globals remain in a few pre-SMODS UI hooks.
    hand_chips=SMODS.Scoring_Parameters.chips.current
end
local entries={
    {'J02','backstage',2,7,{reserve={}}},
    {'J03','pendulum',3,8,{selected='B',bank=0}},
    {'J04','between_lines',2,7,{}},
    {'J05','thumbtack',3,10,{}},
    {'J06','extra_time',3,9,{}},
    {'J07','barterer',2,7,{}},
    {'J08','castling',2,7,{}},
    {'J09','lightning_rod',3,10,{}},
    {'J10','last_performance',3,9,{}},
    {'J11','promissory_note',2,7,{}},
    {'J12','broken_record',3,8,{}},
}
function J.register_extra(I,mod)
    for _,d in ipairs(entries) do
        local id,key,rarity,cost,state=unpack(d)
        I.order[#I.order+1]=key
        if mod.config.jokers[key]==nil then mod.config.jokers[key]=true end
        SMODS.Atlas{key=key,path=key..'.png',px=71,py=95,disable_mipmap=true,
            inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
        local def={key=key,atlas=key,pos={x=key=='pendulum' and 2 or 0,y=0},rarity=rarity,cost=cost,
            blueprint_compat=false,eternal_compat=true,perishable_compat=true,
            config={extra=copy_table(state)},
            in_pool=function(self) return self.unlocked and X.unlocked(id) and I.enabled(key) end,
            loc_vars=function(self,queue,card)
                local e=card.ability.extra
                if key=='pendulum' then
                    queue[#queue+1]={key='incj_double_controls',set='Other'}
                    return {vars={e.bank or 0,e.selected or 'B'}}
                end
                return {vars={key=='backstage' and #(e.reserve or {}) or 0}}
            end,
        }
        if key=='pendulum' then def.portrait_family='doubles';def.no_main_mod_badge=true end
        SMODS.Joker(X.decorate(def,id))
    end
end
function J.register_upg(R,E)
    R.mod.config.spyglass_cost=R.mod.config.spyglass_cost or 8
    local def={key='spyglass',atlas='spyglass',name='Spyglass',cost_key='spyglass_cost',expansion48='J01',blueprint_compat=false,
        initial_state={stage=1,progress=0,seen={}},
        stages={{loc_key='j_upg_spyglass_1',sprite={x=0,y=0}},
            {loc_key='j_upg_spyglass_2',sprite={x=1,y=0}},
            {loc_key='j_upg_spyglass_3',sprite={x=2,y=0},final=true}},
        loc_vars=function(s) return {s.stage==1 and 3 or s.stage==2 and 5 or 7,s.progress or 0,s.stage==1 and 3 or 7} end,
        calculate=function() end,
    }
    E.register(def);J.spyglass_def=def
end
function J.install()
    if J.installed then return end;J.installed=true
    require('expansion48.jokers_actions')(J)
    require('expansion48.jokers_scoring')(J)
    require('expansion48.jokers_lifetime')(J)
    local shuffle=CardArea.shuffle
    function CardArea:shuffle(seed,...)
        if self==G.deck and type(seed)=='string' and seed:sub(1,2)=='nr' then J.prepare_reserve() end
        return shuffle(self,seed,...)
    end
    local draw=G.FUNCS.draw_from_deck_to_hand
    G.FUNCS.draw_from_deck_to_hand=function(...)
        if G.GAME.facing_blind and G.GAME.current_round.hands_played==0 and G.GAME.current_round.discards_used==0 then J.prepare_reserve() end
        return draw(...)
    end
    local shop=PortraitGameplay.shop_ready
    function PortraitGameplay.shop_ready(...)
        local s=J.state();local token=tostring(G.GAME.round)
        if s and s.shop_round~=token then s.shop_round=token;s.shop=s.shop+1 end
        return shop(...)
    end
    local remove=Card.remove_from_deck
    function Card:remove_from_deck(...)
        if J.key(self)=='j_incj_backstage' then
            J.release_reserve(X.id(self));self.ability.extra.reserve={}
        end
        return remove(self,...)
    end
    X.listen(function(c)
        if c.end_of_round and c.main_eval and not c.blueprint and not c.retrigger_joker then
            J.release_reserve()
            for _,card in ipairs(G.playing_cards or {}) do card.ability.x48_pin=nil end
        end
        if c.hand_drawn and not c.blueprint and not c.retrigger_joker then J.refresh_pins() end
        if c.after and not c.blueprint and not c.retrigger_joker and not c.individual then
            local s=J.state();s.last_scoring={}
            for _,card in ipairs(c.scoring_hand or {}) do s.last_scoring[#s.last_scoring+1]=X.id(card) end
        end
    end)
end
return J
