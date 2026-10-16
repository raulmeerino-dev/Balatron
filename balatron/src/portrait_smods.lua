local M = {}
function M.capture()
    M.blind_debuff=G.FUNCS.HUD_blind_debuff
    M.change_collab=G.FUNCS.change_collab
end
function M.apply()
    if not (SMODS and SMODS.Joker) then return end

    -- SMODS replaces Card.draw; keep the same foreground pass as the base game.
    local draw_card = Card.draw
    function Card:draw(...)
        if self:is_portrait_consumable_focus() and G.portrait_foreground_card ~= self then return end
        return draw_card(self, ...)
    end

    local build_mod_tag = buildModtag
    if build_mod_tag then
        buildModtag = function(...)
            local ui = build_mod_tag(...)
            local function bind(node)
                local object = node.config and node.config.object
                if object and object.hover then portrait_bind_tag_tooltip(object) end
                for _,child in ipairs(node.nodes or {}) do bind(child) end
            end
            bind(ui)
            return ui
        end
    end

    -- Steamodded replaces the vanilla booster builders, so it must share the
    -- portrait resolver as well. All selection, pricing and pack effects stay native.
    local create_pack = SMODS.Booster.create_UIBox
    function SMODS.Booster:create_UIBox(...)
        if G.F_PORTRAIT then
            local count = math.max(1,SMODS.OPENED_BOOSTER.ability.extra+(G.GAME.modifiers.booster_size_mod or 0))
            return portrait_pack_ui(count,localize(self.group_key or ('k_booster_group_'..self.key)))
        end
        return create_pack(self,...)
    end
    local update_pack = SMODS.Booster.update_pack
    function SMODS.Booster:update_pack(dt)
        local opening = not G.STATE_COMPLETE
        local result = update_pack(self,dt)
        if G.F_PORTRAIT then
            if G.shop then G.shop.alignment.offset.y=G.ROOM.T.h+11 end
            if opening then
                G.E_MANAGER:add_event(Event{trigger='immediate',func=function()
                    if G.booster_pack then portrait_anchor_run_panel(G.booster_pack,true) end
                    return true
                end})
            end
        end
        return result
    end
    -- Vanilla pack definitions take ownership with explicit copies of these two
    -- methods before local mods load. Update only definitions using those defaults.
    for _,booster in pairs(SMODS.Booster.obj_table) do
        if booster.set=='Booster' then
            if booster.create_UIBox==create_pack then booster.create_UIBox=SMODS.Booster.create_UIBox end
            if booster.update_pack==update_pack then booster.update_pack=SMODS.Booster.update_pack end
        end
    end

    require('portrait_save_migration').install()
    require('portrait_unlocks').install()
    -- Menus can be opened immediately after Continue, before the title menu
    -- has rebuilt its buttons. Install portrait adapters at loader completion.
    portrait_hook_smods_mod_list()
    require('portrait_mod_info').install()
    require('portrait_mod_selection').install()
    if IncJoker and PortraitGameplay then require('expansion48.jokers').install() end
    if PortraitHorizons then PortraitHorizons.install() end
    require('portrait_popup_layout').install_creators()
    portrait_hook_smods_collection()
    portrait_default_smods_run_select()
    G.FUNCS.HUD_blind_debuff=M.blind_debuff
    G.FUNCS.change_collab=M.change_collab
    local front_info=get_front_spriteinfo
    get_front_spriteinfo=function(front,card)
        local atlas,pos=CardSkins.front(front,card)
        if atlas then return atlas,pos end
        return front_info(front)
    end
    local set_sprites=Card.set_sprites
    function Card:set_sprites(center,front)
        front=front or (center and self.config.card and self.config.card.suit and self.config.card)
        set_sprites(self,center,front)
        if self.children.front and front then
            local atlas,pos=CardSkins.front(front,self)
            if atlas then self.children.front.atlas=atlas; self.children.front:set_sprite_pos(pos) end
        end
        CardSkins.refresh_back(self)
    end
    SMODS.juice_up_blind=function()
        if G.HUD_blind then
            for i=1,2 do
                local e=G.HUD_blind:get_UIE_by_ID('HUD_blind_debuff_'..i)
                if e then e:juice_up(0.3,0) end
            end
        end
        if G.GAME.blind then G.GAME.blind:juice_up() end
    end
end
return M
