return {
    key='glass_cannon',name='Glass Cannon',cost_key='glass_cannon_cost',
    mult=function(s,c) return c.glass_cannon_xmult end,
    vars=function(s,c) return {c.glass_cannon_xmult} end,
    secondary=function(card,context,c,M) return M.first_hand(card,context) end,
}
