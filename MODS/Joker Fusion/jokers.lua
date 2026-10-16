return function(F,P)
    local function real(card,c) return P.real(c) and not card.debuff and card.area==G.jokers and not card.getting_sliced end
    for _,id in ipairs(F.order) do
      if id~='broken_copier' then
        local key=id
        SMODS.Atlas{key=key,path=key..'.png',px=71,py=95,disable_mipmap=true,
            inject=function(self) SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest') end}
        SMODS.Joker{
            key=key,atlas=key,pos={x=0,y=0},rarity='fuse_fusion',cost=12,
            unlocked=true,discovered=false,blueprint_compat=true,eternal_compat=true,perishable_compat=true,
            in_pool=function() return false end,
            config={extra={xmult=F.mod.config.last_meal_initial}},
            set_ability=function(_,card) card.ability.extra={xmult=F.config().last_meal_initial} end,
            update=function(_,card)
                if card.ability.extra.fuse_pending_destroy and card.area==G.jokers and not card.getting_sliced and not card.removed then
                    SMODS.destroy_cards(card)
                end
            end,
            loc_vars=function(_,queue,card)
                local c,s=F.config(),card.ability.extra
                if key=='midas' then return {vars={c.midas_xmult,c.midas_money_per_step,c.midas_money_step,c.midas_max_reward}}
                elseif key=='banana_cannon' then return {vars={c.banana_xmult,c.banana_odds,c.banana_first_hand_odds}}
                elseif key=='last_meal' then return {vars={s.xmult,c.last_meal_decay,c.last_meal_min,c.last_meal_restore,c.last_meal_max}}
                else
                    local effect=s.glitch_effect and c.glitch_effects[s.glitch_effect]
                    return {key=effect and 'j_fuse_glitch_revealed' or 'j_fuse_glitch',
                        vars=effect and {effect.mult or 0,effect.x_mult or 1,effect.chips or 0} or {}}
                end
            end,
            calculate=function(_,card,context)
                if card.debuff or card.ability.extra.fuse_pending_destroy then return end
                local s,c=card.ability.extra,F.config()
                if context.joker_main then
                    if key=='midas' then return {x_mult=c.midas_xmult}
                    elseif key=='banana_cannon' then return {x_mult=c.banana_xmult}
                    elseif key=='last_meal' then return {x_mult=s.xmult}
                    elseif s.glitch_effect then return copy_table(c.glitch_effects[s.glitch_effect]) end
                end
                if not real(card,context) then return end
                if key=='glitch' and context.setting_blind and P.once(s,'rolled_blind',
                    tostring(G.GAME.round)..':'..tostring(G.GAME.round_resets.ante)..':'..tostring(context.blind and context.blind.key)) then
                    s.glitch_effect=math.min(#c.glitch_effects,math.floor(P.roll('glitch')*#c.glitch_effects)+1)
                    return {message=localize('k_fuse_revealed'),colour=G.C.PURPLE}
                end
                if key=='last_meal' and context.using_consumeable then
                    -- The native context belongs to one physical consumable use.
                    if context.consumeable and not context.consumeable.ability.fuse_meal_use then
                        G.GAME.fuse_use_serial=(G.GAME.fuse_use_serial or 0)+1
                        context.consumeable.ability.fuse_meal_use=G.GAME.fuse_use_serial
                    end
                    local token=context.consumeable and context.consumeable.ability.fuse_meal_use
                    if token and P.once(s,'last_use',token) then
                        local before=s.xmult
                        s.xmult=math.min(c.last_meal_max,math.floor((s.xmult+c.last_meal_restore)*100+0.5)/100)
                        if s.xmult~=before then return {message='X'..before..' > X'..s.xmult,colour=G.C.MULT,card=card} end
                    end
                end
                if P.won(context) and P.once(s,'last_win',P.token()) then
                    if key=='midas' then
                        local amount=math.min(c.midas_max_reward,math.max(0,math.floor(G.GAME.dollars/c.midas_money_step))*c.midas_money_per_step)
                        if amount>0 then
                            ease_dollars(amount,true)
                            return {message='+$'..amount,colour=G.C.MONEY,card=card}
                        end
                    elseif key=='banana_cannon' then
                        local odds=G.GAME.current_round.hands_played==1 and c.banana_first_hand_odds or c.banana_odds
                        if P.roll('banana')<1/odds then
                            SMODS.destroy_cards(card)
                            if card.getting_sliced then s.fuse_pending_destroy=true end
                        else return {message=localize('k_risk_survived'),colour=G.C.GREEN,card=card} end
                    elseif key=='last_meal' then
                        local before=s.xmult
                        s.xmult=math.max(c.last_meal_min,math.floor((s.xmult-c.last_meal_decay)*100+0.5)/100)
                        if s.xmult~=before then return {message='X'..before..' > X'..s.xmult,colour=G.C.MULT,card=card} end
                    end
                end
            end,
        }
    end
    end
    local use=Card.use_consumeable
    function Card:use_consumeable(...)
        if F.state() then
            G.GAME.fuse_use_serial=(G.GAME.fuse_use_serial or 0)+1
            self.ability.fuse_meal_use=G.GAME.fuse_use_serial
        end
        return use(self,...)
    end
    local copy=copy_card
    function copy_card(...)
        local card=copy(...);if card.ability then card.ability.fuse_meal_use=nil end;return card
    end
end
