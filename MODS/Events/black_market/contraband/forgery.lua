return function(B,C)
 C.register('forgery',18,{targets=true,can=function(card) return #C.targets('forgery',card)>0 end,
 apply=function(source,target)
  local card=copy_card(target);card:add_to_deck();G.consumeables:emplace(card);card:start_materialize()
 end})
end
