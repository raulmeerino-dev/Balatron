return {
    key='burning_fuse',name='Burning Fuse',cost_key='burning_fuse_cost',
    initial_state=function(c) return {xmult=c.burning_fuse_initial_xmult} end,
    mult=function(s,c) return s.xmult end,
    vars=function(s,c) return {s.xmult,c.burning_fuse_decay,c.burning_fuse_min_xmult} end,
    secondary=function(card,context,c,M)
        if not M.won(card,context) then return end
        local s=card.ability.extra
        if s.xmult<=c.burning_fuse_min_xmult then
            M.destroy(card)
        else
            s.xmult=math.max(c.burning_fuse_min_xmult,s.xmult-c.burning_fuse_decay)
            return {message=localize{type='variable',key='a_xmult',vars={s.xmult}},colour=G.C.MULT,card=card}
        end
    end,
}
