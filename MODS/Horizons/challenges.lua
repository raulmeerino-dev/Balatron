return function(H)
 local C={};H.challenges=C
 local X,P=H.X,H.P
 function C.state() local s=H.state();if s then s.challenges=s.challenges or {};return s.challenges end end
 function C.active(id) return G.STAGE==G.STAGES.RUN and G.GAME and G.GAME.challenge==H.key(id) end
 local unlocks={
  CH01='Win a run after performing two distinct Fusion recipes.',
  CH02='Win a run carrying Greed through the last three Bosses without ending any of their hands in debt.',
  CH03='Win a run after destroying at least 15 playing cards, with at most 30 cards remaining.',
  CH04='Complete four different Contracts by the end of Ante 6 and win the run.',
  CH05='Win a run without buying or creating a Joker from the start of Ante 6.',
  CH06='Win a run using at least 12 consumables from at least three families.',
  CH07='Complete the vanilla X-ray Vision Challenge.',
  CH08='Win a run without disabling or replacing a Boss, defeating at least six distinct Bosses.'}
 local rules={
  CH01={'Solo funcionan los Jokers {C:attention}Fusion{}.','Empiezas con Abstract Joker y Misprint.'},
  CH02={'Empiezas con {C:money}$12{} y {C:attention}Greed anclado{}.','Terminar una mano con dinero negativo causa derrota.'},
  CH03={'Las compras de tienda son {C:money}gratis{},','pero cada una destruye una carta aleatoria del mazo.','Los rerolls conservan su precio.'},
  CH04={'Completa al menos {C:attention}1 Contract por Ante{}.','Recibes una oferta elegible al comenzar cada Ante.','Sin completar uno antes del jefe, pierdes.'},
  CH05={'Los Jokers obtenidos permanecen inactivos','hasta el comienzo del {C:attention}siguiente Ante{}.'},
  CH06={'Jokers y consumibles comparten {C:attention}5 espacios{}.','Las Editions Negative aportan su espacio nativo.'},
  CH07={'La identidad de las ofertas de tienda queda oculta','hasta comprarlas. Ves tipo, rareza y precio.'},
  CH08={'La habilidad del próximo jefe también se aplica','a las ciegas pequeña y grande de ese Ante.','Su objetivo y premio originales se conservan.'}}
 local rules_en={
  CH01={'Only {C:attention}Fusion Jokers{} function.','Start with Abstract Joker and Misprint.'},
  CH02={'Start with {C:money}$12{} and an {C:attention}anchored Greed{}.','Ending a hand with negative money loses the run.'},
  CH03={'Shop purchases are {C:money}free{}, but each','destroys a random playing card from your deck.','Rerolls retain their normal price.'},
  CH04={'Complete at least {C:attention}1 Contract per Ante{}.','Receive an eligible offer at the start of each Ante.','Lose if its Boss is defeated without completing one.'},
  CH05={'Obtained Jokers are inactive until','the beginning of the {C:attention}next Ante{}.'},
  CH06={'Jokers and consumables share {C:attention}5 slots{}.','Negative Editions contribute their native slot.'},
  CH07={'Shop identities stay hidden until bought.','Type, rarity and price remain visible.'},
  CH08={'The upcoming Boss ability also applies','to the Small and Big Blinds of that Ante.','Their original target and reward are preserved.'}}
 function C.available(id)
  if not H.enabled('challenges',id) then return false end
  if id=='CH01' then
   local f=PortraitFusion;local cfg=f and (G.STAGE==G.STAGES.RUN and f.config() or f.mod.config)
   return cfg and cfg.enabled and cfg.recipes.glitch~=false
  end
  if id=='CH02' then
   local r=RiskJokers and RiskJokers.registry;local cfg=r and (G.STAGE==G.STAGES.RUN and r.config() or r.mod.config)
   return cfg and r.entries.greed and r.entries.greed.art_available and cfg.enabled and cfg.jokers.greed and (cfg.risk_weights.greed or 0)>0
  end
  if id=='CH04' then
   local contracts=P.modules.contracts
   if not contracts then return false end
   local cfg=G.STAGE==G.STAGES.RUN and contracts.config() or contracts.mod.config
   if not cfg.enabled then return false end
   local kinds=cfg.contracts or {}
   return kinds.no_safety_net~=false or (kinds.clean_hands~=false and (cfg.clean_hands_blinds or 2)<=3)
  end
  return true
 end
 for n=1,8 do
  local id=string.format('CH%02d',n);local d=H.meta[id];d.unlock_en=unlocks[id];d.effect_en=table.concat(rules_en[id],' '):gsub('{.-}','')
  H.atlas(d.key..'_art','challenges/'..id..'.png')
  H.atlas(d.key..'_icon','challenges/'..id..'_icon.png',34,34)
  local modifiers={};local jokers={}
  if id=='CH01' then jokers={{id='j_abstract'},{id='j_misprint'}} end
  if id=='CH02' then jokers={{id='j_risk_greed'}};modifiers={{id='dollars',value=12}} end
  if id=='CH06' then modifiers={{id='joker_slots',value=5},{id='consumable_slots',value=5}} end
  SMODS.Challenge{key=d.key:gsub('^c_hz_',''),loc_txt={['en-us']={name=d.name_en},['es_ES']={name=d.name},['es_419']={name=d.name}},
   jokers=jokers,rules={custom={{id='hz_'..id}},modifiers=modifiers},
   unlocked=function()
    local p=G.PROFILES[G.SETTINGS.profile]
    return (p.all_unlocked or p.challenges_unlocked~=nil) and H.unlocked(id) and C.available(id)
   end}
 end
 local loc=H.mod.process_loc_text
 H.mod.process_loc_text=function(...)
  if loc then loc(...) end
  local es=G.SETTINGS.language:sub(1,2)=='es'
  for n=1,8 do local id=string.format('CH%02d',n);G.localization.misc.v_text['ch_c_hz_'..id]=es and rules[id] or rules_en[id] end
  G.localization.descriptions.Other.hz_hidden_offer={name=es and 'Oferta a ciegas' or 'Blind offer',text={es and 'Compra para revelar su identidad.' or 'Buy to reveal its identity.','#1#','#2#'}}
 end
 function C.anchored(card)
  return not C.teardown and C.active('CH02') and card and G.GAME.hz_greed_anchor==card.sort_id
 end
 function C.joker_debuff(card)
  if not card or not card.ability or card.ability.set~='Joker' then return end
  local key=card.config.center.key
  local furnace=C.active('CH01') and key:sub(1,7)~='j_fuse_' or nil
  local sources=card.ability.debuff_sources or {}
  if sources.hz_furnace~=furnace then SMODS.debuff_card(card,furnace,'hz_furnace') end
  local delayed=C.active('CH05') and card.ability.hz_activation_ante and G.GAME.round_resets.ante<card.ability.hz_activation_ante
  if sources.hz_made_to_order~=(delayed or nil) then SMODS.debuff_card(card,delayed or nil,'hz_made_to_order') end
 end
 local add=Card.add_to_deck
 function Card:add_to_deck(from_debuff,...)
  if not from_debuff and self.ability.set=='Joker' then
   if C.active('CH02') and not G.GAME.hz_greed_anchor and self.config.center.key=='j_risk_greed' then G.GAME.hz_greed_anchor=self.sort_id end
   if C.active('CH05') and self.ability.hz_activation_owner~=X.id(self) then
    self.ability.hz_activation_owner=X.id(self);self.ability.hz_activation_ante=G.GAME.round_resets.ante+1
   end
  end
  if C.hidden(self) then self.ability.hz_revealed=true end
  local r=add(self,from_debuff,...)
  if not from_debuff and self.area==G.jokers then C.joker_debuff(self) end
  return r
 end
 local eternal=SMODS.is_eternal
 function SMODS.is_eternal(card,trigger) return C.anchored(card) or eternal(card,trigger) end
 local sell=Card.can_sell_card
 function Card:can_sell_card(...) if C.anchored(self) then return false end;return sell(self,...) end
 for _,method in ipairs({'remove','start_dissolve','shatter'}) do
  local original=Card[method];Card[method]=function(self,...) if C.anchored(self) then return false end;return original(self,...) end
 end
 local remove=Card.remove_from_deck
 function Card:remove_from_deck(from_debuff,...) if C.anchored(self) and not from_debuff then return false end;return remove(self,from_debuff,...) end
 local remove_area=CardArea.remove_card
 function CardArea:remove_card(card,...) if self==G.jokers and C.anchored(card) then return nil end;return remove_area(self,card,...) end
 local ability=Card.set_ability
 function Card:set_ability(center,...) if C.anchored(self) and center~=self.config.center then return end;return ability(self,center,...) end
 local copy=copy_card
 function copy_card(other,target,...) if C.anchored(target) then return target end;return copy(other,target,...) end
 local edition=Card.set_edition
 function Card:set_edition(value,...)
  if C.anchored(self) and (value=='e_negative' or type(value)=='table' and value.negative) then return end
  return edition(self,value,...)
 end
 local delete=Game.delete_run
 function Game:delete_run(...) C.teardown=true;local r=delete(self,...);C.teardown=false;return r end
 function C.after_hand()
  local s=C.state();if not s then return end
  if C.active('CH02') and G.GAME.dollars<0 then s.failed=true end
  if H.challenge_deck_missions then H.challenge_deck_missions.after_hand() end
 end
 function C.failed()
  local s=C.state();if not s then return false end
  return s.failed==true
 end
 function C.end_round_failed()
  local s=C.state();if not s then return false end
  if C.active('CH04') and G.GAME.blind:get_type()=='Boss' and (not s.completed or not s.completed[G.GAME.round_resets.ante]) then return true end
  return C.failed()
 end
 H.on(function(c)
  if not P.real(c) then return end
  if c.exp48_contract_result and c.success then
   local s=C.state();s.completed=s.completed or {};s.completed[G.GAME.round_resets.ante]=true
  end
  if c.ante_change then
   G.E_MANAGER:add_event(Event{func=function() for _,card in ipairs(G.jokers.cards) do C.joker_debuff(card) end;return true end})
  end
 end)
 assert(SMODS.load_file('challenge_effects.lua'))()(H)
 assert(SMODS.load_file('challenge_ui.lua'))()(H)
end
