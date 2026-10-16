return function(B,C)
 C.register('inside_information',11,{can=function() return C.shop.can_preview() end,
 choices=function(card) return C.shop.preview(card) end,
 valid=function(card,choice) return C.shop.valid(choice) end,
 apply=function(card,choice) C.shop.reserve(choice) end})
end
