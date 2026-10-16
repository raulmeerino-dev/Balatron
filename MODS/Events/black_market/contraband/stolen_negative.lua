return function(B,C)
 C.register('stolen_negative',25,{targets=true,can=function(card) return #C.targets('stolen_negative',card)>0 end,
 apply=function(source,target) target:set_edition({negative=true},true);target:juice_up() end})
end
