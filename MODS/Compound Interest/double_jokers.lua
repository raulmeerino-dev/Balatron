-- Fixed-choice Doubles share Options' gestures and sprite lifecycle, not its RNG.
return function(I)
    local function active_mode(card, a, b)
        if not (G.STAGE==G.STAGES.RUN and G.jokers and card.area==G.jokers) then return localize('k_incj_double_choose') end
        return localize(card.ability.extra.selected=='B' and b or a)
    end
    local function register(def)
        local key=def.key
        SMODS.Atlas{key=key,path=key..'.png',px=71,py=95,disable_mipmap=true,
            inject=function(self)
                SMODS.Atlas.inject(self)
                self.image:setFilter('nearest','nearest')
            end}
        def.atlas=key;def.pos={x=2,y=0};def.portrait_family='doubles'
        def.rarity=3;def.cost=8;def.unlocked=true;def.discovered=false
        def.blueprint_compat=true;def.eternal_compat=true;def.perishable_compat=true
        def.no_main_mod_badge=true
        def.in_pool=function() return I.enabled(key) end
        SMODS.Joker(def)
    end
    register{
        key='color_call',config={extra={selected='A',mult=8}},
        loc_vars=function(self,queue,card)
            queue[#queue+1]={key='incj_double_controls',set='Other'}
            local vars={card.ability.extra.mult,active_mode(card,'k_incj_red','k_incj_black')}
            return {key='j_incj_color_call_tooltip',vars=vars,main_end=require('portrait_tooltips').modes(card,{
                {title=localize('k_incj_red'),colour=G.C.RED,loc={set='Other',key='incj_color_red',vars=vars}},
                {title=localize('k_incj_black'),loc={set='Other',key='incj_color_black',vars=vars}},
            })}
        end,
        calculate=function(self,card,context)
            if card.debuff or not context.individual or context.cardarea~=G.play then return end
            local scored=context.other_card
            if not scored or scored.debuff then return end
            local black=card.ability.extra.selected=='B'
            -- is_suit preserves native Wild Card, Smeared Joker and no-suit rules.
            -- One OR condition prevents Wild cards receiving the bonus twice.
            if scored:is_suit(black and 'Spades' or 'Hearts') or scored:is_suit(black and 'Clubs' or 'Diamonds') then
                return {mult=card.ability.extra.mult,card=context.blueprint_card or card}
            end
        end,
    }
    register{
        key='double_entry',config={extra={selected='A',mult=30,cost=1,income=3,last_debit_hand=''}},
        loc_vars=function(self,queue,card)
            queue[#queue+1]={key='incj_double_controls',set='Other'}
            local e=card.ability.extra
            local vars={e.mult,e.cost,e.income,active_mode(card,'k_incj_debit','k_incj_credit')}
            return {key='j_incj_double_entry_tooltip',vars=vars,main_end=require('portrait_tooltips').modes(card,{
                {title=localize('k_incj_debit'),colour=G.C.RED,loc={set='Other',key='incj_entry_debit',vars=vars}},
                {title=localize('k_incj_credit'),colour=G.C.GREEN,loc={set='Other',key='incj_entry_credit',vars=vars}},
            })}
        end,
        calculate=function(self,card,context)
            local e=card.ability.extra
            if card.debuff or e.selected=='B' then return end
            if context.before and not context.blueprint and not context.retrigger_joker and card.area==G.jokers then
                -- A real owned card pays once per hand. Copies/retriggers copy
                -- scoring output, not a second charge; the token survives save/load.
                local hand=tostring(G.GAME.round)..':'..tostring(G.GAME.current_round.hands_played or 0)
                if e.last_debit_hand~=hand then
                    e.last_debit_hand=hand
                    return {dollars=-e.cost,card=card}
                end
            end
            if context.joker_main then return {mult=e.mult} end
        end,
        calc_dollar_bonus=function(self,card)
            -- Native cash-out owns the payment, its animation and its save state.
            if not card.debuff and card.ability.extra.selected=='B' then return card.ability.extra.income end
        end,
    }
end
