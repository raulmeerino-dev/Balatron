return function(B,C)
 C.register('dealers_choice',20,{can=function() return C.space(nil,G.jokers) and #C.choice_pool('dealers_choice')>0 end,
 choices=function() return C.joker_choices('dealers_choice') end,valid=C.joker_valid,apply=C.take_joker})
end
