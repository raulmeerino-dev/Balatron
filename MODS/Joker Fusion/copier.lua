return function(F,P)
    -- Audited scoring-only targets. Never execute an arbitrary mod's callback
    -- merely to discover whether its return value looks numeric.
    local safe={}
    for _,key in ipairs({'joker','greedy_joker','lusty_joker','wrathful_joker','gluttenous_joker',
        'jolly','zany','mad','crazy','droll','sly','wily','clever','devious','crafty',
        'half','banner','summit','abstract','even_steven','odd_todd','scholar','scary_face',
        'blue_joker','fibonacci','blackboard','arrowhead','onyx_agate','bloodstone',
        'the_duo','the_trio','the_family','the_order','the_tribe','stuntman','steel_joker',
        'incj_sniper','incj_second_course','incj_tax_collector','incj_hipster','incj_world_record',
        'incj_excessive_force','incj_collector','incj_olympico','incj_compound_interest',
        'risk_loan_shark','risk_overheated','risk_greed','risk_russian_joker','risk_burning_fuse',
        'risk_all_or_nothing','risk_glass_cannon','fuse_midas','fuse_last_meal','fuse_banana_cannon','fuse_glitch'}) do
        safe['j_'..key]=true
    end
    local additive={chips=true,chip_mod=true,mult=true,mult_mod=true,dollars=true,p_dollars=true}
    local multiplicative={x_mult=true,xmult=true,Xmult_mod=true,x_chips=true,xchips=true,Xchip_mod=true}
    function F.scale_copy(effect,efficiency)
        if not effect then return end
        local result={};local present=false
        for key,value in pairs(effect) do
            if type(value)=='number' and value==value and math.abs(value)<math.huge then
                if additive[key] and value>0 then
                    local amount=value*efficiency
                    if key=='dollars' or key=='p_dollars' then amount=math.floor(amount) end
                    if amount>0 then result[key]=amount;present=true end
                elseif multiplicative[key] and value>1 then
                    result[key]=1+(value-1)*efficiency;present=true
                end
            end
        end
        if present then return result end
    end
    local function right(card)
        for i,v in ipairs(G.jokers.cards) do if v==card then return G.jokers.cards[i+1] end end
    end
    local function target(card)
        local t,seen=right(card),{[card]=true}
        while t and (t.config.center.key=='j_blueprint' or t.config.center.key=='j_brainstorm') do
            if t.debuff or seen[t] then return end
            seen[t]=true
            if t.config.center.key=='j_blueprint' then
                t=right(t)
            else
                t=G.jokers.cards[1]
            end
        end
        if t and not t.debuff and not seen[t] and not t.getting_sliced then return t end
    end
    SMODS.Atlas{key='broken_copier',path='broken_copier.png',px=71,py=95}
    SMODS.Joker{key='broken_copier',atlas='broken_copier',pos={x=0,y=0},rarity='fuse_fusion',cost=12,
        unlocked=true,discovered=false,blueprint_compat=true,eternal_compat=true,perishable_compat=true,
        in_pool=function() return false end,config={extra={efficiency=50}},
        loc_vars=function(_,q,card)
            local t=G.jokers and target(card)
            local compatible=t and (safe[t.config.center.key] or t.config.center.key=='j_golden')
            return {vars={card.ability.extra.efficiency,localize(compatible and 'k_compatible' or 'k_incompatible')}}
        end,
        calculate=function(_,card,c)
            if card.debuff then return end
            local s=card.ability.extra
            local t=target(card)
            if P.won(c) and card.area==G.jokers and not card.getting_sliced and P.once(s,'last_win',P.token()) then
                -- The money copy uses the efficiency in force during this blind.
                local money=t and t.config.center.key=='j_golden' and math.floor(t.ability.extra*s.efficiency/100) or 0
                if c.beat_boss and s.efficiency<100 then
                    s.efficiency=math.min(100,s.efficiency+10)
                    card_eval_status_text(card,'extra',nil,nil,nil,{message=s.efficiency..'%',colour=G.C.GOLD})
                end
                if money>0 then ease_dollars(money,true);return {message='+$'..money,colour=G.C.MONEY,card=card} end
            end
            if not (c.joker_main or (c.individual and c.cardarea==G.play)) or not t or not safe[t.config.center.key] then return end
            local effect=F.scale_copy(SMODS.blueprint_effect(card,t,c),s.efficiency/100)
            if effect then effect.card=c.blueprint_card or card;return effect end
        end}
end
