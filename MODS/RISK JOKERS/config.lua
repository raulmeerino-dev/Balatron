return {
    enabled=true,loan_shark_cost=9,overheated_cost=8,
    jokers={russian_joker=true,burning_fuse=true,greed=true,glass_cannon=true,all_or_nothing=true},
    -- Relative family weights, not percentages; adding members does not increase them.
    risk_rarity_weight=0.01,
    risk_black_market_weight=0.05,
    risk_weights={russian_joker=1,burning_fuse=1,greed=1,glass_cannon=1,all_or_nothing=1},
    russian_xmult=4.0,russian_destroy_chance=0.08,russian_cost=10,
    burning_fuse_initial_xmult=6.0,burning_fuse_decay=0.5,burning_fuse_min_xmult=1.0,burning_fuse_cost=9,
    greed_xmult=3.0,greed_cost_per_scoring_hand=2,greed_cost=8,
    glass_cannon_xmult=5.0,glass_cannon_cost=10,
    all_or_nothing_initial_xmult=3.0,all_or_nothing_decay=0.5,all_or_nothing_min_xmult=1.0,all_or_nothing_cost=8,
}
