return {
    {id='clean_hands',duration='blinds',target='clean_hands_blinds',reward='cash_clean',
        event=function(a,e) if e=='discard' then a.failed=true elseif e=='win' then a.progress=a.progress+1 end end},
    {id='one_shot',duration='next_blind',target_value=1,reward='joker',
        event=function(a,e,d) if e=='win' then a.progress=d.hands==1 and 1 or 0;a.failed=d.hands~=1 end end},
    {id='monochrome',duration='next_blind',target_value=1,reward='mono',
        event=function(a,e,d) if e=='win' then a.progress=d.mono and 1 or 0;a.failed=not d.mono end end},
    {id='high_roller',duration='next_shop',target='high_roller_spend',reward='rerolls',
        event=function(a,e,d)
            if e=='spend' and d.shop==a.shop+1 then a.progress=a.progress+d.amount end
            if e=='leave_shop' and d.shop==a.shop+1 and a.progress<a.target then a.failed=true end
        end},
    {id='no_safety_net',duration='next_boss',target_value=1,reward='spectral',
        event=function(a,e,d)
            if e=='consume' and d.boss then a.failed=true end
            if e=='win' and d.boss then a.progress=1 end
        end},
    {id='execution',duration='ante',target='execution_cards',reward='cash_execution',
        event=function(a,e,d)
            if e=='destroy' then a.progress=a.progress+d.count end
            if e=='win' and d.boss and a.progress<a.target then a.failed=true end
        end},
    {id='debt_collector',duration='ante',target='debt_required',reward='cash_debt',
        event=function(a,e,d)
            if e=='ante_paid' then a.progress=math.max(0,d.money);a.failed=a.progress<a.target end
        end,
        success_condition=function(a,e) return e=='ante_paid' and a.progress>=a.target end},
}
