function wrap(x, around)
    return (x - 1) % around + 1
end

MenuItem = Class()
Text = Class(MenuItem)
Back = Class(Text)
Close = Back -- FIXME
LinkTo = Class(Text)

Active = Class(Text)
Toggle = Class(Active)
Hold = Class(Active)
Oneshot = Class(Active)
Flags = Class(Active)

Screen = Class()
Menu = Class()

Callbacks = Class()

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
    local color = self.focused and 'yellow' or 'white'
    brush(0, y, color, self.text)
end

function Back:init()
    Text.init(self, 'back')
end
function Back:run()
    return nil -- FIXME
end

function LinkTo:init(text, submenu)
    Text.init(self, text)
    self.submenu = submenu
end
function LinkTo:run()
    return self.submenu
end

function Active:init(text, callbacks)
    self.text = text
    self.callbacks = callbacks or {}
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

--function Flags:init

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

    if pressed.down then i = i + 1 end
    if pressed.up then i = i - 1 end
    i = wrap(i, #self.items)
    self.item_sel = i

    local item = self.items[i]

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
