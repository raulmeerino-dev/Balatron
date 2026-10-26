return function(H)
 local X=H.X
 local classes={challenges='Challenge',bosses='Boss Blind',vouchers='Voucher',tags='Tag',packs='Booster',decks='Deck'}
 function H.info(id,reveal)
  local d=H.meta[id];local unlocked=H.unlocked(id)
  return {title=(unlocked or reveal) and H.text(d.name,d.name_en) or localize('k_locked'),
   text={(unlocked or reveal) and H.text(d.effect,d.effect_en or d.effect) or H.text(d.unlock,d.unlock_en or d.unlock)},
   class=classes[d.category],secondary=not unlocked and {H.text('Requisito de desbloqueo','Unlock requirement')} or nil}
 end
 function H.icon(id,size,reveal)
  local d=H.meta[id];size=size or 1.5
  local c=G.P_CENTERS[d.key] or G.P_TAGS[d.key] or G.P_BLINDS[d.key]
  local atlas=c and c.atlas;local pos=c and c.pos or {x=0,y=0}
  if not atlas and d.category=='challenges' then atlas='hz_'..d.key..'_art' end
  if not reveal and not H.unlocked(id) then atlas='Joker';pos=G.j_undiscovered and G.j_undiscovered.pos or {x=0,y=0} end
  if not G.ASSET_ATLAS[atlas or ''] then return H.P.text(H.text(d.name,d.name_en),0.26) end
  local square=d.category=='tags' or d.category=='bosses'
  return PortraitRunGallery.sprite(atlas,pos,square and size or size*71/95,size)
 end
 local old=X.notice_definition
 X.notice_definition=function(id)
  if not H.meta[id] then return old and old(id) end
  local d=H.meta[id]
  local description={n=G.UIT.R,config={align='cm',padding=0.12,maxw=7},nodes={}}
  description.nodes[#description.nodes+1]=H.P.text(H.text('Misión cumplida','MISSION COMPLETE'),0.3)
  for _,line in ipairs(H.lines(H.text(d.unlock,d.unlock_en or d.unlock),38)) do
   description.nodes[#description.nodes+1]=H.P.text(line,0.28)
  end
  local heading=d.category=='packs' and H.text('Sobre desbloqueado','Booster Unlocked')
   or d.category=='contracts' and H.text('Contrato desbloqueado','Contract Unlocked')
   or d.category=='contraband' and H.text('Contrabando desbloqueado','Contraband Unlocked')
   or H.text('Contenido desbloqueado','Content Unlocked')
  return create_UIBox_card_unlock(nil,{heading=heading,sprite=H.icon(id,1.8,true),description=description})
 end
 H.installers[#H.installers+1]=function()
  -- Booster localization belongs to Other in SMODS, including its unlock text.
  -- Native locked card UI otherwise attempts the nonexistent Booster loc set.
  for id,d in pairs(H.meta) do if d.category=='packs' then
   local center=G.P_CENTERS[d.key]
   local locked=center.locked_loc_vars
   center.locked_loc_vars=function(self,...)
    local result=locked and locked(self,...) or {};result.set=result.set or 'Other';return result
   end
  end end
  local popup=create_UIBox_blind_popup
  function create_UIBox_blind_popup(blind,discovered,...)
   if blind.horizons and not H.unlocked(blind.horizons) then
    return require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(H.info(blind.horizons)))
   end
   return popup(blind,discovered,...)
  end
  local tag_info=Tag.get_uibox_table
  function Tag:get_uibox_table(sprite,...)
   local r=tag_info(self,sprite,...);local obj=G.P_TAGS[self.key]
   if obj and obj.horizons and not H.unlocked(obj.horizons) then
    local s=sprite or self.tag_sprite
    -- Preserve the complete native AUT contract (card_type and badges included).
    local aut=s.ability_UIBox_table
    -- Native names own DynaText objects. Replacing their nodes without removing
    -- those objects leaves the undiscovered name drawn at the screen origin.
    local function discard(nodes)
     for _,node in ipairs(nodes or {}) do if type(node)=='table' then
      if node.n==G.UIT.O and node.config and node.config.object then node.config.object:remove()
      elseif node.nodes then discard(node.nodes) else discard(node) end
     end end
    end
    discard(aut.name);discard(aut.main);discard(aut.info)
    aut.name={{n=G.UIT.T,config={text=localize('k_locked'),colour=G.C.WHITE,scale=0.4}}}
    aut.main=require('portrait_tooltips').rows(H.info(obj.horizons),5)
    aut.info={};aut.type={};aut.card_type='Locked';aut.badges={}
   end
   return r
  end
  local discover=discover_card
  function discover_card(center,...)
   if center and center.horizons then X.discover(center.horizons) end
   return discover(center,...)
  end
  local start=G.FUNCS.can_start_run
  G.FUNCS.can_start_run=function(e,...)
   local r=start(e,...)
   local selected=G.GAME and G.GAME.viewed_back
   local c=selected and selected.effect and selected.effect.center
   if c and c.horizons and not H.enabled('decks',c.horizons) then e.config.button=nil;e.config.colour=G.C.UI.BACKGROUND_INACTIVE end
   return r
  end
 end
end
