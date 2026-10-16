return function(B,C)
 C.register('hot_merchandise',20,{can=function() return C.space(nil,G.jokers) and #C.choice_pool('hot_merchandise')>0 end,
 choices=function() return C.joker_choices('hot_merchandise') end,valid=C.joker_valid,apply=C.take_joker})
end
