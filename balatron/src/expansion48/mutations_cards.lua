return function(X,A,P,M,R)
 local T=X.text
 function A.queue_enhancements()
  if A.enhancement_queued then return end
  A.enhancement_queued=true;local game=G.GAME
  G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
   local s=A.state()
   if G.GAME~=game or not s or not s.enhancement_choices[1] then A.enhancement_queued=nil;return true end
   if G.OVERLAY_MENU or G.CONTROLLER.locks.use or G.CONTROLLER.locked or G.STATE==G.STATES.PLAY_TAROT or
    G.STATE==G.STATES.HAND_PLAYED or G.STATE==G.STATES.DRAW_TO_HAND then return false end
   A.enhancement_queued=nil;A.actions.enhancements();return true
  end})
 end
 -- SMODS quantum enhancements run the original enhancement calculations,
 -- including native Seal/retrigger contexts, without cloning those effects.
 SMODS.optional_features.quantum_enhancements=true
 local changing=false
 local function propagate(card,property,value)
  if changing or not card.playing_card or not card.ability.exp48_lineage or not A.has('M08') then return end
  changing=true
  for _,other in ipairs(G.playing_cards or {}) do
   if other~=card and other.ability.exp48_lineage==card.ability.exp48_lineage and not other.removed then
    if property=='base' then other:set_base(value)
    elseif property=='enhancement' then
     other:set_ability(G.P_CENTERS[value[1]])
     other.ability.exp48_enhancement=value[2]
    elseif property=='seal' then other:set_seal(value,true,true)
    elseif property=='edition' then other:set_edition(value and copy_table(value),true,true) end
   end
  end
  changing=false;SMODS.enh_cache:clear()
 end
 local ability=Card.set_ability
 function Card:set_ability(center,initial,delay_sprites,...)
  local old=self.config and self.config.center
  local metadata={}
  for k,v in pairs(self.ability or {}) do if k:sub(1,6)=='exp48_' then metadata[k]=v end end
  local quantum=delay_sprites=='quantum' or SMODS.extra_enhancement_calc_in_progress
  local secondary=metadata.exp48_enhancement
  if not quantum and not changing and A.state() and A.has('M01') and self.playing_card and old and
    old.set=='Enhanced' and center.set=='Enhanced' and center.key~=old.key then
   if secondary and secondary~=center.key then
    local pending=A.state().enhancement_choices
    local found=false;for _,v in ipairs(pending) do if v.card==X.id(self) then found=true end end
    if not found then pending[#pending+1]={card=X.id(self),keys={old.key,secondary,center.key}} end
    A.save();A.queue_enhancements();return
   end
   secondary=old.key
  elseif not quantum and center.key=='c_base' then secondary=nil end
  local result=ability(self,center,initial,delay_sprites,...)
  if not quantum then
   for k,v in pairs(metadata) do self.ability[k]=v end
   self.ability.exp48_enhancement=secondary
   SMODS.enh_cache:clear()
   if self.playing_card and old and old.key~=center.key then propagate(self,'enhancement',{center.key,secondary}) end
  end
  return result
 end
 local enhancements=SMODS.get_enhancements
 function SMODS.get_enhancements(card,extra_only)
  local result=enhancements(card,extra_only)
  local key=card.ability and card.ability.exp48_enhancement
  if key and G.P_CENTERS[key] and (not extra_only or key~=card.config.center.key) then result[key]=true end
  return result
 end
 -- Stone remains rankless/suitless even alongside Wild, as the approved rule requires.
 local no_suit=SMODS.has_no_suit
 function SMODS.has_no_suit(card)
  if card.ability.exp48_enhancement and (card.ability.exp48_enhancement=='m_stone' or card.config.center.key=='m_stone') then return true end
  return no_suit(card)
 end
 A.actions.enhancements=function()
  local pending=A.state().enhancement_choices[1];if not pending then return A.open() end
  if not A.find(pending.card) then table.remove(A.state().enhancement_choices,1);A.save();return A.actions.enhancements() end
  local rows={P.text(A.label(A.find(pending.card))),P.text(T('Elige la mejora que sustituyes','Choose the Enhancement to replace'))}
  for i=1,2 do rows[#rows+1]=A.button(localize{type='name_text',set='Enhanced',key=pending.keys[i]},'replace_enhancement',i) end
  A.menu(T('Doble fondo','False Bottom'),rows,'exp48_mutations')
 end
 A.actions.replace_enhancement=function(i)
  local s=A.state();local p=s.enhancement_choices[1];if not p or (i~=1 and i~=2) then return end
  local card=A.find(p.card)
  if card then
   changing=true;card:set_ability(G.P_CENTERS[p.keys[3]]);card.ability.exp48_enhancement=p.keys[3-i];changing=false
   propagate(card,'enhancement',{card.config.center.key,card.ability.exp48_enhancement})
  end
  table.remove(s.enhancement_choices,1);SMODS.enh_cache:clear();A.save();A.close();P.schedule_offers()
 end
 for method,property in pairs({set_base='base',set_seal='seal',set_edition='edition'}) do
  local native=Card[method];local prop=property
  Card[method]=function(self,value,...)
   local result=native(self,value,...)
   if A.state() and self.ability then propagate(self,prop,value) end
   return result
  end
 end
 local copy=copy_card
 function copy_card(source,destination,...)
  local before=changing;changing=true
  local result=copy(source,destination,...);changing=before
  if result and source.playing_card and A.state() and A.has('M08') then
   local family=source.ability.exp48_lineage or X.id(source)
   source.ability.exp48_lineage=family;result.ability.exp48_lineage=family
  end
  return result
 end
 function X.swap_ranks(a,b)
  if SMODS.has_no_rank(a) or SMODS.has_no_rank(b) then return false end
  local ar,br=a.base.value,b.base.value
  if a.ability.exp48_lineage and a.ability.exp48_lineage==b.ability.exp48_lineage and A.has('M08') then return false end
  changing=true;SMODS.change_base(a,nil,br);SMODS.change_base(b,nil,ar);changing=false
  propagate(a,'base',a.config.card);propagate(b,'base',b.config.card)
  return true
 end
 -- Reorder the real engine phases, retaining the native per-phase repetitions.
 local areas=SMODS.get_card_areas
 function SMODS.get_card_areas(kind,...)
  local result=areas(kind,...)
  if kind=='playing_cards' and A.in_scoring and A.state() and A.has('M10') then
   local out={};if G.hand then out[#out+1]=G.hand end
   for _,area in ipairs(result) do if area~=G.hand then out[#out+1]=area end end
   return out
  end
  return result
 end
 -- A chosen hand changes both the classified hand and its scoring membership.
 local poker=G.FUNCS.get_poker_hand_info
 function G.FUNCS.get_poker_hand_info(cards)
  local name,display,hands,scoring,raw=poker(cards)
  local s=A.state();local chosen=s and s.interpretation
  if chosen and A.has('M05') and hands[chosen] and #hands[chosen]>0 then
   return chosen,localize(chosen,'poker_hands'),hands,hands[chosen][1],chosen
  end
  return name,display,hands,scoring,raw
 end
 local play=G.FUNCS.play_cards_from_highlighted
 G.FUNCS.play_cards_from_highlighted=function(e)
  local s=A.state()
  if s and s.enhancement_choices[1] then return A.actions.enhancements() end
  if s and A.has('M05') and not s.interpretation_confirmed then
   local _,_,hands=poker(G.hand.highlighted);local rows={}
   for _,key in ipairs(G.handlist) do if hands[key] and #hands[key]>0 then
    rows[#rows+1]=A.button(localize(key,'poker_hands'),'interpret',key)
   end end
   return A.menu(T('Libre interpretación','Open Interpretation'),rows,'exit_overlay_menu')
  end
  if s then s.interpretation_confirmed=nil end
  return play(e)
 end
 local discard=G.FUNCS.discard_cards_from_highlighted
 G.FUNCS.discard_cards_from_highlighted=function(e,hook,...)
  local s=A.state()
  if not hook and s and s.enhancement_choices[1] then return A.actions.enhancements() end
  return discard(e,hook,...)
 end
 A.actions.interpret=function(key)
  local _,_,hands=poker(G.hand.highlighted)
  if not A.has('M05') or not hands[key] or #hands[key]==0 then return end
  local s=A.state();s.interpretation=key;s.interpretation_confirmed=true
  G.FUNCS.exit_overlay_menu();G.FUNCS.play_cards_from_highlighted()
 end
 -- Base Mult is substituted before Blind changes and all scoring bonuses.
 local modify=Blind.modify_hand
 function Blind:modify_hand(cards,hands,name,mult,chips,...)
  local s=A.state()
  if s and A.has('M17') and s.previous_hand and s.previous_hand~=name and G.GAME.hands[s.previous_hand] then
   mult=G.GAME.hands[s.previous_hand].mult
  elseif s and A.has('M17') and s.previous_different and s.previous_hand==name and G.GAME.hands[s.previous_different] then
   mult=G.GAME.hands[s.previous_different].mult
  end
  return modify(self,cards,hands,name,mult,chips,...)
 end
 X.listen(function(c)
  local s=A.state();if not s or not P.real(c) then return end
  if c.setting_blind then s.previous_hand=nil;s.previous_different=nil;s.interpretation=nil end
  if c.initial_scoring_step then A.in_scoring=true end
  if c.after then
   A.in_scoring=nil
   if s.previous_hand~=c.scoring_name then s.previous_different=s.previous_hand end
   s.previous_hand=c.scoring_name;s.interpretation=nil
  end
 end)
end
