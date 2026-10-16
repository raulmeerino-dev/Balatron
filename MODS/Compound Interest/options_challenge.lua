-- A native Challenge; only its starting Options instance is permanently anchored.
return function(I)
    local C={key='c_incj_wake_up_neo',teardown=false}
    I.options_challenge=C
    function C.anchored(card)
        return not C.teardown and G.STAGE==G.STAGES.RUN and G.GAME and
            G.GAME.challenge==C.key and G.GAME.incj_options_anchor~=nil and card and card.sort_id==G.GAME.incj_options_anchor and
            card.config and card.config.center.key=='j_incj_options'
    end
    SMODS.Challenge{
        key='wake_up_neo',loc_txt={name='WAKE UP, NEO'},
        jokers={{id='j_incj_options'}},
        rules={custom={{id='incj_options_anchored'}},modifiers={}},
        unlocked=function()
            local p=G.PROFILES[G.SETTINGS.profile]
            -- Use the native Challenge-mode gate, independently of challenge completion order.
            return p.all_unlocked or p.challenges_unlocked~=nil
        end,
    }
    local add=Card.add_to_deck
    function Card:add_to_deck(...)
        if G.GAME and G.GAME.challenge==C.key and not G.GAME.incj_options_anchor and
            self.config.center.key=='j_incj_options' then
            G.GAME.incj_options_anchor=self.sort_id
        end
        return add(self,...)
    end
    local eternal=SMODS.is_eternal
    function SMODS.is_eternal(card,trigger)
        return C.anchored(card) or eternal(card,trigger)
    end
    local sell=Card.can_sell_card
    function Card:can_sell_card(...) if C.anchored(self) then return false end;return sell(self,...) end
    for _,method in ipairs({'remove','start_dissolve','shatter'}) do
        local original=Card[method]
        Card[method]=function(self,...) if C.anchored(self) then return false end;return original(self,...) end
    end
    local remove_deck=Card.remove_from_deck
    function Card:remove_from_deck(from_debuff,...)
        if C.anchored(self) and not from_debuff then return false end
        return remove_deck(self,from_debuff,...)
    end
    local remove_area=CardArea.remove_card
    function CardArea:remove_card(card,...)
        if self==G.jokers and C.anchored(card) then return nil end
        return remove_area(self,card,...)
    end
    local ability=Card.set_ability
    function Card:set_ability(center,...)
        if C.anchored(self) and center~=self.config.center then return end
        return ability(self,center,...)
    end
    local copy=copy_card
    function copy_card(other,target,...)
        if C.anchored(target) then return target end
        return copy(other,target,...)
    end
    local edition=Card.set_edition
    function Card:set_edition(value,...)
        if C.anchored(self) and (value=='e_negative' or (type(value)=='table' and value.negative)) then return end
        return edition(self,value,...)
    end
    local delete=Game.delete_run
    function Game:delete_run(...)
        C.teardown=true;local result=delete(self,...);C.teardown=false;return result
    end
end
