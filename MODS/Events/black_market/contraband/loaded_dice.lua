return function(B,C)
 C.register('loaded_dice',15,{can=function() return B.state().dice_ante~=G.GAME.round_resets.ante end,
 apply=function(card) B.state().dice_ante=G.GAME.round_resets.ante;C.refresh_status() end})
end
