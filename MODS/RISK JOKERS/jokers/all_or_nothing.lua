return {
    key='all_or_nothing',name='All or Nothing',cost_key='all_or_nothing_cost',
    initial_state=function(c) return {xmult=c.all_or_nothing_initial_xmult} end,
    mult=function(s,c)
        if G.GAME.current_round.hands_played==0 then return s.xmult end
    end,
    vars=function(s,c) return {s.xmult,c.all_or_nothing_decay,c.all_or_nothing_min_xmult} end,
    secondary=function(card,context,c,M)
        -- Same authoritative final-score event as Olympian/World Record. The
        -- native Blind hand count and chips advance AFTER this event; therefore
        -- use final score plus existing chips, not the still-queued chips easing.
        if not context.portrait_hand_result or not M.real(card,context) then return end
        local game,s=G.GAME,card.ability.extra
        if game.current_round.hands_played~=0 or not game.facing_blind or
            not game.blind or game.blind.chips<=0 then return end
        local token=M.blind_token()
        if s.checked_blind==token then return end
        local score=context.record_score
        if type(score)~='number' or score~=score then return end
        s.checked_blind=token
        local before=s.xmult
        local won=score>=game.blind.chips-game.chips
        if not won then s.xmult=math.max(c.all_or_nothing_min_xmult,before-c.all_or_nothing_decay) end
        -- Receipt and permanent loss are synchronous native ability state;
        -- only presentation animates. No queued penalty can be lost or replayed.
        local message=won and 'JACKPOT' or localize{type='variable',key='a_risk_all_or_nothing_loss',vars={before,s.xmult}}
        require('portrait_reward_fx').joker_result(card,
            string.upper(localize{type='name_text',set='Joker',key='j_risk_all_or_nothing'}),message,won)
        return {calculated=true}
    end,
}
