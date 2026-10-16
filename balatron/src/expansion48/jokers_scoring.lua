return function(J)
    local X=J.X
    local calculate=SMODS.calculate_main_scoring
    local repetitions=SMODS.calculate_repetitions
    local function repetition_source(card)
        local seen={}
        while card and (J.key(card)=='j_blueprint' or J.key(card)=='j_brainstorm') do
            if seen[card] then return nil end;seen[card]=true
            if J.key(card)=='j_brainstorm' then card=G.jokers.cards[1]
            else
                local following
                for i,c in ipairs(G.jokers.cards) do if c==card then following=G.jokers.cards[i+1];break end end
                card=following
            end
        end
        return card
    end
    -- Evaluate each source exactly once in its native repetition context. Only
    -- the resulting extra activations are transferred; original plays stay put.
    SMODS.calculate_repetitions=function(card,context,reps)
        local result=repetitions(card,context,reps)
        local route=J.route
        if route and context.cardarea==G.play and card~=route.target then
            for i=2,#reps do route.extras[#route.extras+1]={effect=reps[i],source=card} end
            for i=#reps,2,-1 do reps[i]=nil end
        end
        return result
    end
    local function transferred_activation(card,context,entry)
        local _,effect=next(entry.effect)
        SMODS.calculate_effect(effect,effect.card)
        if effect.retrigger_flag then return end
        percent=(percent or 0)+(percent_delta or 0.08)
        local previous=X.scoring_card;X.scoring_card=card
        context.cardarea=G.play;context.main_scoring=true
        local effects={eval_card(card,context)}
        SMODS.calculate_quantum_enhancements(card,effects,context)
        context.main_scoring=nil;context.individual=true;context.other_card=card
        if next(effects) then
            SMODS.calculate_card_areas('jokers',context,effects,{main_scoring=true})
            SMODS.calculate_card_areas('individual',context,effects,{main_scoring=true})
        end
        SMODS.trigger_effects(effects,card)
        local sources={};local source=repetition_source(effect.card or effect.message_card or entry.source)
        if source and source.ability then sources[X.id(source)]=true end
        X.track{exp48_redirected_repetitions=true,card=card,source_card=entry.source,sources=sources}
        context.individual=nil;context.other_card=nil;card.lucky_trigger=nil;X.scoring_card=previous
    end
    SMODS.calculate_main_scoring=function(context,scoring_hand)
        if context.cardarea==G.hand and X.has('j_incj_between_lines') then
            -- A temporary view makes native Baron, Raised Fist, Mime and held
            -- enhancements see the same identities. Physical areas never move.
            local original=G.hand.cards;local virtual={}
            for _,card in ipairs(original) do virtual[#virtual+1]=card end
            for _,card in ipairs(context.full_hand or {}) do
                if not SMODS.in_scoring(card,context.scoring_hand or {}) and not card.destroyed and not card.shattered then
                    virtual[#virtual+1]=card
                end
            end
            G.hand.cards=virtual
            local result=calculate(context,scoring_hand)
            G.hand.cards=original
            return result
        end
        if context.cardarea==G.play and scoring_hand and X.has('j_incj_lightning_rod') then
            local target
            for _,card in ipairs(G.play.cards) do
                if SMODS.in_scoring(card,scoring_hand) and
                    (not target or card.T.x<target.T.x) then target=card end
            end
            if target then
                local previous=J.route;local route={target=target,extras={}};J.route=route
                local result=calculate(context,scoring_hand);J.route=previous
                if not target.debuff then
                    for _,entry in ipairs(route.extras) do transferred_activation(target,context,entry) end
                end
                return result
            end
        end
        return calculate(context,scoring_hand)
    end
    local probability=SMODS.pseudorandom_probability
    SMODS.pseudorandom_probability=function(card,seed,numerator,denominator,identifier,no_mod)
        local effect=identifier or seed
        if card and card.playing_card and (effect=='lucky_mult' or effect=='lucky_money' or effect=='glass') and X.has('j_incj_broken_record') then
            local s=J.state();local token=X.blind()
            if s.luck_blind~=token then s.luck_blind=token;s.luck={} end
            local id=X.id(card);s.luck[id]=s.luck[id] or {}
            local stored=s.luck[id][effect]
            if stored~=nil then
                if type(stored)~='table' then stored={result=stored,numerator=numerator,denominator=denominator} end
                SMODS.post_prob=SMODS.post_prob or {}
                SMODS.post_prob[#SMODS.post_prob+1]={pseudorandom_result=true,result=stored.result,trigger_obj=card,
                    numerator=stored.numerator,denominator=stored.denominator,identifier=effect}
                return stored.result
            end
            local result=probability(card,seed,numerator,denominator,identifier,no_mod)
            local rolled=SMODS.post_prob and SMODS.post_prob[#SMODS.post_prob]
            s.luck[id][effect]={result=result,numerator=rolled and rolled.numerator or numerator,denominator=rolled and rolled.denominator or denominator}
            return result
        end
        return probability(card,seed,numerator,denominator,identifier,no_mod)
    end
end
