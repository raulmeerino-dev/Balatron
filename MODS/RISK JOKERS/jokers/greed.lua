return {
    key='greed',name='Greed',cost_key='greed_cost',
    mult=function(s,c) return c.greed_xmult end,
    vars=function(s,c) return {c.greed_xmult,c.greed_cost_per_scoring_hand} end,
    secondary=function(card,context,c,M)
        if M.scoring_hand(card,context) then
            ease_dollars(-c.greed_cost_per_scoring_hand,true) -- Vanilla permits negative balances.
            return {message='-$'..c.greed_cost_per_scoring_hand,colour=G.C.MONEY,card=card}
        end
    end,
}
