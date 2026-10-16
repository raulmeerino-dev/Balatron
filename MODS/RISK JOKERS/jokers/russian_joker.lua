return {
    key='russian_joker',name='Russian Joker',cost_key='russian_cost',
    mult=function(s,c) return c.russian_xmult end,
    vars=function(s,c) return {c.russian_xmult,c.russian_destroy_chance*100} end,
    secondary=function(card,context,c,M)
        if M.won(card,context) then
            -- Each real instance advances the shared seeded stream once.
            if pseudorandom(pseudoseed('risk_russian'))<c.russian_destroy_chance then
                M.destroy(card)
            else
                return {message=localize('k_risk_survived'),colour=G.C.GREEN,card=card}
            end
        end
    end,
}
