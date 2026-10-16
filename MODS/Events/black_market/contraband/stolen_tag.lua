return function(B,C)
 local function pool()
  local out={}
  for _,key in ipairs(get_current_pool('Tag')) do
   local tag=G.P_TAGS[key]
   if tag and not G.GAME.banned_keys[key] and B.registry.mod_enabled(tag) and SMODS.add_to_pool(tag,{source='contraband'}) then out[#out+1]=key end
  end
  return out
 end
 C.register('stolen_tag',16,{can=function() return #pool()>0 end,
 choices=function()
  local keys,out=pool(),{}
  for i=1,math.min(3,#keys) do local key=B.choose(keys,'stolen_tag');out[#out+1]={key=key}
   for n=#keys,1,-1 do if keys[n]==key then table.remove(keys,n) end end
  end
  return out
 end,
 valid=function(card,choice) for _,key in ipairs(pool()) do if key==choice.key then return true end end end,
 apply=function(source,choice) add_tag(Tag(choice.key));play_sound('generic1',1,0.5) end})
end
