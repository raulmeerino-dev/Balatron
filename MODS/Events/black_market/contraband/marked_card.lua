return function(B,C)
 C.register('marked_card',12,{targets=true,
 can=function(card)
  if #C.targets('marked_card',card)==0 then return false end
  for _,key in ipairs(get_current_pool('Seal')) do if key~='UNAVAILABLE' then return true end end
  return false
 end,
 apply=function(source,target,choice)
  assert(choice and choice.enhancement and choice.seal,'Marked Card requires its saved Enhancement and Seal choice')
  target:set_ability(G.P_CENTERS[choice.enhancement]);target:set_seal(choice.seal,true);target:juice_up()
 end})
end
