return function(B,C)
 local function can()
  local g=G.GAME;local state=g.round_resets.blind_states.Boss
  return not G.FORCE_BOSS and not (g.perscribed_bosses and g.perscribed_bosses[g.round_resets.ante]) and
   state~='Defeated' and state~='Skipped' and state~='Current' and
   not (g.facing_blind and g.blind and g.blind:get_type()=='Boss') and
   (G.STATE==G.STATES.SHOP or G.STATE==G.STATES.BLIND_SELECT or G.STATE==G.STATES.SELECTING_HAND)
 end
 C.register('bribe',14,{can=can,
 choices=function()
  local g=G.GAME;local used,banned=g.bosses_used,g.banned_keys
  g.bosses_used=copy_table(used);g.banned_keys=copy_table(banned);g.banned_keys[C.boss()]=true
  local out={}
  -- Use the native/SMODS generator, including its minimum-use and ante rules.
  local ok,err=pcall(function()
   for i=1,3 do local key=get_new_boss();if not key then break end
    out[#out+1]={key=key,ante=g.round_resets.ante};g.banned_keys[key]=true
   end
  end)
  g.bosses_used=used;g.banned_keys=banned
  return out
 end,
 valid=function(card,choice) return can() and choice.ante==G.GAME.round_resets.ante and G.P_BLINDS[choice.key] and not G.GAME.banned_keys[choice.key] end,
 apply=function(source,choice)
  local g=G.GAME;g.round_resets.blind_choices.Boss=choice.key
  g.bosses_used[choice.key]=(g.bosses_used[choice.key] or 0)+1
  if G.blind_select then
   G.blind_select:remove();G.blind_select=nil
   if G.STATE==G.STATES.BLIND_SELECT or G.TAROT_INTERRUPT==G.STATES.BLIND_SELECT then G.STATE_COMPLETE=false end
  end
 end})
end
