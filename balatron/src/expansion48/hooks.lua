return function(X)
    local shuffle=CardArea.shuffle
    function CardArea:shuffle(seed,...)
        local result=shuffle(self,seed,...)
        if X.state() and self==G.deck and type(seed)=='string' and seed:sub(1,2)=='nr' then
            X.track{exp48_blind_shuffled=true}
        end
        return result
    end
    local evaluate=eval_card
    function eval_card(card,context,...)
        local lucky=X.state() and context.main_scoring and context.cardarea==G.play and not card.debuff and card.config.center.key=='m_lucky'
        if X.state() and context.main_scoring and context.cardarea==G.play and not card.debuff and not context.extra_enhancement and not SMODS.extra_enhancement_calc_in_progress then
            X.track{exp48_score_card=true,card=card,context=context,hand_token=X.blind()..':'..G.GAME.hands_played}
        end
        local result,post=evaluate(card,context,...)
        if lucky and card.lucky_trigger then X.track{exp48_lucky_activation=true,card=card} end
        return result,post
    end
    local played_money=Card.get_p_dollars
    function Card:get_p_dollars(...)
        local first=SMODS.post_prob and #SMODS.post_prob or 0
        local result=played_money(self,...)
        -- Keep the Lucky component distinct from a Gold Seal's dollars, including
        -- a temporary quantum enhancement and Broken Record's cached outcomes.
        if X.state() and G.GAME.facing_blind and G.STATE==G.STATES.HAND_PLAYED then
            for i=first+1,#(SMODS.post_prob or {}) do
                local roll=SMODS.post_prob[i]
                if roll.trigger_obj==self and roll.identifier=='lucky_money' and roll.result then
                    roll.exp48_lucky_dollars=self.ability.p_dollars or 0
                end
            end
        end
        return result
    end
    local repetitions=SMODS.calculate_repetitions
    function SMODS.calculate_repetitions(card,context,reps)
        local result=repetitions(card,context,reps)
        if X.state() and context.cardarea==G.play then
            local sources={};local count=0
            for _,entry in ipairs(reps) do
                if type(entry)=='table' then for _,effect in pairs(entry) do
                    if type(effect)=='table' and not effect.retrigger_flag then
                        count=count+1
                        local source=effect.card or effect.message_card or card
                        local seen={}
                        while source and source.config and (source.config.center.key=='j_blueprint' or source.config.center.key=='j_brainstorm') and not seen[source] do
                            seen[source]=true
                            if source.config.center.key=='j_brainstorm' then source=G.jokers.cards[1]
                            else
                                local next_card
                                for i,joker in ipairs(G.jokers.cards) do if joker==source then next_card=G.jokers.cards[i+1];break end end
                                source=next_card
                            end
                        end
                        source=source or card
                        sources[X.id(source) or tostring(source)]=true
                    end
                end end
            end
            X.track{exp48_repetitions=true,card=card,count=count,sources=sources}
        end
        return result
    end
    local effect=SMODS.calculate_individual_effect
    function SMODS.calculate_individual_effect(e,scored,key,amount,...)
        local money=key=='p_dollars' or key=='h_dollars' or key=='dollars'
        local source=e.card or scored
        local before=X.money_converted
        if money and type(amount)=='number' and amount>0 and X.state() and G.GAME.facing_blind and
            X.mutations and X.mutations.convert_money and X.mutations.convert_money(amount,source,'ability') then
            X.track{exp48_money=true,amount=amount,card=source,native_playing=source and source.playing_card~=nil,converted=true}
            return true
        end
        local result=effect(e,scored,key,amount,...)
        if money and type(amount)=='number' and amount>0 and X.state() and G.GAME.facing_blind then
            X.track{exp48_money=true,amount=amount,card=source,native_playing=source and source.playing_card~=nil,
                converted=X.money_converted~=before}
        end
        return result
    end
    local endround=SMODS.calculate_end_of_round_effects
    function SMODS.calculate_end_of_round_effects(context)
        local result=endround(context)
        if context.cardarea==G.hand and X.state() then X.track{exp48_blind_paid=true} end
        return result
    end
    local sale=G.FUNCS.sell_card
    G.FUNCS.sell_card=function(e,...)
        local card=e and e.config and e.config.ref_table
        if card and X.state() then X.track{exp48_selling=true,card=card,price=card.sell_cost or 0} end
        return sale(e,...)
    end
    local use=Card.use_consumeable
    function Card:use_consumeable(...)
        local snapshots={}
        if X.state() and self.ability.set=='Tarot' then
            for _,c in ipairs(G.playing_cards or {}) do snapshots[X.id(c)]={rank=c.base.id,suit=c.base.suit,
                center=c.config.center.key,seal=c.seal,edition=c.edition and c.edition.key} end
        end
        local result=use(self,...)
        if next(snapshots) then
            local game=G.GAME;local key=self.config.center.key
            G.E_MANAGER:add_event(Event{trigger='after',delay=0,func=function()
                if G.GAME==game then X.track{exp48_tarot_resolved=true,key=key,before=snapshots} end
                return true
            end})
        end
        return result
    end
    function X.joker_history(key,field)
        local h=G.GAME.hands[key];local value=h and h[field] or 0
        local s=X.state();local a=s and s.alibi and s.alibi[key]
        if a and a.ante==G.GAME.round_resets.ante then
            if field=='played' then return math.max(0,value-a.played) end
            if field=='played_this_round' and a.round==G.GAME.round then return math.max(0,value-a.played_this_round) end
        end
        return value
    end
end
