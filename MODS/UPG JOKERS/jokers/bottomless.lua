return {
    key='bottomless',atlas='bottomless',name='Bottomless',
    cost_key='bottomless_cost',
    trigger='playing_cards_destroyed',evolution_message_key='k_upg_upgrade',
    initial_state={stage=1,stage_progress=0,accumulated_mult=0,seen_destroyed={}},
    stages={
        {loc_key='j_upg_hungry',sprite={x=0,y=0},growth_key='hungry_mult_per_destroyed',required_key='hungry_required_destroyed'},
        {loc_key='j_upg_starving',sprite={x=1,y=0},growth_key='starving_mult_per_destroyed',required_key='starving_required_destroyed'},
        {loc_key='j_upg_devourer',sprite={x=2,y=0},growth_key='devourer_mult_per_destroyed',xmult_key='devourer_xmult',final=true},
    },
    effect=function(state,stage,config)
        -- Native Joker scoring applies additive Mult before multiplicative Mult.
        return {mult=state.accumulated_mult,x_mult=stage.xmult_key and config[stage.xmult_key] or nil}
    end,
    loc_vars=function(state,stage,config)
        return {config[stage.growth_key],state.accumulated_mult,state.stage_progress,
            stage.required_key and config[stage.required_key] or 0,config.devourer_xmult,config.starving_required_destroyed}
    end,
}
