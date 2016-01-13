local function wrap(x, around)
    return (x - 1) % around + 1
end

local MenuItem = Class()
local Text = Class(MenuItem)
local Back = Class(Text)
local Close = Class(Text)
local LinkTo = Class(Text)

local Active = Class(Text)
local Toggle = Class(Active)
local Radio = Class(Active)
local Hold = Class(Active)
local Oneshot = Class(Active)

local Screen = Class()
local Menu = Class()

local Callbacks = Class()

local MenuHandler = Class()

function Callbacks:init()
    self.state = false
end
function Callbacks:on()
    self.state = true
end
function Callbacks:off()
    self.state = false
end
function Callbacks:hold()
end
function Callbacks:release()
end

local dummy = Callbacks()

function MenuItem:init()
    self.focused = false
end
function MenuItem:run()
    return self
end
function MenuItem:hold()
    self:release()
end
function MenuItem:focus()
    self.focused = true
end
function MenuItem:unfocus()
    self.focused = false
end
function MenuItem:release()
end
function MenuItem:draw(brush, y)
end

function Text:init(text)
    MenuItem.init(self)
    self.text = text
end
function Text:draw(brush, y)
    local color = 'cyan'
    if getindex(self) ~= Text then
        color = self.focused and 'yellow' or 'white'
    end
    brush(0, y, color, self.text)
end

function Back:init()
    Text.init(self, 'back')
end
function Back:run()
    return 'back'
end

function Close:init()
    Text.init(self, 'close')
end
function Close:run()
    return 'close'
end

function LinkTo:init(text, submenu)
    Text.init(self, text)
    self.submenu = submenu
end
function LinkTo:run()
    return self.submenu
end

function Active:init(text, callbacks)
    Text.init(self, text)
    if type(callbacks) == 'function' then
        local f = callbacks
        callbacks = Callbacks()
        function callbacks:on() f() end
        callbacks.hold = callbacks.on
    end
    self.callbacks = callbacks or dummy
end

function Toggle:init(text, callbacks)
    Active.init(self, text, callbacks)
    self.state = false
end
function Toggle:run()
    self.state = not self.state
    if self.state then
        self.callbacks:on(true)
    else
        self.callbacks:off(false)
    end
    return self
end
function Toggle:draw(brush, y)
    local color = self.focused and 'yellow' or 'white'
    brush(0, y, 'cyan', '[ ]')
    if self.state then
        brush(1, y, color, 'x')
    end
    brush(4, y, color, self.text)
end

function Radio:init(text, group, callbacks)
    Active.init(self, text, callbacks)
    self.state = #group == 0
    table.insert(group, self)
    self.group = group
end
function Radio:run()
    if self.state then
        -- we're already selected!
        self.callbacks:hold()
        return self
    end

    for _, active in pairs(self.group) do
        -- FIXME: shouldn't really be invading their namespace
        if active ~= self then
            active.state = false
            active.callbacks:off(false)
        end
    end

    self.state = true
    self.callbacks:on(true)
    return self
end
function Radio:draw(brush, y)
    local color = self.focused and 'yellow' or 'white'
    brush(0, y, 'cyan', '( )')
    if self.state then
        brush(1, y, color, 'x')
    end
    brush(4, y, color, self.text)
end

function Oneshot:run()
    self.callbacks:on()
    return self
end

function Hold:run()
    self:hold()
    return self
end
function Hold:hold()
    self.callbacks:hold()
end
function Hold:release()
    self.callbacks:release()
end

function Screen:init(items)
    self.items = items
    self.item_sel = 1
end

function Screen:focus()
    self.items[self.item_sel]:focus()
end

function Screen:unfocus()
    self.items[self.item_sel]:unfocus()
end

function Screen:navigate(ctrl, pressed)
    local i = self.item_sel
    local old = self.items[i]

    local direction
    if pressed.down then direction = 'down' end
    if pressed.up then direction = 'up' end

    local item
    for give_up = 0, 100 do
        if give_up >= 100 then
            error("couldn't find a suitable menu item to select", 1)
        end

        if direction == 'down' then i = i + 1 end
        if direction == 'up' then i = i - 1 end
        i = wrap(i, #self.items)
        self.item_sel = i
        item = self.items[i]

        if getindex(item) ~= Text then
            break
        elseif direction == nil then
            i = i + 1
        end
    end

    if item ~= old then
        old:unfocus()
        old:release()
        item:focus()
    end

    local focus = self
    if pressed.enter then
        focus = item:run()
    elseif ctrl.enter then
        item:hold()
    else
        item:release()
    end

    if focus == item then
        focus = self
    end

    return focus
end

function Screen:draw(brush, y)
    for i, item in ipairs(self.items) do
        item:draw(brush, y + i - 1)
    end
end

function Menu:init(screens)
    self.screens = screens
    self.screen_sel = 1
end

function Menu:focus()
    self.screens[self.screen_sel]:focus()
end

function Menu:unfocus()
    self.screens[self.screen_sel]:unfocus()
end

function Menu:navigate(ctrl, pressed)
    local s = self.screen_sel
    local old = self.screens[s]
    if pressed.left then s = s - 1 end
    if pressed.right then s = s + 1 end
    s = wrap(s, #self.screens)
    self.screen_sel = s

    local screen = self.screens[s]
    if screen ~= old then
        old:unfocus()
        screen:focus()
    end

    local focus = screen:navigate(ctrl, pressed)
    if focus == screen then focus = self end

    return focus
end

function Menu:draw(brush, y)
    self.screens[self.screen_sel]:draw(brush, y)
end

function MenuHandler:init(main_menu, brush)
    self.main_menu = main_menu
    self.backstack = {}
    self.brush = brush
    self.menu = nil
    self.hidden = nil
end

function MenuHandler:push(menu)
    table.insert(self.backstack, menu)
end

function MenuHandler:pop()
    return table.remove(self.backstack)
end

function MenuHandler:unhide()
    if not self.hidden then return end
    self.menu = self.hidden
    self.hidden = nil
end

function MenuHandler:navigate(new_menu)
    self:unhide()
    if new_menu ~= self.menu then
        if new_menu == 'back' then
            new_menu = self:pop()
        elseif new_menu == 'close' then
            self.backstack = {}
            new_menu = nil
        elseif new_menu == 'hide' then
            self.hidden = self.menu
            new_menu = nil
        elseif self.menu and new_menu ~= self.menu then
            self:push(self.menu)
            self.menu:unfocus()
        end
        if new_menu then new_menu:focus() end
    end
    self.menu = new_menu
end

function MenuHandler:update(ctrl, pressed)
    if self.hidden then
        if not pressed.enter then return end
        self:unhide()
    elseif not self.menu and pressed.enter then
        self:navigate(self.main_menu)
    elseif self.menu then
        local new_menu = self.menu:navigate(ctrl, pressed)
        self:navigate(new_menu)
    end
    if self.menu then self.menu:draw(self.brush, 0) end
end

return globalize{
    MenuItem = MenuItem,
    Text = Text,
    Back = Back,
    Close = Close,
    LinkTo = LinkTo,
    Active = Active,
    Toggle = Toggle,
    Radio = Radio,
    Hold = Hold,
    Oneshot = Oneshot,
    Screen = Screen,
    Menu = Menu,
    Callbacks = Callbacks,
    MenuHandler = MenuHandler,
    dummy = dummy,
}
