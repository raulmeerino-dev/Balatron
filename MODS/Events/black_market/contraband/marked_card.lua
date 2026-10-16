return function(B,C)
 C.register('marked_card',12,{targets=true,
 can=function(card)
  if #C.targets('marked_card',card)==0 then return false end
  for _,key in ipairs(get_current_pool('Seal')) do if key~='UNAVAILABLE' then return true end end
  return false
 end,
 apply=function(source,target)
  local enhancement=SMODS.poll_enhancement{key='evt_cb_marked',guaranteed=true,options=B.pool('Enhanced')}
  local seal=SMODS.poll_seal{key='evt_cb_marked',guaranteed=true}
  target:set_ability(G.P_CENTERS[enhancement]);target:set_seal(seal,true);target:juice_up()
 end})
end
