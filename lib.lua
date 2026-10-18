local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

-- Helpers de type d'input (pattern Library 5)
local function IsMouseInput(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch;
end;
local function IsClickInput(Input)
    return IsMouseInput(Input)
        and Input.UserInputState == Enum.UserInputState.Begin;
end;
local function IsDragInput(Input)
    return IsMouseInput(Input)
        and (Input.UserInputState == Enum.UserInputState.Begin
            or Input.UserInputState == Enum.UserInputState.Change);
end;

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

--============================================================
--  Tween helper (TweenService)
--============================================================
local TweenConfig = {
    Toggle = 0.20;
    Slider = 0.15;
    Dropdown = 0.18;
    Hover = 0.12;
};

local function Tween(Object, Time, Properties, EasingStyle, EasingDirection)
    if (not Object) or (not Object.Parent) then return end;

    local Info = TweenInfo.new(
        Time or 0.2,
        EasingStyle or Enum.EasingStyle.Quad,
        EasingDirection or Enum.EasingDirection.Out
    );

    local Ok, TweenObj = pcall(function()
        return TweenService:Create(Object, Info, Properties);
    end);

    if Ok and TweenObj then
        TweenObj:Play();
    else
        for Prop, Val in next, Properties do
            Object[Prop] = Val;
        end;
    end;

    return TweenObj;
end

--============================================================
--  Mobile / touch helpers
--============================================================
local IsMobile = (InputService.TouchEnabled and not InputService.MouseEnabled);
local IsTouch = (InputService.TouchEnabled or InputService.GamepadEnabled);

-- agrandit les zones tactiles (un doigt ≠ une souris)
local function TouchPad(Height)
    return IsMobile and math.max(Height, 26) or Height;
end;

-- garde un frame dans l'écran (mobile : ColorPicker / Dropdown)
local function ClampToScreen(Position, Size)
    local Cam = workspace.CurrentCamera;
    local VP = (Cam and Cam.ViewportSize.X > 0) and Cam.ViewportSize or ScreenGui.AbsoluteSize;

    local W = Size and Size.X.Offset or 0;
    local H = Size and Size.Y.Offset or 0;

    return UDim2.fromOffset(
        math.clamp(Position.X.Offset, 4, math.max(4, VP.X - W - 4)),
        math.clamp(Position.Y.Offset, 4, math.max(4, VP.Y - H - 4))
    );
end;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(20, 20, 20);
    BackgroundColor = Color3.fromRGB(12, 12, 12);
    AccentColor = Color3.fromRGB(255, 255, 255);
    AccentColorDark = Color3.fromRGB(160, 160, 160);
    OutlineColor = Color3.fromRGB(40, 40, 40);
    RiskColor = Color3.fromRGB(255, 50, 50);

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Code;
    FontFace = nil;
    CustomFontUrl = 'https://github.com/kiciahook-org/v3-assets/raw/refs/heads/main/Minecraftia-Regular.ttf';
    CustomFontName = 'Minecraftia-Regular.ttf';

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    Icons = {
        Rage = 'rbxassetid://18484264435',
        Combat = 'rbxassetid://18484264435',
        Legit = 'rbxassetid://7733765307',
        AntiAim = 'rbxassetid://7734056608',
        ['Anti-Aim'] = 'rbxassetid://7734056608',
        Visual = 'rbxassetid://7733774602',
        visual = 'rbxassetid://7733774602',
        Visuals = 'rbxassetid://7733774602',
        visuals = 'rbxassetid://7733774602',
        Misc = 'rbxassetid://7734053495',
        misc = 'rbxassetid://7734053495',
        Settings = 'rbxassetid://7734053495',
        settings = 'rbxassetid://7734053495',
        gear = 'rbxassetid://7734053495',
        wrench = 'rbxassetid://7734053495',
        ['UI Settings'] = 'rbxassetid://7734053495',
        Configs = 'rbxassetid://7733799901',
        Config = 'rbxassetid://7733799901',
        Players = 'rbxassetid://7743876054',
        players = 'rbxassetid://7743876054',
        Profile = 'rbxassetid://7743876054',
        Default = 'rbxassetid://7734053495',
        crosshair = 'rbxassetid://7733765307',
        Crosshair = 'rbxassetid://7733765307',
        Aimbot = 'rbxassetid://7733765307',
        aimbot = 'rbxassetid://7733765307',
        eye = 'rbxassetid://7733774602',
        Eye = 'rbxassetid://7733774602',
        ESP = 'rbxassetid://7733774602',
        esp = 'rbxassetid://7733774602',
        circle = 'rbxassetid://5881046614',
        FOV = 'rbxassetid://5881046614',
        maximize = 'rbxassetid://5881046614',
        skin = 'rbxassetid://7734056672',
        Skin = 'rbxassetid://7734056672',
        ['Skin Changer'] = 'rbxassetid://7734056672',
        shirt = 'rbxassetid://7734056672',
    };
    ShowCustomCursor = false;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if Library.FontFace and (_Instance:IsA('TextLabel') or _Instance:IsA('TextBox') or _Instance:IsA('TextButton')) then
        pcall(function()
            _Instance.FontFace = Library.FontFace;
        end);
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    if Library.FontFace then
        pcall(function()
            _Instance.FontFace = Library.FontFace;
        end);
    end;

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, DragFrame, Cutoff)
    if type(DragFrame) == 'number' then
        Cutoff = DragFrame;
        DragFrame = Instance;
    end;
    DragFrame = DragFrame or Instance;

    Instance.Active = true;
    DragFrame.Active = true;

    DragFrame.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
            and Input.UserInputType ~= Enum.UserInputType.Touch then
            return;
        end;

        local startInputPos = Vector2.new(Input.Position.X, Input.Position.Y);
        local relY = startInputPos.Y - Instance.AbsolutePosition.Y;

        local effectiveCutoff = Cutoff;
        if effectiveCutoff and Input.UserInputType == Enum.UserInputType.Touch then
            effectiveCutoff = math.max(effectiveCutoff, 45);
        end;

        if effectiveCutoff and (relY > effectiveCutoff or relY < 0) then
            return;
        end;

        local startFramePos = Instance.Position;
        local activeInput = Input;
        local dragging = true;

        local moveConn
        local endConn

        local function Disconnect()
            dragging = false;
            if moveConn then moveConn:Disconnect(); moveConn = nil; end;
            if endConn then endConn:Disconnect(); endConn = nil; end;
        end;

        moveConn = InputService.InputChanged:Connect(function(moveInput)
            if not dragging then return end;

            local isMatch = false;
            if activeInput.UserInputType == Enum.UserInputType.Touch then
                isMatch = (moveInput == activeInput)
                    or (moveInput.UserInputType == Enum.UserInputType.Touch);
            else
                isMatch = (moveInput == activeInput)
                    or (moveInput.UserInputType == Enum.UserInputType.MouseMovement);
            end;

            if isMatch and moveInput.Position then
                local currentPos = Vector2.new(moveInput.Position.X, moveInput.Position.Y);
                local delta = currentPos - startInputPos;

                Instance.Position = UDim2.new(
                    startFramePos.X.Scale,
                    startFramePos.X.Offset + delta.X,
                    startFramePos.Y.Scale,
                    startFramePos.Y.Offset + delta.Y
                );
            end;
        end);

        endConn = InputService.InputEnded:Connect(function(endInput)
            if endInput == activeInput
                or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and endInput.UserInputType == Enum.UserInputType.MouseButton1)
                or (activeInput.UserInputType == Enum.UserInputType.Touch and endInput.UserInputType == Enum.UserInputType.Touch) then
                Disconnect();
            end;
        end);

        activeInput.Changed:Connect(function()
            if activeInput.UserInputState == Enum.UserInputState.End
                or activeInput.UserInputState == Enum.UserInputState.Cancel then
                Disconnect();
            end;
        end);
    end);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 4);
        Parent = Tooltip;
    });

    Library:Create('UIStroke', {
        Color = Library.OutlineColor;
        Thickness = 1;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Parent = Tooltip;
    });

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        local Goal = {};

        for Property, ColorIdx in next, Properties do
            Goal[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;

        if TweenConfig.Hover > 0 then
            Tween(Instance, TweenConfig.Hover, Goal);
        else
            for Property, Value in next, Goal do
                Instance[Property] = Value;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        local Goal = {};

        for Property, ColorIdx in next, PropertiesDefault do
            Goal[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;

        if TweenConfig.Hover > 0 then
            Tween(Instance, TweenConfig.Hover, Goal);
        else
            for Property, Value in next, Goal do
                Instance[Property] = Value;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame(PX, PY)
    local X = PX or Mouse.X;
    local Y = PY or Mouse.Y;
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if X >= AbsPos.X and X <= AbsPos.X + AbsSize.X
            and Y >= AbsPos.Y and Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame, PX, PY)
    local X = PX or Mouse.X;
    local Y = PY or Mouse.Y;
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

    if X >= AbsPos.X and X <= AbsPos.X + AbsSize.X
        and Y >= AbsPos.Y and Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        if Object and Object.Instance and Object.Instance.Parent then
            for Property, ColorIdx in next, Object.Properties do
                pcall(function()
                    if type(ColorIdx) == 'string' and Library[ColorIdx] ~= nil then
                        Object.Instance[Property] = Library[ColorIdx];
                    elseif type(ColorIdx) == 'function' then
                        Object.Instance[Property] = ColorIdx()
                    end
                end)
            end;
        end;
    end;
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    pcall(function()
        for _, obj in ipairs(game:GetService('Lighting'):GetChildren()) do
            if obj:IsA('BlurEffect') and (obj.Name == 'GlassBlur' or obj.Size == 18) then
                obj:Destroy()
            end
        end
    end);

    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        -- local Container = self.Container;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, IsMobile and 34 or 24, 0, IsMobile and 22 or 12);
            LayoutOrder = 2;
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = ClampToScreen(UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18), UDim2.fromOffset(230, Info.Transparency and 271 or 253)),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = ClampToScreen(UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18), PickerFrameOuter.Size);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

                        ColorPicker:Display();

                        RenderStepped:Wait();
                    end;

                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);

            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18;
                    if (Label.TextBounds.X > XSize) then
                        XSize = Label.TextBounds.X
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
                Obj.Color = Props.Color or Props.BackgroundColor3 or (Props.Primary and Color3.fromRGB(110, 230, 110))
                Obj.TextColor = Props.TextColor or Props.TextColor3 or (Props.Primary and Color3.fromRGB(18, 18, 18))
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, 0, 0, IsMobile and 28 or 22);
                ZIndex = 5;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 3);
                Parent = Outer;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Button.Color or Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 3);
                Parent = Inner;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 13;
                Text = Button.Text;
                TextColor3 = Button.TextColor or Library.FontColor;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 195, 195))
                });
                Rotation = 90;
                Parent = Inner;
            });

            Library:Create('UIStroke', {
                Color = Library.OutlineColor;
                Thickness = 1;
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });

            if not Button.Color then
                Library:AddToRegistry(Inner, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
            end;

            if not Button.TextColor then
                Library:AddToRegistry(Label, {
                    TextColor3 = 'FontColor';
                });
            end;

            Library:OnHighlight(Outer, Inner,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'OutlineColor' }
            );

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                task.spawn(function()
                    Button.Label.TextColor3 = Library.AccentColor
                    task.wait(0.12)
                    Button.Label.TextColor3 = Library.FontColor
                end)

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, IsMobile and 28 or 22)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 4, 0, 0)
            SubButton.Outer.Size = UDim2.new(1, 0, 1, 0)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 3);
            Parent = ToggleOuter;
        });

        local ToggleScale = Instance.new('UIScale', ToggleOuter);
        ToggleScale.Scale = 1;

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 3);
            Parent = ToggleInner;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        local function UpdateToggleLabelSize()
            local w = Container.AbsoluteSize.X > 0 and Container.AbsoluteSize.X or 240;
            ToggleLabel.Size = UDim2.new(0, math.max(160, w - 24), 1, 0);
        end;
        UpdateToggleLabelSize();
        Container:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateToggleLabelSize);

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            AnchorPoint = Vector2.new(0, 0.5);
            Position = UDim2.new(0, 0, 0.5, 0);
            Size = UDim2.new(0, 170, 0, TouchPad(26));
            ZIndex = 8;
            Active = true;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        local function AttachTooltip(str)
            local TooltipButton = Library:CreateLabel({
                Size = UDim2.new(0, 16, 1, 0);
                Text = '[?]';
                TextColor3 = Library.AccentColor;
                TextSize = 12;
                Font = Library.Font;
                LayoutOrder = 1;
                ZIndex = 7;
                Parent = ToggleLabel;
            });
            Library:AddToolTip(str, TooltipButton);
            Library:AddToolTip(str, ToggleRegion);
        end;

        if type(Info.Tooltip) == 'string' then
            AttachTooltip(Info.Tooltip);
        end;

        function Toggle:AddTooltip(str)
            if type(str) == 'string' then
                AttachTooltip(str);
            end;
            return self;
        end;

        function Toggle:Display()
            local TargetBg = Toggle.Value and Library.AccentColor or Library.MainColor;
            local TargetBorder = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';

            if TweenConfig.Toggle > 0 then
                Tween(ToggleInner, TweenConfig.Toggle, {
                    BackgroundColor3 = TargetBg;
                    BorderColor3 = TargetBorder;
                });

                Tween(ToggleScale, TweenConfig.Toggle, {
                    Scale = Toggle.Value and 1.22 or 0.85
                }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

                task.delay(TweenConfig.Toggle, function()
                    if ToggleScale and ToggleScale.Parent then
                        Tween(ToggleScale, TweenConfig.Toggle * 0.8, { Scale = 1 },
                            Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
                    end;
                end);
            else
                ToggleInner.BackgroundColor3 = TargetBg;
                ToggleInner.BorderColor3 = TargetBorder;
            end;
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if not IsClickInput(Input) then return end;
            local PX = Input.Position.X;
            local PY = Input.Position.Y;
            if not Library:MouseIsOverOpenedFrame(PX, PY) then
                Toggle:SetValue(not Toggle.Value);
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Active = true;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        -- MaxSize suit la largeur réelle du slider (responsive PC/mobile)
        local function UpdateSliderMaxSize()
            local W = SliderInner.AbsoluteSize.X;

            if W > 0 then
                local NewMax = math.max(60, math.floor(W - 2));

                if NewMax ~= Slider.MaxSize then
                    Slider.MaxSize = NewMax;
                    Slider:Display();
                end;
            end;
        end;

        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateSliderMaxSize);
        task.defer(UpdateSliderMaxSize);

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);

            if TweenConfig.Slider > 0 then
                Tween(Fill, TweenConfig.Slider, { Size = UDim2.new(0, X, 1, 0) });
            else
                Fill.Size = UDim2.new(0, X, 1, 0);
            end;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        local function OnSliderDown(Input)
            if not IsClickInput(Input) then return end;
            if Library:MouseIsOverOpenedFrame(Input.Position.X, Input.Position.Y) then return end;

            local mPos = Mouse.X;
            local gPos = Fill.Size.X.Offset;
            local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

            while IsDragInput(Input) do
                local nX = math.clamp(gPos + (Mouse.X - mPos) + Diff, 0, Slider.MaxSize);
                local nValue = Slider:GetValueFromXOffset(nX);
                local OldValue = Slider.Value;
                Slider.Value = nValue;

                local dX = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
                Fill.Size = UDim2.new(0, dX, 1, 0);
                HideBorderRight.Visible = not (dX == Slider.MaxSize or dX == 0);

                if Info.Compact then
                    DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. (Info.Suffix or '');
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format('%s', Slider.Value .. (Info.Suffix or ''));
                else
                    DisplayLabel.Text = string.format('%s/%s', Slider.Value .. (Info.Suffix or ''), Slider.Max .. (Info.Suffix or ''));
                end;

                if nValue ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value);
                    Library:SafeCallback(Slider.Changed, Slider.Value);
                end;

                RenderStepped:Wait();
            end;

            Library:AttemptSave();
        end;

        -- zone de drag élargie au doigt (mobile uniquement, invisible, hors layout)
        if IsMobile then
            local SliderTouchZone = Library:Create('Frame', {
                BackgroundTransparency = 1;
                AnchorPoint = Vector2.new(0, 0.5);
                Position = UDim2.new(0, 0, 0.5, 0);
                Size = UDim2.new(1, 0, 0, 36);
                ZIndex = 8;
                Active = true;
                Parent = SliderOuter;
            });

            SliderTouchZone.InputBegan:Connect(OnSliderDown);
        end;

        SliderInner.InputBegan:Connect(OnSliderDown);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DROPDOWN_ITEM_H = IsMobile and 26 or 20;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, DROPDOWN_ITEM_H);
            ZIndex = 5;
            Active = true;
            Parent = Container;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5);
            Parent = DropdownOuter;
        });

        Library:Create('UIStroke', {
            Color = Library.OutlineColor;
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5);
            Parent = DropdownInner;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(205, 205, 205))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderSizePixel = 0;
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5);
            Parent = ListOuter;
        });

        Library:Create('UIStroke', {
            Color = Library.OutlineColor;
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            ZIndex = 22;
            Parent = ListOuter;
        });

        local function GetTargetDropdownHeight()
            local count = #Dropdown.Values;
            return math.clamp(count * DROPDOWN_ITEM_H, 0, MAX_DROPDOWN_ITEMS * DROPDOWN_ITEM_H) + 2;
        end;

        local function RecalculateListPosition(forcedH)
            local X = DropdownOuter.AbsolutePosition.X;
            local Cam = workspace.CurrentCamera;
            local VP = (Cam and Cam.ViewportSize.X > 0) and Cam.ViewportSize or ScreenGui.AbsoluteSize;
            local TargetH = forcedH or GetTargetDropdownHeight();

            local Y = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y + 2;
            local OpensUpward = false;

            -- Si la liste dépasse en bas de l'écran (notamment en mode fenêtré), on l'ouvre vers le haut
            if (Y + TargetH) > (VP.Y - 8) then
                local UpY = DropdownOuter.AbsolutePosition.Y - TargetH - 2;
                if UpY >= 4 or (DropdownOuter.AbsolutePosition.Y > (VP.Y / 2)) then
                    Y = math.max(4, UpY);
                    OpensUpward = true;
                end;
            end;

            ListOuter.Position = UDim2.fromOffset(
                math.clamp(X, 4, math.max(4, VP.X - DropdownOuter.AbsoluteSize.X - 4)),
                math.clamp(Y, 4, math.max(4, VP.Y - TargetH - 4))
            );

            return OpensUpward, TargetH;
        end;

        local function RecalculateListSize(YSize)
            local H = YSize or GetTargetDropdownHeight();
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, H);
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 5);
            Parent = ListInner;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 20)),
            });
            Rotation = 90;
            Parent = ListInner;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, DROPDOWN_ITEM_H);
                    ZIndex = 23;
                    Active = true;
                    Parent = Scrolling;
                });

                Library:Create('UICorner', {
                    CornerRadius = UDim.new(0, 3);
                    Parent = Button;
                });


                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if IsClickInput(Input) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * DROPDOWN_ITEM_H) + 1);

            local Y = math.clamp(Count * DROPDOWN_ITEM_H, 0, MAX_DROPDOWN_ITEMS * DROPDOWN_ITEM_H) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        Dropdown.Refresh = Dropdown.SetValues;

        function Dropdown:OpenDropdown()
            local TargetH = GetTargetDropdownHeight();
            local OpensUpward = RecalculateListPosition(TargetH);
            RecalculateListSize(TargetH);

            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;

            if TweenConfig.Dropdown > 0 then
                Tween(DropdownArrow, TweenConfig.Dropdown, { Rotation = 180 },
                    Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

                ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, 0);
                if OpensUpward then
                    local bottomY = DropdownOuter.AbsolutePosition.Y - 2;
                    ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, bottomY);
                    Tween(ListOuter, TweenConfig.Dropdown, {
                        Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, TargetH),
                        Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, bottomY - TargetH)
                    }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
                else
                    Tween(ListOuter, TweenConfig.Dropdown, {
                        Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, TargetH)
                    }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
                end;
            else
                DropdownArrow.Rotation = 180;
            end;
        end;

        function Dropdown:CloseDropdown()
            Library.OpenedFrames[ListOuter] = nil;

            if TweenConfig.Dropdown > 0 then
                Tween(DropdownArrow, TweenConfig.Dropdown, { Rotation = 0 },
                    Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

                local CurrentSize = ListOuter.Size;
                Tween(ListOuter, TweenConfig.Dropdown, {
                    Size = UDim2.fromOffset(CurrentSize.X.Offset, 0)
                }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

                task.delay(TweenConfig.Dropdown, function()
                    if ListOuter and not Library.OpenedFrames[ListOuter] then
                        ListOuter.Visible = false;
                    end;
                end);
            else
                ListOuter.Visible = false;
                DropdownArrow.Rotation = 0;
            end;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if not IsClickInput(Input) then return end;
            if Library:MouseIsOverOpenedFrame(Input.Position.X, Input.Position.Y) then return end;
            if ListOuter.Visible then
                Dropdown:CloseDropdown();
            else
                Dropdown:OpenDropdown();
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not IsMouseInput(Input) then return end;
            local PX = Input.Position.X;
            local PY = Input.Position.Y;
            local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

            if PX < AbsPos.X or PX > AbsPos.X + AbsSize.X
                or PY < (AbsPos.Y - 20 - 1) or PY > AbsPos.Y + AbsSize.Y then

                Dropdown:CloseDropdown();
            end;
        end));

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    function Funcs:AddList(Idx, Info)
        assert(Info.Values, 'AddList: Missing `Values` table.');

        local List = {
            Values = Info.Values or {};
            Value = Info.Multi and (Info.Default or {}) or (Info.Default or (Info.Values and Info.Values[1] or ''));
            Multi = Info.Multi or false;
            Type = 'List';
            Callback = Info.Callback or function() end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        local Height = Info.Height or 240;

        local Outer = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(1, 0, 0, Height);
            ZIndex = 5;
            Parent = Container;
        });

        local SearchHeight = (Info.Search ~= false) and 24 or 0;
        local ResetHeight = (Info.ResetButton ~= nil and Info.ResetButton ~= false) and 24 or 0;

        local SearchBox;
        if Info.Search ~= false then
            local SearchFrame = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(25, 25, 25);
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 0, SearchHeight);
                ZIndex = 6;
                Parent = Outer;
            });

            SearchBox = Library:Create('TextBox', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -10, 1, 0);
                Position = UDim2.new(0, 5, 0, 0);
                Font = Library.Font;
                TextSize = 13;
                TextColor3 = Library.FontColor;
                PlaceholderColor3 = Color3.fromRGB(130, 130, 130);
                PlaceholderText = Info.Placeholder or 'Search...';
                Text = '';
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 7;
                Parent = SearchFrame;
            });
            Library:ApplyTextStroke(SearchBox);
        end;

        local Scroll = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 2, 0, SearchHeight + 2);
            Size = UDim2.new(1, -4, 1, -(SearchHeight + ResetHeight + 4));
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.OutlineColor;
            ZIndex = 6;
            Parent = Outer;
        });

        local ListLayout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0, 2);
            Parent = Scroll;
        });

        ListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 4);
        end);

        local ItemButtons = {};

        local function RefreshItems()
            local query = SearchBox and SearchBox.Text:lower() or '';

            for val, btn in next, ItemButtons do
                local match = query == '' or tostring(val):lower():find(query, 1, true) ~= nil;
                btn.Visible = match;

                local isSelected = List.Multi and (List.Value[val] == true) or (List.Value == val);
                btn.TextColor3 = isSelected and Library.AccentColor or Library.FontColor;
            end;
        end;

        function List:BuildItems()
            for _, child in next, Scroll:GetChildren() do
                if child:IsA('TextButton') then
                    child:Destroy();
                end;
            end;
            table.clear(ItemButtons);

            for _, val in next, List.Values do
                local Btn = Library:Create('TextButton', {
                    BackgroundTransparency = 1;
                    Size = UDim2.new(1, -4, 0, 18);
                    Font = Library.Font;
                    TextSize = 13;
                    Text = ' ' .. tostring(val);
                    TextColor3 = Library.FontColor;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 7;
                    Parent = Scroll;
                });
                Library:ApplyTextStroke(Btn);

                Btn.MouseButton1Click:Connect(function()
                    if List.Multi then
                        List.Value[val] = not List.Value[val];
                    else
                        List.Value = val;
                    end;
                    RefreshItems();
                    Library:SafeCallback(List.Callback, List.Value);
                    if List.Changed then
                        Library:SafeCallback(List.Changed, List.Value);
                    end;
                end);

                ItemButtons[val] = Btn;
            end;
            RefreshItems();
        end;

        if SearchBox then
            SearchBox:GetPropertyChangedSignal('Text'):Connect(RefreshItems);
        end;

        if ResetHeight > 0 then
            local ResetBtnOuter = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30);
                BorderColor3 = Library.OutlineColor;
                Position = UDim2.new(0, 0, 1, -ResetHeight);
                Size = UDim2.new(1, 0, 0, ResetHeight);
                ZIndex = 6;
                Parent = Outer;
            });

            local ResetBtn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Font = Library.Font;
                TextSize = 13;
                TextColor3 = Library.FontColor;
                Text = type(Info.ResetButton) == 'string' and Info.ResetButton or 'Reset all';
                ZIndex = 7;
                Parent = ResetBtnOuter;
            });
            Library:ApplyTextStroke(ResetBtn);

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 38)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 24)),
                });
                Rotation = 90;
                Parent = ResetBtnOuter;
            });

            ResetBtn.MouseButton1Click:Connect(function()
                if List.Multi then
                    table.clear(List.Value);
                else
                    List.Value = '';
                end;
                RefreshItems();
                if Info.ResetCallback then
                    Library:SafeCallback(Info.ResetCallback);
                end;
            end);
        end;

        function List:SetValues(newVals)
            List.Values = newVals or {};
            List:BuildItems();
        end;

        function List:SetValue(val)
            List.Value = val;
            RefreshItems();
            Library:SafeCallback(List.Callback, List.Value);
            if List.Changed then
                Library:SafeCallback(List.Changed, List.Value);
            end;
        end;

        function List:OnChanged(f)
            List.Changed = f;
            f(List.Value);
        end;

        List:BuildItems();
        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = List;
        return List;
    end;

    function Funcs:AddStats(Info)
        Info = Info or {};
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Outer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 68);
            ZIndex = 5;
            Parent = Container;
        });

        local AvatarFrame = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Position = UDim2.new(0, 0, 0, 2);
            Size = UDim2.new(0, 60, 0, 60);
            ZIndex = 6;
            Parent = Outer;
        });

        local targetUserId = Info.UserId or (LocalPlayer and LocalPlayer.UserId or 1);
        local avatarImg = Info.Image or ('rbxthumb://type=AvatarHeadShot&id=' .. tostring(targetUserId) .. '&w=100&h=100');

        local AvatarImage = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Image = avatarImg;
            ZIndex = 7;
            Parent = AvatarFrame;
        });

        local TextHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 68, 0, 2);
            Size = UDim2.new(1, -70, 1, -4);
            ZIndex = 6;
            Parent = Outer;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0, 2);
            Parent = TextHolder;
        });

        local defaultLines = {
            (LocalPlayer and (LocalPlayer.Name .. ' (@' .. LocalPlayer.Name .. ')') or 'Player (@Player)'),
            'ID: ' .. tostring(targetUserId),
            'Account Age: ' .. tostring(LocalPlayer and LocalPlayer.AccountAge or 0) .. ' days',
            'Team: ' .. (LocalPlayer and LocalPlayer.Team and LocalPlayer.Team.Name or 'Neutral'),
        };

        local lines = Info.Lines or defaultLines;
        local Labels = {};

        for i, line in ipairs(lines) do
            local lbl = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13);
                TextSize = (i == 1) and 13 or 12;
                TextColor3 = (i == 1) and Library.FontColor or Color3.fromRGB(200, 200, 200);
                Text = line;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 7;
                Parent = TextHolder;
            });
            table.insert(Labels, lbl);
        end;

        local Stats = {
            Labels = Labels;
            Avatar = AvatarImage;
        };

        function Stats:SetLines(newLines)
            for i, line in ipairs(newLines) do
                if Labels[i] then
                    Labels[i].Text = line;
                end;
            end;
        end;

        function Stats:SetAvatar(img)
            AvatarImage.Image = img;
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Stats;
    end;

    function Funcs:AddImage(Idx, Info)
        if type(Idx) == 'table' and Info == nil then
            Info = Idx;
            Idx = Info.Idx or ('Image_' .. tostring(math.random(10000, 99999)));
        end;
        Info = Info or {};
        local Groupbox = self;
        local Container = Groupbox.Container;

        local CardHeight = Info.Height or 135;
        local HasTitle = (Info.Title ~= nil and Info.Title ~= '');

        local CardOuter = Library:Create('Frame', {
            BackgroundColor3 = Info.BackgroundColor3 or Color3.fromRGB(18, 18, 22);
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, CardHeight);
            ZIndex = 5;
            Parent = Container;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, Info.Corner or 6);
            Parent = CardOuter;
        });

        Library:Create('UIStroke', {
            Color = Info.StrokeColor or Color3.fromRGB(40, 40, 48);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = CardOuter;
        });

        local TitleLabel;
        if HasTitle then
            TitleLabel = Library:CreateLabel({
                Size = UDim2.new(1, -16, 0, 16);
                Position = UDim2.new(0, 8, 0, 6);
                TextSize = Info.TitleSize or 12;
                TextColor3 = Info.TitleColor or Color3.fromRGB(220, 220, 230);
                Text = Info.Title;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 6;
                Parent = CardOuter;
            });
        end;

        local ImageBox = Library:Create('ImageLabel', {
            BackgroundTransparency = 1;
            Position = HasTitle and UDim2.new(0, 8, 0, 24) or UDim2.new(0, 8, 0, 8);
            Size = HasTitle and UDim2.new(1, -16, 1, -30) or UDim2.new(1, -16, 1, -16);
            Image = Info.Image or '';
            ScaleType = Info.ScaleType or Enum.ScaleType.Fit;
            ImageColor3 = Info.ImageColor3 or Color3.new(1, 1, 1);
            ZIndex = 6;
            Parent = CardOuter;
        });

        if Info.AspectRatio then
            Library:Create('UIAspectRatioConstraint', {
                AspectRatio = Info.AspectRatio;
                Parent = ImageBox;
            });
        end;

        local ImageObj = {
            Outer = CardOuter;
            Card = CardOuter;
            ImageLabel = ImageBox;
            TitleLabel = TitleLabel;
            Height = CardHeight;
        };

        function ImageObj:SetImage(newImg)
            if type(newImg) == 'number' then
                newImg = 'rbxassetid://' .. tostring(newImg);
            end;
            ImageBox.Image = newImg or '';
        end;

        function ImageObj:SetTitle(newTitle)
            if TitleLabel then
                TitleLabel.Text = newTitle or '';
            end;
        end;

        function ImageObj:SetVisible(vis)
            CardOuter.Visible = vis;
            Groupbox:Resize();
        end;

        function ImageObj:SetHeight(newH)
            CardOuter.Size = UDim2.new(1, -4, 0, newH);
            Groupbox:Resize();
        end;

        function ImageObj:SetScaleType(scaleType)
            ImageBox.ScaleType = scaleType;
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = ImageObj;
        return ImageObj;
    end;

    function Funcs:AddImageRow(Idx, Info)
        if type(Idx) == 'table' and Info == nil then
            Info = Idx;
            Idx = Info.Idx or ('ImageRow_' .. tostring(math.random(10000, 99999)));
        end;
        Info = Info or {};
        local Groupbox = self;
        local Container = Groupbox.Container;

        local RowHeight = Info.Height or 90;
        local Items = Info.Items or {};
        local Count = #Items;
        if Count == 0 then Count = 2 end;

        local RowFrame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, RowHeight);
            ZIndex = 5;
            Parent = Container;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0, Info.Padding or 6);
            Parent = RowFrame;
        });

        local SubCards = {};
        local itemWidthScale = 1 / Count;
        local totalPadding = (Count - 1) * (Info.Padding or 6);
        local itemWidthOffset = -math.floor(totalPadding / Count);

        for i, itemData in ipairs(Items) do
            local itemKey = itemData.Key or itemData.Title or tostring(i);
            local HasSubTitle = (itemData.Title ~= nil and itemData.Title ~= '');

            local SubCard = Library:Create('Frame', {
                BackgroundColor3 = itemData.BackgroundColor3 or Color3.fromRGB(18, 18, 22);
                BorderSizePixel = 0;
                Size = UDim2.new(itemWidthScale, itemWidthOffset, 1, 0);
                LayoutOrder = i;
                ZIndex = 6;
                Parent = RowFrame;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, itemData.Corner or 6);
                Parent = SubCard;
            });

            Library:Create('UIStroke', {
                Color = itemData.StrokeColor or Color3.fromRGB(40, 40, 48);
                Thickness = 1;
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Parent = SubCard;
            });

            local SubTitle;
            if HasSubTitle then
                SubTitle = Library:CreateLabel({
                    Size = UDim2.new(1, -12, 0, 14);
                    Position = UDim2.new(0, 6, 0, 5);
                    TextSize = 11;
                    TextColor3 = Color3.fromRGB(190, 190, 200);
                    Text = itemData.Title;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 7;
                    Parent = SubCard;
                });
            end;

            local SubImg = Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Position = HasSubTitle and UDim2.new(0, 6, 0, 20) or UDim2.new(0, 6, 0, 6);
                Size = HasSubTitle and UDim2.new(1, -12, 1, -24) or UDim2.new(1, -12, 1, -12);
                Image = itemData.Image or '';
                ScaleType = itemData.ScaleType or Enum.ScaleType.Fit;
                ImageColor3 = itemData.ImageColor3 or Color3.new(1, 1, 1);
                ZIndex = 7;
                Parent = SubCard;
            });

            local cardRef = {
                Card = SubCard;
                TitleLabel = SubTitle;
                ImageLabel = SubImg;
            };

            function cardRef:SetImage(newImg)
                if type(newImg) == 'number' then
                    newImg = 'rbxassetid://' .. tostring(newImg);
                end;
                SubImg.Image = newImg or '';
            end;

            function cardRef:SetTitle(newTitle)
                if SubTitle then
                    SubTitle.Text = newTitle or '';
                end;
            end;

            SubCards[itemKey] = cardRef;
            SubCards[i] = cardRef;
        end;

        local RowObj = {
            Outer = RowFrame;
            Cards = SubCards;
            Height = RowHeight;
        };

        function RowObj:SetImage(key, img)
            if SubCards[key] then
                SubCards[key]:SetImage(img);
            end;
        end;

        function RowObj:SetTitle(key, title)
            if SubCards[key] then
                SubCards[key]:SetTitle(title);
            end;
        end;

        function RowObj:SetVisible(vis)
            RowFrame.Visible = vis;
            Groupbox:Resize();
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = RowObj;
        return RowObj;
    end;

    function Funcs:AddRender(Idx, Info)
        if type(Idx) == 'table' and Info == nil then
            Info = Idx;
            Idx = Info.Idx or ('Render_' .. tostring(math.random(10000, 99999)));
        end;
        Info = Info or {};
        local Groupbox = self;

        local MainCard = Groupbox:AddImage(Idx .. '_Main', {
            Title = Info.WeaponTitle or 'AKEY-47';
            Image = Info.WeaponImage or '';
            Height = Info.WeaponHeight or 135;
            Corner = 6;
        });

        local DetailFields = Info.Details or {
            { Key = 'Weapon', Label = 'Weapon', Value = 'Assault Rifle' },
            { Key = 'Skin', Label = 'Skin', Value = 'AKEY-47' },
            { Key = 'Wrap', Label = 'Wrap', Value = '2025 Wrapping' },
            { Key = 'Charm', Label = 'Charm', Value = 'WE1RD' },
            { Key = 'Finisher', Label = 'Finisher', Value = 'Whirlpool' },
        };

        local Labels = {};
        for _, item in ipairs(DetailFields) do
            local lbl = Groupbox:AddLabel(item.Label .. ': ' .. tostring(item.Value));
            Labels[item.Key] = {
                LabelObj = lbl;
                Prefix = item.Label;
            };
        end;

        local Row = Groupbox:AddImageRow(Idx .. '_Row', {
            Height = 85;
            Items = {
                { Key = 'Wrap', Title = Info.WrapTitle or 'Wrap', Image = Info.WrapImage or '' },
                { Key = 'Charm', Title = Info.CharmTitle or 'Charm', Image = Info.CharmImage or '' },
            };
        });

        local FinisherCard = Groupbox:AddImage(Idx .. '_Finisher', {
            Title = Info.FinisherTitle or 'Finisher';
            Image = Info.FinisherImage or '';
            Height = 85;
            Corner = 6;
        });

        local RenderObj = {
            MainCard = MainCard;
            Labels = Labels;
            Row = Row;
            FinisherCard = FinisherCard;
        };

        function RenderObj:SetWeapon(title, img)
            if title then MainCard:SetTitle(title) end;
            if img then MainCard:SetImage(img) end;
        end;

        function RenderObj:SetDetail(key, val)
            if Labels[key] and Labels[key].LabelObj then
                Labels[key].LabelObj:SetText(Labels[key].Prefix .. ': ' .. tostring(val));
            end;
        end;

        function RenderObj:SetWrapImage(img)
            Row:SetImage('Wrap', img);
        end;

        function RenderObj:SetCharmImage(img)
            Row:SetImage('Charm', img);
        end;

        function RenderObj:SetFinisherImage(img)
            FinisherCard:SetImage(img);
        end;

        function RenderObj:Update(data)
            data = data or {};
            if data.WeaponTitle or data.Skin then
                MainCard:SetTitle(data.WeaponTitle or data.Skin);
            end;
            if data.WeaponImage then MainCard:SetImage(data.WeaponImage) end;
            if data.Weapon then self:SetDetail('Weapon', data.Weapon) end;
            if data.Skin then self:SetDetail('Skin', data.Skin) end;
            if data.Wrap then self:SetDetail('Wrap', data.Wrap) end;
            if data.Charm then self:SetDetail('Charm', data.Charm) end;
            if data.Finisher then self:SetDetail('Finisher', data.Finisher) end;
            if data.WrapImage then self:SetWrapImage(data.WrapImage) end;
            if data.CharmImage then self:SetCharmImage(data.CharmImage) end;
            if data.FinisherImage then self:SetFinisherImage(data.FinisherImage) end;
        end;

        Options[Idx] = RenderObj;
        return RenderObj;
    end;

    function Funcs:AddESPPreview(Idx, Info)
        if type(Idx) == 'table' and Info == nil then
            Info = Idx;
            Idx = Info.Idx or ('ESPPreview_' .. tostring(math.random(10000, 99999)));
        end;
        Info = Info or {};
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Height = Info.Height or 260;

        local Outer = Library:Create('Frame', {
            BackgroundColor3 = Info.BackgroundColor3 or Color3.fromRGB(14, 14, 18);
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, Height);
            ZIndex = 5;
            ClipsDescendants = true;
            Parent = Container;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 6);
            Parent = Outer;
        });

        Library:Create('UIStroke', {
            Color = Color3.fromRGB(38, 38, 46);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = Outer;
        });

        local Viewport = Library:Create('ViewportFrame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            LightColor = Color3.fromRGB(240, 240, 240);
            Ambient = Color3.fromRGB(150, 150, 160);
            LightDirection = Vector3.new(1, -2, -1);
            ZIndex = 6;
            Parent = Outer;
        });

        local World = Instance.new('WorldModel');
        World.Parent = Viewport;

        local Camera = Instance.new('Camera');
        Camera.FieldOfView = 50;
        Camera.Parent = Viewport;
        Viewport.CurrentCamera = Camera;

        local TargetCenter = Vector3.new(0, 0.2, 0);
        local Yaw = 0;
        local Pitch = 0;
        local Distance = 8.2;

        local UpdateSkeleton;

        local function UpdateCamera()
            local rot = CFrame.Angles(0, Yaw, 0) * CFrame.Angles(Pitch, 0, 0);
            local camPos = TargetCenter + rot * Vector3.new(0, 0, Distance);
            Camera.CFrame = CFrame.new(camPos, TargetCenter);
            if UpdateSkeleton then UpdateSkeleton() end;
        end;
        UpdateCamera();

        local OriginalProps = {};
        local CurrentModel = nil;

        local function SetupModel(model)
            if not model then return end;
            if CurrentModel then
                CurrentModel:Destroy();
                table.clear(OriginalProps);
            end;

            model.Parent = World;
            CurrentModel = model;

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.Anchored = true;
                    part.CanCollide = false;
                    OriginalProps[part] = {
                        Color = part.Color;
                        Material = part.Material;
                        Transparency = part.Transparency;
                    };
                end;
            end;

            -- Orientation: face forward toward camera
            pcall(function()
                model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0));
            end);

            local cf, size = model:GetBoundingBox();
            TargetCenter = cf.Position;
            Distance = math.max(size.Y * 1.6, 7.8);
            UpdateCamera();
        end;

        local function CloneLocalCharacter()
            local char = LocalPlayer and LocalPlayer.Character;
            if not char then return nil end;
            local oldArch = char.Archivable;
            char.Archivable = true;
            local clone = char:Clone();
            char.Archivable = oldArch;

            for _, desc in ipairs(clone:GetDescendants()) do
                if desc:IsA('Script') or desc:IsA('LocalScript') or desc:IsA('Sound') then
                    desc:Destroy();
                elseif desc:IsA('BasePart') then
                    desc.Anchored = true;
                    desc.CanCollide = false;
                end;
            end;
            local hum = clone:FindFirstChildOfClass('Humanoid');
            if hum then
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
            end;
            return clone;
        end;

        task.spawn(function()
            local charClone = CloneLocalCharacter();
            if charClone then
                SetupModel(charClone);
            elseif LocalPlayer then
                local ok, dummy = pcall(function()
                    return Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId);
                end);
                if ok and dummy then
                    for _, desc in ipairs(dummy:GetDescendants()) do
                        if desc:IsA('BasePart') then desc.Anchored = true end;
                    end;
                    SetupModel(dummy);
                end;
            end;
        end);

        if LocalPlayer then
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1);
                local freshClone = CloneLocalCharacter();
                if freshClone then SetupModel(freshClone) end;
            end);
        end;

        -- Mouse & Touch Rotation Controls
        local Dragging = false;
        local LastPos = Vector2.new();

        Outer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true;
                LastPos = Vector2.new(input.Position.X, input.Position.Y);
            end;
        end);

        local endSignal = InputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false;
            end;
        end);
        Library:GiveSignal(endSignal);

        local changeSignal = InputService.InputChanged:Connect(function(input)
            if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local currentPos = Vector2.new(input.Position.X, input.Position.Y);
                local delta = currentPos - LastPos;
                LastPos = currentPos;

                Yaw = Yaw - delta.X * 0.015;
                Pitch = math.clamp(Pitch - delta.Y * 0.01, -0.65, 0.65);
                UpdateCamera();
            end;
        end);
        Library:GiveSignal(changeSignal);

        Outer.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                Distance = math.clamp(Distance - input.Position.Z * 0.9, 4.0, 16.0);
                UpdateCamera();
            end;
        end);

        -- 3D Projector to convert WorldModel coordinates to Viewport pixel space
        local function ProjectToViewport(worldPos)
            local obj = Camera.CFrame:PointToObjectSpace(worldPos);
            local z = -obj.Z;
            if z <= 0.1 then return Vector2.new(-1000, -1000), false end;

            local absW = Viewport.AbsoluteSize.X;
            local absH = Viewport.AbsoluteSize.Y;
            if absW <= 10 or absH <= 10 then
                absW = Outer.AbsoluteSize.X;
                absH = Height;
            end;
            if absW <= 10 then absW = 220 end;
            if absH <= 10 then absH = Height or 260 end;

            local aspect = absW / absH;
            local tanHalfFov = math.tan(math.rad(Camera.FieldOfView) / 2);
            local normX = obj.X / (z * tanHalfFov * aspect);
            local normY = obj.Y / (z * tanHalfFov);

            local px = (normX * 0.5 + 0.5) * absW;
            local py = (-normY * 0.5 + 0.5) * absH;
            local onScreen = (normX >= -1.2 and normX <= 1.2 and normY >= -1.2 and normY <= 1.2);
            return Vector2.new(px, py), onScreen;
        end;

        -- ESP Overlay Frame
        local Overlay = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 8;
            Parent = Outer;
        });

        -- Dynamic 3D Skeleton Wireframe Overlay
        local SkeletonContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 8;
            Parent = Overlay;
        });

        local BoneLines = {};
        local SkeletonEnabled = true;
        local SkeletonColor = Color3.fromRGB(255, 255, 255);

        local R15_Bones = {
            { 'Head', 'UpperTorso' },
            { 'UpperTorso', 'LowerTorso' },
            { 'UpperTorso', 'LeftUpperArm' },
            { 'LeftUpperArm', 'LeftLowerArm' },
            { 'LeftLowerArm', 'LeftHand' },
            { 'UpperTorso', 'RightUpperArm' },
            { 'RightUpperArm', 'RightLowerArm' },
            { 'RightLowerArm', 'RightHand' },
            { 'LowerTorso', 'LeftUpperLeg' },
            { 'LeftUpperLeg', 'LeftLowerLeg' },
            { 'LeftLowerLeg', 'LeftFoot' },
            { 'LowerTorso', 'RightUpperLeg' },
            { 'RightUpperLeg', 'RightLowerLeg' },
            { 'RightLowerLeg', 'RightFoot' },
        };

        local R6_Bones = {
            { 'Head', 'Torso' },
            { 'Torso', 'Left Arm' },
            { 'Torso', 'Right Arm' },
            { 'Torso', 'Left Leg' },
            { 'Torso', 'Right Leg' },
        };

        UpdateSkeleton = function()
            if not SkeletonEnabled or not CurrentModel then
                for _, line in pairs(BoneLines) do
                    line.Visible = false;
                end;
                return;
            end;

            local isR15 = CurrentModel:FindFirstChild('UpperTorso') ~= nil;
            local boneDefs = isR15 and R15_Bones or R6_Bones;

            for idx, pair in ipairs(boneDefs) do
                local p1 = CurrentModel:FindFirstChild(pair[1]);
                local p2 = CurrentModel:FindFirstChild(pair[2]);
                local line = BoneLines[idx];
                if not line then
                    line = Library:Create('Frame', {
                        BackgroundColor3 = SkeletonColor;
                        BorderSizePixel = 0;
                        AnchorPoint = Vector2.new(0.5, 0.5);
                        ZIndex = 8;
                        Parent = SkeletonContainer;
                    });
                    Library:Create('UIStroke', {
                        Color = Color3.new(0, 0, 0);
                        Thickness = 0.5;
                        Parent = line;
                    });
                    BoneLines[idx] = line;
                end;

                if p1 and p2 then
                    local v1, on1 = ProjectToViewport(p1.Position);
                    local v2, on2 = ProjectToViewport(p2.Position);

                    if on1 and on2 then
                        local dx = v2.X - v1.X;
                        local dy = v2.Y - v1.Y;
                        local dist = math.sqrt(dx * dx + dy * dy);
                        local angle = math.deg(math.atan2(dy, dx));
                        local midX = (v1.X + v2.X) / 2;
                        local midY = (v1.Y + v2.Y) / 2;

                        line.Size = UDim2.new(0, dist, 0, 1.5);
                        line.Position = UDim2.new(0, midX, 0, midY);
                        line.Rotation = angle;
                        line.BackgroundColor3 = SkeletonColor;
                        line.Visible = true;
                    else
                        line.Visible = false;
                    end;
                else
                    line.Visible = false;
                end;
            end;

            for i = #boneDefs + 1, #BoneLines do
                if BoneLines[i] then BoneLines[i].Visible = false end;
            end;
        end;

        -- Bounding Box (Supports Full Box, Corner Box, and Fill)
        local BoxMain = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255);
            BackgroundTransparency = 0.90;
            BorderSizePixel = 0;
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.new(0.5, 0, 0.5, 0);
            Size = UDim2.new(0, 108, 0, 186);
            ZIndex = 9;
            Parent = Overlay;
        });

        local BoxStrokeMain = Library:Create('UIStroke', {
            Color = Color3.fromRGB(255, 255, 255);
            Thickness = 1.2;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = BoxMain;
        });

        local BoxInnerBorder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 9;
            Parent = BoxMain;
        });

        local InnerStroke = Library:Create('UIStroke', {
            Color = Color3.new(0, 0, 0);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = BoxInnerBorder;
        });

        local BoxOuterBorder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, -1, 0, -1);
            Size = UDim2.new(1, 2, 1, 2);
            ZIndex = 9;
            Parent = BoxMain;
        });

        local OuterStroke = Library:Create('UIStroke', {
            Color = Color3.new(0, 0, 0);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = BoxOuterBorder;
        });

        -- Corner Box Frames
        local CornerHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 9;
            Parent = BoxMain;
        });

        local CornerFrames = {};
        local cornerLen = 14;
        local cornerThick = 1.5;

        local function CreateCornerLine(anchor, pos, size)
            local f = Library:Create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255);
                BorderSizePixel = 0;
                AnchorPoint = anchor;
                Position = pos;
                Size = size;
                ZIndex = 9;
                Parent = CornerHolder;
            });
            Library:Create('UIStroke', {
                Color = Color3.new(0, 0, 0);
                Thickness = 0.6;
                Parent = f;
            });
            table.insert(CornerFrames, f);
            return f;
        end;

        -- Top-Left Corner
        CreateCornerLine(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, cornerLen, 0, cornerThick));
        CreateCornerLine(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, cornerThick, 0, cornerLen));

        -- Top-Right Corner
        CreateCornerLine(Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, cornerLen, 0, cornerThick));
        CreateCornerLine(Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, cornerThick, 0, cornerLen));

        -- Bottom-Left Corner
        CreateCornerLine(Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(0, cornerLen, 0, cornerThick));
        CreateCornerLine(Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(0, cornerThick, 0, cornerLen));

        -- Bottom-Right Corner
        CreateCornerLine(Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), UDim2.new(0, cornerLen, 0, cornerThick));
        CreateCornerLine(Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), UDim2.new(0, cornerThick, 0, cornerLen));

        -- Health Bar (Left of Box)
        local HealthBarBg = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(12, 12, 14);
            BorderSizePixel = 0;
            Position = UDim2.new(0, -7, 0, 0);
            Size = UDim2.new(0, 3, 1, 0);
            ZIndex = 10;
            Parent = BoxMain;
        });

        Library:Create('UIStroke', {
            Color = Color3.new(0, 0, 0);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = HealthBarBg;
        });

        local HealthBarFill = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(0, 255, 120);
            BorderSizePixel = 0;
            AnchorPoint = Vector2.new(0, 1);
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 11;
            Parent = HealthBarBg;
        });

        local HealthText = Library:CreateLabel({
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(0, -3, 0, -2);
            Size = UDim2.new(0, 24, 0, 12);
            Text = '100';
            TextSize = 9;
            TextColor3 = Color3.fromRGB(240, 240, 240);
            TextXAlignment = Enum.TextXAlignment.Right;
            TextStrokeTransparency = 0;
            TextStrokeColor3 = Color3.new(0, 0, 0);
            ZIndex = 11;
            Parent = HealthBarBg;
        });

        -- Ammo Bar (Bottom of Box)
        local AmmoBarBg = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(12, 12, 14);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 2);
            Size = UDim2.new(1, 0, 0, 2.5);
            ZIndex = 10;
            Visible = false;
            Parent = BoxMain;
        });

        Library:Create('UIStroke', {
            Color = Color3.new(0, 0, 0);
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = AmmoBarBg;
        });

        local AmmoBarFill = Library:Create('Frame', {
            BackgroundColor3 = Color3.fromRGB(80, 140, 255);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 11;
            Parent = AmmoBarBg;
        });

        local AmmoText = Library:CreateLabel({
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 28, 0, -3);
            Size = UDim2.new(0, 24, 0, 10);
            Text = '30';
            TextSize = 8;
            TextColor3 = Color3.fromRGB(200, 220, 255);
            TextStrokeTransparency = 0;
            TextStrokeColor3 = Color3.new(0, 0, 0);
            Visible = false;
            ZIndex = 11;
            Parent = AmmoBarBg;
        });

        -- Name Tag
        local NameTag = Library:CreateLabel({
            AnchorPoint = Vector2.new(0.5, 1);
            Position = UDim2.new(0.5, 0, 0, -5);
            Size = UDim2.new(1, 60, 0, 14);
            Text = (LocalPlayer and LocalPlayer.DisplayName) or 'LocalPlayer';
            TextSize = 11;
            TextColor3 = Color3.fromRGB(255, 255, 255);
            TextStrokeTransparency = 0;
            TextStrokeColor3 = Color3.new(0, 0, 0);
            ZIndex = 11;
            Parent = BoxMain;
        });

        -- Weapon Tag
        local WeaponTag = Library:CreateLabel({
            AnchorPoint = Vector2.new(0.5, 0);
            Position = UDim2.new(0.5, 0, 1, 4);
            Size = UDim2.new(1, 60, 0, 13);
            Text = 'Assault Rifle';
            TextSize = 10;
            TextColor3 = Color3.fromRGB(220, 220, 230);
            TextStrokeTransparency = 0;
            TextStrokeColor3 = Color3.new(0, 0, 0);
            ZIndex = 11;
            Parent = BoxMain;
        });

        -- Distance Tag
        local DistanceTag = Library:CreateLabel({
            AnchorPoint = Vector2.new(0.5, 0);
            Position = UDim2.new(0.5, 0, 1, 17);
            Size = UDim2.new(1, 60, 0, 12);
            Text = '18m';
            TextSize = 9;
            TextColor3 = Color3.fromRGB(175, 175, 190);
            TextStrokeTransparency = 0;
            TextStrokeColor3 = Color3.new(0, 0, 0);
            Visible = false;
            ZIndex = 11;
            Parent = BoxMain;
        });

        -- Flags Holder (Right of Box)
        local FlagsHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(1, 6, 0, 0);
            Size = UDim2.new(0, 50, 1, 0);
            ZIndex = 11;
            Parent = BoxMain;
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0, 2);
            Parent = FlagsHolder;
        });

        local FlagLabels = {};
        for _, flag in ipairs({
            { Key = 'Armor', Text = 'ARMOR', Color = Color3.fromRGB(90, 190, 255) },
            { Key = 'Scoped', Text = 'SCOPED', Color = Color3.fromRGB(120, 240, 140) },
            { Key = 'VIP', Text = 'VIP', Color = Color3.fromRGB(255, 215, 0) },
            { Key = 'Flashed', Text = 'FLASHED', Color = Color3.fromRGB(255, 170, 0) },
            { Key = 'Reload', Text = 'RELOAD', Color = Color3.fromRGB(255, 80, 80) },
        }) do
            local fl = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 11);
                Text = flag.Text;
                TextSize = 9;
                TextColor3 = flag.Color;
                TextStrokeTransparency = 0;
                TextStrokeColor3 = Color3.new(0, 0, 0);
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 11;
                Parent = FlagsHolder;
            });
            FlagLabels[flag.Key] = fl;
        end;

        local ResetBtn = Library:Create('TextButton', {
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, -8, 0, 8);
            Size = UDim2.new(0, 24, 0, 24);
            BackgroundColor3 = Color3.fromRGB(24, 24, 30);
            Text = '⟲';
            TextColor3 = Color3.fromRGB(200, 200, 210);
            TextSize = 14;
            ZIndex = 12;
            Parent = Outer;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 4);
            Parent = ResetBtn;
        });

        Library:Create('UIStroke', {
            Color = Color3.fromRGB(48, 48, 56);
            Thickness = 1;
            Parent = ResetBtn;
        });

        ResetBtn.MouseButton1Click:Connect(function()
            Yaw = 0;
            Pitch = 0;
            Distance = 8.2;
            UpdateCamera();
        end);

        Library:AddToolTip('Reset 3D camera angle', ResetBtn);

        local HintLabel = Library:CreateLabel({
            AnchorPoint = Vector2.new(0, 1);
            Position = UDim2.new(0, 8, 1, -6);
            Size = UDim2.new(1, -16, 0, 12);
            Text = '🖱️ Drag to rotate • 🔍 Scroll to zoom';
            TextSize = 10;
            TextColor3 = Color3.fromRGB(130, 130, 145);
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 11;
            Parent = Outer;
        });

        local ESPPreviewObj = {
            Outer = Outer;
            Viewport = Viewport;
            World = World;
            Camera = Camera;
            BoxMain = BoxMain;
            BoxStrokeMain = BoxStrokeMain;
            CornerHolder = CornerHolder;
            CornerFrames = CornerFrames;
            HealthBarBg = HealthBarBg;
            HealthBarFill = HealthBarFill;
            HealthText = HealthText;
            AmmoBarBg = AmmoBarBg;
            AmmoBarFill = AmmoBarFill;
            AmmoText = AmmoText;
            NameTag = NameTag;
            WeaponTag = WeaponTag;
            DistanceTag = DistanceTag;
            FlagsHolder = FlagsHolder;
            FlagLabels = FlagLabels;
            SkeletonContainer = SkeletonContainer;
        };

        function ESPPreviewObj:SetBox(visible, color, style)
            BoxMain.Visible = (visible ~= false);
            if color then
                BoxStrokeMain.Color = color;
                for _, cl in ipairs(CornerFrames) do
                    cl.BackgroundColor3 = color;
                end;
            end;
            if style then
                ESPPreviewObj:SetBoxStyle(style);
            end;
        end;

        function ESPPreviewObj:SetBoxStyle(style)
            local isCorner = (style == 'Corner');
            BoxStrokeMain.Enabled = not isCorner;
            InnerStroke.Enabled = not isCorner;
            OuterStroke.Enabled = not isCorner;
            CornerHolder.Visible = isCorner;
        end;

        function ESPPreviewObj:SetBoxFill(visible, color, transparency)
            if visible then
                BoxMain.BackgroundTransparency = transparency or 0.85;
                if color then BoxMain.BackgroundColor3 = color end;
            else
                BoxMain.BackgroundTransparency = 1;
            end;
        end;

        function ESPPreviewObj:SetSkeleton(visible, color)
            SkeletonEnabled = (visible ~= false);
            if color then SkeletonColor = color end;
            UpdateSkeleton();
        end;

        function ESPPreviewObj:SetName(visible, color, text)
            NameTag.Visible = (visible ~= false);
            if color then NameTag.TextColor3 = color end;
            if text then NameTag.Text = text end;
        end;

        function ESPPreviewObj:SetHealth(visible, hp, showNumber, color)
            HealthBarBg.Visible = (visible ~= false);
            hp = hp or 100;
            local pct = math.clamp(hp / 100, 0, 1);
            HealthBarFill.Size = UDim2.new(1, 0, pct, 0);
            HealthText.Visible = (showNumber ~= false);
            HealthText.Text = tostring(math.floor(hp));
            if color then
                HealthBarFill.BackgroundColor3 = color;
            else
                if hp >= 75 then
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120);
                elseif hp >= 40 then
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(240, 200, 40);
                else
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60);
                end;
            end;
        end;

        function ESPPreviewObj:SetWeapon(visible, color, text)
            WeaponTag.Visible = (visible ~= false);
            if color then WeaponTag.TextColor3 = color end;
            if text then WeaponTag.Text = text end;
        end;

        function ESPPreviewObj:SetAmmo(visible, pct, color, text)
            AmmoBarBg.Visible = (visible ~= false);
            if pct then AmmoBarFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) end;
            if color then AmmoBarFill.BackgroundColor3 = color end;
            if text then
                AmmoText.Text = text;
                AmmoText.Visible = true;
            end;
            if AmmoBarBg.Visible then
                WeaponTag.Position = UDim2.new(0.5, 0, 1, 7);
                DistanceTag.Position = UDim2.new(0.5, 0, 1, 20);
            else
                WeaponTag.Position = UDim2.new(0.5, 0, 1, 4);
                DistanceTag.Position = UDim2.new(0.5, 0, 1, 17);
            end;
        end;

        function ESPPreviewObj:SetDistance(visible, color, text)
            DistanceTag.Visible = (visible ~= false);
            if color then DistanceTag.TextColor3 = color end;
            if text then DistanceTag.Text = text end;
        end;

        function ESPPreviewObj:SetFlags(visible, flagsList)
            FlagsHolder.Visible = (visible ~= false);
            if flagsList and type(flagsList) == 'table' then
                for key, lbl in pairs(FlagLabels) do
                    lbl.Visible = (flagsList[key] == true);
                end;
            end;
        end;

        function ESPPreviewObj:SetChams(enabled, color, transparency, material)
            if not CurrentModel then return end;
            for part, orig in pairs(OriginalProps) do
                if part and part.Parent then
                    if enabled then
                        part.Color = color or Color3.fromRGB(255, 255, 255);
                        part.Material = material or Enum.Material.Neon;
                        part.Transparency = transparency or 0.35;
                    else
                        part.Color = orig.Color;
                        part.Material = orig.Material;
                        part.Transparency = orig.Transparency;
                    end;
                end;
            end;
        end;

        function ESPPreviewObj:ResetCamera()
            Yaw = 0;
            Pitch = 0;
            Distance = 8.2;
            UpdateCamera();
        end;

        function ESPPreviewObj:SetModel(newModel)
            SetupModel(newModel);
        end;

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = ESPPreviewObj;
        return ESPPreviewObj;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(14, 14, 14);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 15, 0, 15);
        Size = UDim2.new(0, 240, 0, 24);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(18, 18, 18);
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'OutlineColor';
    });

    local WatermarkTopAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 205;
        Parent = WatermarkInner;
    });

    Library:AddToRegistry(WatermarkTopAccent, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local WatermarkIcon = Library:Create('ImageLabel', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 5, 0.5, 1);
        AnchorPoint = Vector2.new(0, 0.5);
        Size = UDim2.fromOffset(14, 14);
        Image = '';
        ScaleType = Enum.ScaleType.Fit;
        ZIndex = 204;
        Visible = false;
        Parent = WatermarkInner;
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0);
        Size = UDim2.new(1, -16, 1, 0);
        TextSize = 13;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = WatermarkInner;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkInner = WatermarkInner;
    Library.WatermarkTopAccent = WatermarkTopAccent;
    Library.WatermarkIcon = WatermarkIcon;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

Library.DefaultLogoUrl = 'https://github.com/xvbxvvv/logo/blob/main/0fb782bd-42a8-46bd-8a52-7df5bee0812a.jpg?raw=true';

function Library:GetCustomAsset(url, filename)
    if not url or url == '' then return '' end
    if url:find('^rbxasset') then return url end

    local user, repo, branch, file = url:match('github%.com/([^/]+)/([^/]+)/blob/([^/]+)/([^%?]+)')
    local rawUrl = url
    if user and repo and branch and file then
        rawUrl = string.format('https://raw.githubusercontent.com/%s/%s/%s/%s', user, repo, branch, file)
    end

    filename = filename or 'gamesense_custom_asset.jpg'

    local customAssetFunc = getcustomasset or getsynasset
    if customAssetFunc and writefile and readfile and isfile then
        if not isfile(filename) then
            if isfile('gamesense/' .. filename) then
                filename = 'gamesense/' .. filename
            else
                local ok, content = pcall(function()
                    return game:HttpGet(rawUrl)
                end)
                if ok and content and #content > 0 then
                    pcall(writefile, filename, content)
                end
            end
        end

        if isfile(filename) then
            local ok, asset = pcall(customAssetFunc, filename)
            if ok and asset then
                return asset
            end
        end
    end

    return rawUrl
end;

function Library:SetWatermarkIcon(url)
    if not Library.WatermarkIcon then return end
    if url == false then
        Library.WatermarkIcon.Visible = false
        Library.WatermarkIcon.Image = ''
        UpdateWatermarkDisplay()
        return
    end

    url = (type(url) == 'string' and url) or Library.DefaultLogoUrl
    Library.WatermarkIcon.Visible = true

    task.spawn(function()
        local asset = Library:GetCustomAsset(url, 'gamesense_watermark_logo.jpg')
        if asset and asset ~= '' and Library.WatermarkIcon then
            Library.WatermarkIcon.Image = asset
            Library.WatermarkIcon.Visible = true
            UpdateWatermarkDisplay()
        end
    end)
end;

function Library:SetFont(url, filename)
    url = url or Library.CustomFontUrl
    filename = filename or Library.CustomFontName or 'Minecraftia-Regular.ttf'

    task.spawn(function()
        local asset = Library:GetCustomAsset(url, filename)
        if asset and asset ~= '' then
            local okFont, fontObj = pcall(Font.new, asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            if okFont and fontObj then
                Library.FontFace = fontObj
                if ScreenGui then
                    for _, inst in ipairs(ScreenGui:GetDescendants()) do
                        if inst:IsA('TextLabel') or inst:IsA('TextBox') or inst:IsA('TextButton') then
                            pcall(function() inst.FontFace = fontObj end)
                        end
                    end
                end
            end
        end
    end)
end;

task.spawn(function()
    Library:SetFont();
end);

Library.WatermarkTitle = 'gamesense.pub';
local WatermarkFps = 60;
local WatermarkPing = 0;
local LastFpsUpdate = 0;

local function StripTags(str)
    return str:gsub('<[^>]->', '');
end;

local function UpdateWatermarkDisplay()
    if not Library.Watermark or not Library.Watermark.Visible then return end;

    local base = Library.WatermarkTitle or 'gamesense.pub';
    local coloredBase = base;

    local r = math.floor(Library.AccentColor.R * 255);
    local g = math.floor(Library.AccentColor.G * 255);
    local b = math.floor(Library.AccentColor.B * 255);
    local accentHex = string.format('rgb(%d,%d,%d)', r, g, b);

    if coloredBase:find('sense') and not coloredBase:find('<font') then
        coloredBase = coloredBase:gsub('game', '<font color="rgb(255,255,255)">game</font>')
                                 :gsub('sense', string.format('<font color="%s">sense</font>', accentHex))
                                 :gsub('%.pub', '<font color="rgb(255,255,255)">.pub</font>');
    elseif coloredBase:find(' - ') and not coloredBase:find('<font') then
        local p1, p2 = coloredBase:match('^(.-)(%s*-%s*.*)$');
        if p1 and p2 then
            coloredBase = string.format('<font color="%s">%s</font><font color="rgb(255,255,255)">%s</font>', accentHex, p1, p2);
        end;
    end;
    if coloredBase:find('Demo') and not coloredBase:find('<font color=.-Demo') then
        coloredBase = coloredBase:gsub('Demo', string.format('<font color="%s">Demo</font>', accentHex));
    end;

    local richText;
    if Library.WatermarkShowStats == false then
        richText = coloredBase;
    else
        richText = string.format('%s <font color="rgb(90,90,90)">|</font> <font color="%s">%d</font> fps <font color="rgb(90,90,90)">|</font> <font color="%s">%d</font> ms', coloredBase, accentHex, WatermarkFps, accentHex, WatermarkPing);
    end;
    Library.WatermarkText.Text = richText;

    local plain = StripTags(richText);
    local X, _ = Library:GetTextBounds(plain, Library.Font, 13);

    local hasIcon = Library.WatermarkIcon and Library.WatermarkIcon.Visible and Library.WatermarkIcon.Image ~= '';
    local iconOffset = hasIcon and 22 or 0;

    if Library.WatermarkText then
        Library.WatermarkText.Position = UDim2.new(0, hasIcon and 24 or 8, 0, 0);
        Library.WatermarkText.Size = UDim2.new(1, -(hasIcon and 28 or 16), 1, 0);
    end;

    Library.Watermark.Size = UDim2.new(0, X + 18 + iconOffset, 0, 24);
end;

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    if os.clock() - LastFpsUpdate >= 0.25 then
        LastFpsUpdate = os.clock();
        WatermarkFps = math.floor(1 / math.max(0.001, Delta));
        pcall(function()
            local stats = game:GetService('Stats');
            WatermarkPing = math.floor(stats.Network.ServerStatsItem['Data Ping']:GetValue());
        end);
        UpdateWatermarkDisplay();
    end;
end));

function Library:SetWatermark(Text, IconUrl)
    if type(Text) == 'string' and Text:len() > 0 then
        Library.WatermarkTitle = Text;
    end;
    if IconUrl ~= nil then
        Library:SetWatermarkIcon(IconUrl);
    elseif Library.WatermarkIcon and Library.WatermarkIcon.Image == '' then
        Library:SetWatermarkIcon(Library.DefaultLogoUrl);
    end;
    Library:SetWatermarkVisibility(true);
    UpdateWatermarkDisplay();
end;

function Library:SetNotifySide(Side)
    if not Library.NotificationArea then return end
    if Side == 'Right' or Side == 'right' then
        Library.NotificationArea.Position = UDim2.new(1, -310, 0, 40)
    else
        Library.NotificationArea.Position = UDim2.new(0, 0, 0, 40)
    end
end;

function Library:Notify(Text, Time)
    if type(Text) == 'table' then
        Time = Time or Text.Time;
        local body = Text.Content or Text.Text or '';
        if Text.Title and Text.Title ~= '' then
            Text = Text.Title .. ': ' .. body;
        else
            Text = body;
        end;
    end;
    Text = tostring(Text or '');

    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    -- la notif ne doit jamais dépasser de l'écran (mobile)
    do
        local Cam = workspace.CurrentCamera;
        local VP = (Cam and Cam.ViewportSize.X > 0) and Cam.ViewportSize or ScreenGui.AbsoluteSize;
        XSize = math.min(XSize, math.max(120, VP.X - 112));
    end;

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

-- ══════════════════════════════════════════════════════════════
--  THEMEMANAGER  (intégré directement dans lib.lua)
-- ══════════════════════════════════════════════════════════════
local httpService = game:GetService('HttpService')

local isfile = isfile or function(path) return false end
local isfolder = isfolder or function(path) return false end
local makefolder = makefolder or function(path) end
local readfile = readfile or function(path) return nil end
local writefile = writefile or function(path, content) end
local listfiles = listfiles or function(path) return {} end
local delfile = (delfile or (syn and syn.delfile)) or function(path) end

local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	ThemeManager.Library = Library
	ThemeManager.DefaultTheme = 'Gamesense'
	ThemeManager.BuiltInThemes = {
		['Gamesense']       = { 1, httpService:JSONDecode('{"FontColor":"e6e6e6","MainColor":"141414","AccentColor":"a8ff00","BackgroundColor":"0c0c0c","OutlineColor":"282828"}') },
		['ezwin.cc'] 		= { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"121214","AccentColor":"ffffff","BackgroundColor":"08080a","OutlineColor":"282830"}') },
		['Liquid Glass']	= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d1020","AccentColor":"88aaff","BackgroundColor":"080c18","OutlineColor":"1e2440"}') },
		['Default'] 		= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot'] 			= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 11, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		self.Library = self.Library or Library or getgenv().Library
		if not self.Library then return end
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]
		if not data then return end
		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			pcall(function()
				self.Library[idx] = Color3.fromHex(col)
				if Options and Options[idx] and Options[idx].SetValueRGB then
					Options[idx]:SetValueRGB(Color3.fromHex(col))
				end
			end)
		end
		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		self.Library = self.Library or Library or getgenv().Library
		if not self.Library then return end
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] and Options[field].Value then
				self.Library[field] = Options[field].Value
			end
		end
		if self.Library.GetDarkerColor and self.Library.AccentColor then
			self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
		end
		if self.Library.UpdateColorsUsingRegistry then
			self.Library:UpdateColorsUsingRegistry()
		end
	end

	function ThemeManager:LoadDefault()
		local theme = 'Gamesense'
		local path = self.Folder .. '/themes/default.txt'
		local hasFile = false
		pcall(function() hasFile = isfile(path) end)
		local content
		if hasFile then
			pcall(function() content = readfile(path) end)
		end
		local isDefault = true
		if content and content ~= '' then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			theme = self.DefaultTheme
		end
		if isDefault then
			if Options and Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.SetValue then
				Options.ThemeManager_ThemeList:SetValue(theme)
			else
				self:ApplyTheme(theme)
			end
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		if not theme or theme == '' then return end
		self:BuildFolderTree()
		pcall(function()
			writefile(self.Folder .. '/themes/default.txt', theme)
		end)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		self.Library = self.Library or Library or getgenv().Library
		local lib = self.Library
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = lib.BackgroundColor })
		groupbox:AddLabel('Main color'):AddColorPicker('MainColor', { Default = lib.MainColor })
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = lib.AccentColor })
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = lib.OutlineColor })
		groupbox:AddLabel('Font color'):AddColorPicker('FontColor', { Default = lib.FontColor })

		groupbox:AddToggle('ThemeManager_RainbowAccent', {
			Text = 'Rainbow Accent',
			Default = false,
			Tooltip = 'Cycle la couleur d\'accentuation automatiquement',
			Callback = function(Value)
				if Value then
					task.spawn(function()
						while Toggles.ThemeManager_RainbowAccent and Toggles.ThemeManager_RainbowAccent.Value do
							local hue = (tick() % 5) / 5
							local color = Color3.fromHSV(hue, 0.8, 1)
							self.Library.AccentColor = color
							self.Library.AccentColorDark = self.Library:GetDarkerColor(color)
							if Options and Options.AccentColor then
								Options.AccentColor:SetValueRGB(color)
							else
								self.Library:UpdateColorsUsingRegistry()
							end
							task.wait(0.05)
						end
					end)
				end
			end
		})

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end
		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
		groupbox:AddButton('Set as default', function()
			if Options and Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.Value then
				self:SaveDefault(Options.ThemeManager_ThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
			end
		end)
		if Options.ThemeManager_ThemeList then
			Options.ThemeManager_ThemeList:OnChanged(function()
				if Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.Value then
					self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
				end
			end)
		end

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		groupbox:AddButton('Save theme', function()
			local name = Options.ThemeManager_CustomThemeName and Options.ThemeManager_CustomThemeName.Value
			self:SaveCustomTheme(name)
			if Options.ThemeManager_CustomThemeList then
				Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
				Options.ThemeManager_CustomThemeList:SetValue(nil)
			end
		end):AddButton('Load theme', function()
			local name = Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				self:ApplyTheme(name)
			end
		end)
		groupbox:AddButton('Overwrite theme', function()
			local name = Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				self:SaveCustomTheme(name:gsub('%.json$', ''))
				self.Library:Notify(string.format('Overwrote theme %q', name))
			end
		end):AddButton('Delete theme', function()
			local name = Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value
			if name and name ~= '' then
				local path = self.Folder .. '/themes/' .. name
				if not path:find('%.json$') then path = path .. '.json' end
				pcall(function() delfile(path) end)
				self.Library:Notify(string.format('Deleted theme %q', name))
				if Options.ThemeManager_CustomThemeList then
					Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
					Options.ThemeManager_CustomThemeList:SetValue(nil)
				end
			end
		end)
		groupbox:AddButton('Refresh list', function()
			if Options.ThemeManager_CustomThemeList then
				Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
				Options.ThemeManager_CustomThemeList:SetValue(nil)
			end
		end)
		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme() self:ThemeUpdate() end
		if Options.BackgroundColor then Options.BackgroundColor:OnChanged(UpdateTheme) end
		if Options.MainColor then Options.MainColor:OnChanged(UpdateTheme) end
		if Options.AccentColor then Options.AccentColor:OnChanged(UpdateTheme) end
		if Options.OutlineColor then Options.OutlineColor:OnChanged(UpdateTheme) end
		if Options.FontColor then Options.FontColor:OnChanged(UpdateTheme) end
	end

	function ThemeManager:GetCustomTheme(file)
		if not file or file == '' then return nil end
		local path = self.Folder .. '/themes/' .. file
		if not path:find('%.json$') then path = path .. '.json' end
		local exists = false
		pcall(function() exists = isfile(path) end)
		if not exists then return nil end
		local successRead, data = pcall(readfile, path)
		if not successRead or not data then return nil end
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		if not success or type(decoded) ~= 'table' then return nil end
		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if not file or file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end
		self:BuildFolderTree()
		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for _, field in next, fields do
			if Options[field] then
				theme[field] = Options[field].Value:ToHex()
			end
		end
		pcall(function()
			writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
		end)
		self.Library:Notify(string.format('Saved theme %q', file))
	end

	function ThemeManager:ReloadCustomThemes()
		local out = {}
		local success, list = pcall(function() return listfiles(self.Folder .. '/themes') end)
		if not success or type(list) ~= 'table' then return out end
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end
				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end
		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib or Library
	end

	function ThemeManager:BuildFolderTree()
		pcall(function()
			local paths = {}
			local parts = self.Folder:split('/')
			for idx = 1, #parts do
				paths[#paths + 1] = table.concat(parts, '/', 1, idx)
			end
			table.insert(paths, self.Folder .. '/themes')
			table.insert(paths, self.Folder .. '/settings')
			for i = 1, #paths do
				local str = paths[i]
				pcall(function()
					if not isfolder(str) then makefolder(str) end
				end)
			end
		end)
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		self.Library = self.Library or Library or getgenv().Library
		if tab.AddLeftGroupbox then
			return tab:AddLeftGroupbox('Themes')
		elseif tab.AddGroupbox then
			return tab:AddGroupbox({ Side = 1, Name = 'Themes' })
		end
		return tab
	end

	function ThemeManager:ApplyToTab(tab)
		self.Library = self.Library or Library or getgenv().Library
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
		return groupbox
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		self.Library = self.Library or Library or getgenv().Library
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

-- ══════════════════════════════════════════════════════════════
--  SAVEMANAGER  (intégré directement dans lib.lua)
-- ══════════════════════════════════════════════════════════════
local SaveManager = {} do
	SaveManager.Folder = 'LinoriaLibSettings'
	SaveManager.Library = Library
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) return { type = 'Toggle', idx = idx, value = object.Value } end,
			Load = function(idx, data) if Toggles[idx] then Toggles[idx]:SetValue(data.value) end end,
		},
		Slider = {
			Save = function(idx, object) return { type = 'Slider', idx = idx, value = tostring(object.Value) } end,
			Load = function(idx, data) if Options[idx] then Options[idx]:SetValue(data.value) end end,
		},
		Dropdown = {
			Save = function(idx, object) return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi } end,
			Load = function(idx, data) if Options[idx] then Options[idx]:SetValue(data.value) end end,
		},
		ColorPicker = {
			Save = function(idx, object) return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency } end,
			Load = function(idx, data) if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end end,
		},
		KeyPicker = {
			Save = function(idx, object) return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value } end,
			Load = function(idx, data) if Options[idx] then Options[idx]:SetValue({ data.key, data.mode }) end end,
		},
		Input = {
			Save = function(idx, object) return { type = 'Input', idx = idx, text = object.Value } end,
			Load = function(idx, data) if Options[idx] and type(data.text) == 'string' then Options[idx]:SetValue(data.text) end end,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do self.Ignore[key] = true end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if not name or name == '' then return false, 'no config file is selected' end
		self:BuildFolderTree()
		local fullPath = self.Folder .. '/settings/' .. name .. '.json'
		local data = { objects = {} }
		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			if not (toggle and toggle.Type and self.Parser[toggle.Type]) then continue end
			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end
		for idx, option in next, Options do
			if self.Ignore[idx] then continue end
			if not (option and option.Type and self.Parser[option.Type]) then continue end
			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end
		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then return false, 'failed to encode data' end
		local writeOk, writeErr = pcall(function() writefile(fullPath, encoded) end)
		if not writeOk then return false, tostring(writeErr) end
		return true
	end

	function SaveManager:Load(name)
		if not name or name == '' then return false, 'no config file is selected' end
		local file = self.Folder .. '/settings/' .. name .. '.json'
		local exists = false
		pcall(function() exists = isfile(file) end)
		if not exists then return false, 'invalid file' end
		local successRead, fileContent = pcall(readfile, file)
		if not successRead or not fileContent then return false, 'read error' end
		local success, decoded = pcall(httpService.JSONDecode, httpService, fileContent)
		if not success or type(decoded) ~= 'table' or type(decoded.objects) ~= 'table' then return false, 'decode error' end
		for _, option in next, decoded.objects do
			if option and option.type and self.Parser[option.type] then
				task.spawn(function()
					pcall(function() self.Parser[option.type].Load(option.idx, option) end)
				end)
			end
		end
		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
			'ThemeManager_RainbowAccent',
		})
	end

	function SaveManager:BuildFolderTree()
		pcall(function()
			local paths = { self.Folder, self.Folder .. '/themes', self.Folder .. '/settings' }
			for i = 1, #paths do
				local str = paths[i]
				pcall(function()
					if not isfolder(str) then makefolder(str) end
				end)
			end
		end)
	end

	function SaveManager:RefreshConfigList()
		local out = {}
		local success, list = pcall(function() return listfiles(self.Folder .. '/settings') end)
		if not success or type(list) ~= 'table' then return out end
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local start = pos
				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end
				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library or Library
	end

	function SaveManager:LoadAutoloadConfig()
		local autoPath = self.Folder .. '/settings/autoload.txt'
		local exists = false
		pcall(function() exists = isfile(autoPath) end)
		if exists then
			local successRead, name = pcall(readfile, autoPath)
			if successRead and name and name ~= '' then
				local success, err = self:Load(name)
				if not success then
					if self.Library and self.Library.Notify then
						return self.Library:Notify('Failed to load autoload config: ' .. tostring(err), 3)
					end
					return
				end
				if self.Library and self.Library.Notify then
					self.Library:Notify(string.format('Auto loaded config %q', name), 3)
				end
			end
		end
	end

	function SaveManager:BuildConfigSection(tab)
		self.Library = self.Library or Library or getgenv().Library
		local section
		if tab.AddRightGroupbox then
			section = tab:AddRightGroupbox('Configuration')
		elseif tab.AddGroupbox then
			section = tab:AddGroupbox({ Side = 2, Name = 'Configuration' })
		else
			section = tab
		end
		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })
		section:AddDivider()

		section:AddToggle('SaveManager_AutoLoadToggle', {
			Text = 'Auto load config on start',
			Default = false,
			Tooltip = 'Charge automatiquement la configuration au lancement',
			Callback = function(val)
				self.AutoLoadEnabled = val
			end
		})

		section:AddDivider()
		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value
			if not name or name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name (empty)', 2) end
			local success, err = self:Save(name)
			if not success then return self.Library:Notify('Failed to save config: ' .. tostring(err)) end
			self.Library:Notify(string.format('Created config %q', name))
			if Options.SaveManager_ConfigList then
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('No config selected', 2) end
			local success, err = self:Load(name)
			if not success then return self.Library:Notify('Failed to load config: ' .. tostring(err)) end
			self.Library:Notify(string.format('Loaded config %q', name))
		end)

		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('No config selected', 2) end
			local success, err = self:Save(name)
			if not success then return self.Library:Notify('Failed to overwrite config: ' .. tostring(err)) end
			self.Library:Notify(string.format('Overwrote config %q', name))
		end):AddButton('Delete config', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('No config selected', 2) end
			local path = self.Folder .. '/settings/' .. name .. '.json'
			local exists = false
		pcall(function() exists = isfile(path) end)
			if exists then
				pcall(function() delfile(path) end)
				self.Library:Notify(string.format('Deleted config %q', name))
				if Options.SaveManager_ConfigList then
					Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
					Options.SaveManager_ConfigList:SetValue(nil)
				end
			else
				self.Library:Notify('Config file does not exist', 2)
			end
		end)

		section:AddButton('Refresh list', function()
			if Options.SaveManager_ConfigList then
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end
		end)

		section:AddButton('Set as autoload', function()
			local name = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('No config selected', 2) end
			self:BuildFolderTree()
			pcall(function()
				writefile(self.Folder .. '/settings/autoload.txt', name)
			end)
			if SaveManager.AutoloadLabel then
				SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			end
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)

		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)
		local autoPath = self.Folder .. '/settings/autoload.txt'
		local hasAuto = false
		pcall(function() hasAuto = isfile(autoPath) end)
		if hasAuto then
			local okRead, name = pcall(readfile, autoPath)
			if okRead and name and name ~= '' then
				SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			end
		end

		SaveManager:SetIgnoreIndexes({
			'SaveManager_ConfigList', 'SaveManager_ConfigName', 'SaveManager_AutoLoadToggle',
			'MenuKeybind', 'KeybindMenuOpen', 'ShowWatermark', 'ShowCustomCursor', 'NotificationSide'
		})
		return section
	end

	SaveManager:BuildFolderTree()
end

-- Liaison immédiate ThemeManager & SaveManager à Library
ThemeManager.Library = Library
SaveManager.Library = Library

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
	'SaveManager_ConfigList', 'SaveManager_ConfigName', 'SaveManager_AutoLoadToggle',
	'MenuKeybind', 'KeybindMenuOpen', 'ShowWatermark', 'ShowCustomCursor', 'NotificationSide'
})

Library.ThemeManager = ThemeManager
Library.SaveManager = SaveManager

getgenv().Library = Library
getgenv().ThemeManager = ThemeManager
getgenv().SaveManager = SaveManager


function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(720, 560) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    --============================================================
    --  Auto size (adapte le menu à l'écran, PC & mobile)
    --============================================================
    local AutoSize = (Config.AutoSize ~= false);
    local ViewportMargin = (type(Config.Margin) == 'number') and Config.Margin or 16;
    local MinScale = (type(Config.MinScale) == 'number') and Config.MinScale or 0.62;
    local MaxScale = (type(Config.MaxScale) == 'number') and Config.MaxScale or 1;
    local MaxSizeCfg = typeof(Config.MaxSize) == 'UDim2' and Config.MaxSize or nil;

    local function GetViewport()
        local Cam = workspace.CurrentCamera;
        if Cam and Cam.ViewportSize.X > 0 then
            return Cam.ViewportSize;
        end;
        return ScreenGui.AbsoluteSize;
    end;

    -- garde le ratio d'origine ("carré") mais rentre dans l'écran
    local function GetFittedSize()
        local BaseW = math.max(Config.Size.X.Offset, 320);
        local BaseH = math.max(Config.Size.Y.Offset, 260);

        if (not AutoSize) then
            return UDim2.fromOffset(BaseW, BaseH);
        end;

        local VP = GetViewport();
        local MaxW = math.max(300, VP.X - (ViewportMargin * 2));
        local MaxH = math.max(240, VP.Y - (ViewportMargin * 2));

        -- plafond optionnel (évite un menu immense sur très grand écran)
        if MaxSizeCfg then
            MaxW = math.min(MaxW, math.max(MaxSizeCfg.X.Offset, BaseW));
            MaxH = math.min(MaxH, math.max(MaxSizeCfg.Y.Offset, BaseH));
        end;

        local Scale = math.min(MaxW / BaseW, MaxH / BaseH);
        Scale = math.clamp(Scale, MinScale, MaxScale);

        return UDim2.fromOffset(math.floor(BaseW * Scale), math.floor(BaseH * Scale));
    end;

    local Window = {
        Tabs = {};
    };

    pcall(function()
        for _, obj in ipairs(game:GetService('Lighting'):GetChildren()) do
            if obj:IsA('BlurEffect') and (obj.Name == 'GlassBlur' or obj.Size == 18) then
                obj:Destroy()
            end
        end
    end);

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.fromRGB(12, 12, 12);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = Config.Position,
        Size = GetFittedSize(),
        Visible = false,
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 8);
        Parent = Outer;
    });

    if AutoSize then
        local function RefreshWindowSize()
            if (not Outer) or (not Outer.Parent) then return end;

            Outer.Size = GetFittedSize();

            -- recentre si le menu sort de l'écran (rotation / resize mobile)
            if Outer.Position.X.Scale == 0 then
                local VP = GetViewport();
                local X = Outer.AbsolutePosition.X;
                local Y = Outer.AbsolutePosition.Y;
                local W = Outer.AbsoluteSize.X;
                local H = Outer.AbsoluteSize.Y;

                if (X + W) > (VP.X - 8) or (Y + H) > (VP.Y - 8) or X < 8 or Y < 8 then
                    Outer.Position = UDim2.fromOffset(
                        math.clamp(X, 8, math.max(8, VP.X - W - 8)),
                        math.clamp(Y, 8, math.max(8, VP.Y - H - 8))
                    );
                end;
            end;
        end;

        local Cam = workspace.CurrentCamera;

        if Cam then
            Cam:GetPropertyChangedSignal('ViewportSize'):Connect(RefreshWindowSize);
        end;

        ScreenGui:GetPropertyChangedSignal('AbsoluteSize'):Connect(RefreshWindowSize);

        task.defer(RefreshWindowSize);
    end;

    local BorderLayer = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(48, 48, 48);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 7);
        Parent = BorderLayer;
    });

    local MainContent = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = BorderLayer;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6);
        Parent = MainContent;
    });

    Library:AddToRegistry(MainContent, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TopAccent = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 6;
        Parent = MainContent;
    });

    Library:AddToRegistry(TopAccent, {
        BackgroundColor3 = 'AccentColor';
    });

    local TopTitleBar = Library:Create('Frame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 2);
        Size = UDim2.new(1, 0, 0, 22);
        ZIndex = 5;
        Active = true;
        Parent = MainContent;
    });

    local WindowLogo = Library:Create('ImageLabel', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0.5, 0);
        AnchorPoint = Vector2.new(0, 0.5);
        Size = UDim2.fromOffset(14, 14);
        Image = '';
        ScaleType = Enum.ScaleType.Fit;
        ZIndex = 6;
        Visible = false;
        Parent = TopTitleBar;
    });

    local WindowTitle = Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0);
        Size = UDim2.new(1, -16, 1, 0);
        TextSize = 13;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 6;
        Parent = TopTitleBar;
    });

    local function FormatWindowTitle(title)
        title = title or '';
        local r = math.floor(Library.AccentColor.R * 255);
        local g = math.floor(Library.AccentColor.G * 255);
        local b = math.floor(Library.AccentColor.B * 255);
        local accentHex = string.format('rgb(%d,%d,%d)', r, g, b);

        if title:find('sense') and not title:find('<font') then
            return title:gsub('game', '<font color="rgb(255,255,255)">game</font>')
                        :gsub('sense', string.format('<font color="%s">sense</font>', accentHex))
                        :gsub('%.pub', '<font color="rgb(255,255,255)">.pub</font>');
        elseif title:find(' - ') and not title:find('<font') then
            local p1, p2 = title:match('^(.-)(%s*-%s*.*)$');
            if p1 and p2 then
                return string.format('<font color="%s">%s</font><font color="rgb(255,255,255)">%s</font>', accentHex, p1, p2);
            end;
        end;
        return title;
    end;

    function Window:SetWindowTitle(Title)
        WindowTitle.Text = FormatWindowTitle(Title);
    end;

    function Window:SetLogo(url)
        if url == false then
            WindowLogo.Visible = false;
            WindowLogo.Image = '';
            WindowTitle.Position = UDim2.new(0, 8, 0, 0);
            WindowTitle.Size = UDim2.new(1, -16, 1, 0);
            return;
        end;

        url = (type(url) == 'string' and url) or Library.DefaultLogoUrl;
        task.spawn(function()
            local asset = Library:GetCustomAsset(url, 'gamesense_menu_logo.jpg');
            if asset and asset ~= '' and WindowLogo then
                WindowLogo.Image = asset;
                WindowLogo.Visible = true;
                WindowTitle.Position = UDim2.new(0, 26, 0, 0);
                WindowTitle.Size = UDim2.new(1, -34, 1, 0);
            end;
        end);
    end;

    Window:SetWindowTitle(Config.Title or 'gamesense');

    if Config.Logo ~= false then
        Window:SetLogo(type(Config.Logo) == 'string' and Config.Logo or Library.DefaultLogoUrl);
    end;

    Library:MakeDraggable(Outer, Outer, 35);
    Library:MakeDraggable(Outer, BorderLayer, 35);
    Library:MakeDraggable(Outer, MainContent, 35);
    Library:MakeDraggable(Outer, TopAccent, 35);
    Library:MakeDraggable(Outer, TopTitleBar, 35);

    local SidebarOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(15, 15, 15);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 8, 0, 26);
        Size = UDim2.new(0, 72, 1, -34);
        ZIndex = 3;
        Parent = MainContent;
    });

    Library:Create('UIStroke', {
        Color = Library.OutlineColor;
        Thickness = 1;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Parent = SidebarOuter;
    });

    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 22)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 15)),
        });
        Rotation = 90;
        Parent = SidebarOuter;
    });

    Library:AddToRegistry(SidebarOuter, {
        BackgroundColor3 = 'BackgroundColor';
    });


    local BottomTabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 1, -112);
        Size = UDim2.new(1, 0, 0, 52);
        ZIndex = 4;
        Parent = SidebarOuter;
    });

    local BottomTabLayout = Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        VerticalAlignment = Enum.VerticalAlignment.Bottom;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Padding = UDim.new(0, 6);
        Parent = BottomTabArea;
    });

    local TopTabArea = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 10);
        Size = UDim2.new(1, 0, 1, -125);
        CanvasSize = UDim2.new(0, 0, 0, 0);
        AutomaticCanvasSize = Enum.AutomaticSize.Y;
        ScrollBarThickness = 0;
        ScrollingDirection = Enum.ScrollingDirection.Y;
        Selectable = false;
        ZIndex = 4;
        Parent = SidebarOuter;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Padding = UDim.new(0, 8);
        Parent = TopTabArea;
    });

    local function UpdateSidebarLayout()
        local badgeH = 58;
        local countBottom = 0;
        for _, child in next, BottomTabArea:GetChildren() do
            if child:IsA('GuiButton') or child:IsA('Frame') then
                countBottom = countBottom + 1;
            end;
        end;

        local bottomH = countBottom > 0 and (countBottom * 42 + math.max(0, countBottom - 1) * 6 + 6) or 0;
        BottomTabArea.Size = UDim2.new(1, 0, 0, bottomH);
        BottomTabArea.Position = UDim2.new(0, 0, 1, -(badgeH + bottomH + 4));

        local totalReserved = badgeH + bottomH + 18;
        TopTabArea.Size = UDim2.new(1, 0, 1, -totalReserved);
    end;

    BottomTabLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(UpdateSidebarLayout);

    -- Profile Badge at bottom of sidebar
    -- Badge tall enough for avatar + two text lines
    local ProfileBadge = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(18, 18, 20);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 4, 1, -54);
        Size = UDim2.new(1, -8, 0, 48);
        ZIndex = 5;
        Parent = SidebarOuter;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 6);
        Parent = ProfileBadge;
    });

    Library:Create('UIStroke', {
        Color = Library.OutlineColor;
        Thickness = 1;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Parent = ProfileBadge;
    });

    -- Avatar (left side)
    local ProfileAvatar = Library:Create('ImageLabel', {
        BackgroundColor3 = Color3.fromRGB(30, 30, 35);
        BorderSizePixel = 0;
        AnchorPoint = Vector2.new(0, 0.5);
        Position = UDim2.new(0, 5, 0.5, 0);
        Size = UDim2.new(0, 28, 0, 28);
        Image = '';
        ScaleType = Enum.ScaleType.Fit;
        ZIndex = 6;
        Parent = ProfileBadge;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0);
        Parent = ProfileAvatar;
    });

    -- Online dot indicator
    local OnlineDot = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(87, 242, 135);
        BorderSizePixel = 0;
        AnchorPoint = Vector2.new(1, 1);
        Position = UDim2.new(1, 1, 1, 1);
        Size = UDim2.new(0, 8, 0, 8);
        ZIndex = 7;
        Parent = ProfileAvatar;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0);
        Parent = OnlineDot;
    });

    -- DisplayName label
    local ProfileDisplayName = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(0, 0);
        Position = UDim2.new(0, 38, 0, 6);
        Size = UDim2.new(1, -44, 0, 14);
        Text = (LocalPlayer and LocalPlayer.DisplayName or 'Player');
        TextColor3 = Library.FontColor;
        Font = Library.Font;
        TextSize = 11;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextTruncate = Enum.TextTruncate.AtEnd;
        ZIndex = 6;
        Parent = ProfileBadge;
    });

    Library:AddToRegistry(ProfileDisplayName, {
        TextColor3 = 'FontColor';
    });

    -- @username label (dimmer)
    local ProfileUsername = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(0, 0);
        Position = UDim2.new(0, 38, 0, 22);
        Size = UDim2.new(1, -44, 0, 13);
        Text = '@' .. (LocalPlayer and LocalPlayer.Name or 'Player');
        TextColor3 = Color3.fromRGB(120, 120, 120);
        Font = Library.Font;
        TextSize = 10;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextTruncate = Enum.TextTruncate.AtEnd;
        ZIndex = 6;
        Parent = ProfileBadge;
    });

    -- Load avatar async
    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size48x48
            );
        end);
        if ok and thumb and ProfileAvatar and ProfileAvatar.Parent then
            ProfileAvatar.Image = thumb;
        end;
    end);

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Color3.fromRGB(16, 16, 16);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 88, 0, 26);
        Size = UDim2.new(1, -96, 1, -34);
        ZIndex = 2;
        Parent = MainContent;
    });

    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, 5);
        Parent = TabContainer;
    });

    Library:Create('UIStroke', {
        Color = Library.OutlineColor;
        Thickness = 1;
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
        Parent = TabContainer;
    });

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'BackgroundColor';
    });

    -- TabContainer must not be draggable to allow child ScrollingFrames to scroll properly

    function Window:SelectTab(TabTarget)
        if type(TabTarget) == 'string' then
            for Name, TabObj in next, Window.Tabs do
                if Name:lower() == TabTarget:lower() then
                    TabObj:ShowTab();
                    return TabObj;
                end;
            end;
        elseif type(TabTarget) == 'table' and TabTarget.ShowTab then
            TabTarget:ShowTab();
            return TabTarget;
        elseif type(TabTarget) == 'number' and Window.TabsList and Window.TabsList[TabTarget] then
            Window.TabsList[TabTarget]:ShowTab();
            return Window.TabsList[TabTarget];
        end;
    end;

    function Window:AddTab(...)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local Name, Icon, TabConfig
        local firstArg = ...
        if type(firstArg) == 'table' then
            TabConfig = firstArg
            Name = TabConfig.Name or TabConfig.Title or 'Tab'
            Icon = TabConfig.Icon
        else
            Name = select(1, ...) or 'Tab'
            Icon = select(2, ...)
            TabConfig = select(3, ...) or {}
        end

        local ResolvedIcon = Icon;
        if type(ResolvedIcon) == 'number' then
            ResolvedIcon = 'rbxassetid://' .. tostring(ResolvedIcon);
        elseif type(ResolvedIcon) == 'string' and ResolvedIcon:match('^%d+$') then
            ResolvedIcon = 'rbxassetid://' .. ResolvedIcon;
        elseif not ResolvedIcon then
            ResolvedIcon = Library.Icons[Name] or Library.Icons.Default;
        elseif Library.Icons[ResolvedIcon] then
            ResolvedIcon = Library.Icons[ResolvedIcon];
        end;

        local lowerName = Name:lower();
        local lowerIcon = type(Icon) == 'string' and Icon:lower() or '';
        local isBottom = false
        if type(TabConfig) == 'table' and (TabConfig.Position == 'Bottom' or TabConfig.Bottom == true or TabConfig.Side == 'Bottom') then
            isBottom = true
        else
            isBottom = (lowerName == 'settings' or lowerName == 'configs' or lowerName == 'config' or lowerName == 'ui settings' or lowerIcon == 'settings');
        end
        local targetParent = isBottom and BottomTabArea or TopTabArea;

        local TabButton = Library:Create('ImageButton', {
            BackgroundColor3 = Color3.fromRGB(24, 24, 28);
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 42, 0, 42);
            Image = ResolvedIcon;
            ImageColor3 = Color3.fromRGB(120, 120, 130);
            ScaleType = Enum.ScaleType.Fit;
            ZIndex = 5;
            Parent = targetParent;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, 6);
            Parent = TabButton;
        });

        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0.5, -8);
            Size = UDim2.new(0, 2, 0, 16);
            Visible = false;
            ZIndex = 6;
            Parent = TabButton;
        });

        Library:Create('UICorner', {
            CornerRadius = UDim.new(1, 0);
            Parent = TabIndicator;
        });

        Library:AddToRegistry(TabIndicator, {
            BackgroundColor3 = 'AccentColor';
        });

        Library:AddToolTip(Name, TabButton);

        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                TabButton.ImageColor3 = Color3.fromRGB(190, 190, 195);
                TabButton.BackgroundTransparency = 0.6;
            end;
        end);

        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                TabButton.ImageColor3 = Color3.fromRGB(120, 120, 130);
                TabButton.BackgroundTransparency = 1;
            end;
        end);

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8, 0, 8);
            Size = UDim2.new(0.5, -12, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 4;
            ScrollBarImageColor3 = Library.AccentColor;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollingDirection = Enum.ScrollingDirection.Y;
            Selectable = false;
            Active = true;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4, 0, 8);
            Size = UDim2.new(0.5, -12, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 4;
            ScrollBarImageColor3 = Library.AccentColor;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollingDirection = Enum.ScrollingDirection.Y;
            Selectable = false;
            Active = true;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local FullSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8, 0, 8);
            Size = UDim2.new(1, -16, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarThickness = 4;
            ScrollBarImageColor3 = Library.AccentColor;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollingDirection = Enum.ScrollingDirection.Y;
            Selectable = false;
            Active = true;
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 14);
            PaddingBottom = UDim.new(0, 14);
            PaddingLeft = UDim.new(0, 2);
            PaddingRight = UDim.new(0, 2);
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 14);
            PaddingBottom = UDim.new(0, 14);
            PaddingLeft = UDim.new(0, 2);
            PaddingRight = UDim.new(0, 2);
            Parent = RightSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 10);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = FullSide;
        });

        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 14);
            PaddingBottom = UDim.new(0, 14);
            PaddingLeft = UDim.new(0, 2);
            PaddingRight = UDim.new(0, 2);
            Parent = FullSide;
        });

        for _, Side in next, { LeftSide, RightSide, FullSide } do
            local layout = Side:WaitForChild('UIListLayout');
            local function UpdateCanvas()
                local contentH = layout.AbsoluteContentSize.Y;
                Side.CanvasSize = UDim2.fromOffset(0, contentH + 28);
            end;
            layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(UpdateCanvas);
            Side:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateCanvas);
            task.defer(UpdateCanvas);
        end;

        function Tab:ShowTab()
            for _, t in next, Window.Tabs do
                t:HideTab();
            end;

            Window.ActiveTab = Tab;
            TabButton.ImageColor3 = Color3.fromRGB(255, 255, 255);
            TabButton.BackgroundTransparency = 0.45;
            TabIndicator.Visible = true;
            TabFrame.Visible = true;

            for _, Groupbox in next, Tab.Groupboxes do
                if Groupbox.Resize then Groupbox:Resize(); end;
            end;
            for _, Tabbox in next, Tab.Tabboxes do
                for _, SubTab in next, Tabbox.Tabs do
                    if SubTab.Resize then SubTab:Resize(); end;
                end;
            end;
        end;

        function Tab:HideTab()
            TabButton.ImageColor3 = Color3.fromRGB(120, 120, 130);
            TabButton.BackgroundTransparency = 1;
            TabIndicator.Visible = false;
            TabFrame.Visible = false;
        end;

        local function OnTabButtonClicked()
            if Library:MouseIsOverOpenedFrame() then return end;
            Tab:ShowTab();
        end;

        TabButton.MouseButton1Click:Connect(OnTabButtonClicked);
        TabButton.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Tab:ShowTab();
            end;
        end);

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local isLeft = true;
            local isFull = false;
            local boxName = 'Groupbox';
            if type(Info) == 'table' then
                if Info.Side == 'Full' or Info.Side == 'full' or Info.Side == 3 or Info.Full then
                    isFull = true;
                elseif Info.Side == 2 or Info.Side == 'Right' or Info.Side == 'right' then
                    isLeft = false;
                end;
                boxName = Info.Name or Info.Title or boxName;
            elseif type(Info) == 'string' then
                boxName = Info;
            end;

            local parentSide = isFull and FullSide or (isLeft and LeftSide or RightSide);

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 50);
                ClipsDescendants = false;
                ZIndex = 2;
                Parent = parentSide;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 5);
                Parent = BoxOuter;
            });

            Library:Create('UIStroke', {
                Color = Library.OutlineColor;
                Thickness = 1;
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Parent = BoxOuter;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 27)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 16)),
                });
                Rotation = 90;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local titleWidth = Library:GetTextBounds(boxName, Library.Font, 13) + 10;
            local GroupboxLabel = Library:CreateLabel({
                BackgroundColor3 = Library.BackgroundColor;
                BackgroundTransparency = 0;
                BorderSizePixel = 0;
                Size = UDim2.new(0, titleWidth, 0, 14);
                Position = UDim2.new(0, 12, 0, -7);
                TextSize = 13;
                Text = boxName;
                TextColor3 = Library.FontColor;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 5;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(GroupboxLabel, {
                BackgroundColor3 = 'BackgroundColor';
                TextColor3 = 'FontColor';
            });

            -- UICorner on label bg
            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 3);
                Parent = GroupboxLabel;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 10);
                Size = UDim2.new(1, -16, 1, -14);
                ZIndex = 3;
                Parent = BoxOuter;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Padding = UDim.new(0, 4);
                Parent = Container;
            });

            function Groupbox:Resize()
                local layout = Container:FindFirstChildOfClass('UIListLayout');
                local contentHeight = 0;

                if layout and layout.AbsoluteContentSize.Y > 0 then
                    contentHeight = layout.AbsoluteContentSize.Y;
                else
                    local count = 0;
                    for _, Element in next, Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            contentHeight = contentHeight + Element.Size.Y.Offset;
                            count = count + 1;
                        end;
                    end;
                    if count > 1 then
                        contentHeight = contentHeight + (count - 1) * 4;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, contentHeight + 22);
            end;

            local cLayout = Container:FindFirstChildOfClass('UIListLayout');
            if cLayout then
                cLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    Groupbox:Resize();
                end);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[boxName] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddFullGroupbox(Name)
            return Tab:AddGroupbox({ Side = 'Full'; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
                ActiveTab = nil;
            };

            local isFull = false;
            local parentSide = LeftSide;
            local tabboxName = 'Tabbox';
            if type(Info) == 'table' then
                if Info.Side == 'Full' or Info.Side == 'full' or Info.Side == 3 or Info.Full then
                    isFull = true;
                    parentSide = FullSide;
                elseif Info.Side == 2 or Info.Side == 'Right' or Info.Side == 'right' then
                    parentSide = RightSide;
                else
                    parentSide = LeftSide;
                end;
                tabboxName = Info.Name or tabboxName;
            elseif type(Info) == 'string' then
                tabboxName = Info;
                isFull = true;
                parentSide = FullSide;
            end;

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = parentSide;
            });

            Library:Create('UICorner', {
                CornerRadius = UDim.new(0, 5);
                Parent = BoxOuter;
            });

            Library:Create('UIStroke', {
                Color = Library.OutlineColor;
                Thickness = 1;
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 0, 32);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(TabboxButtons, {
                BackgroundColor3 = 'MainColor';
            });

            local TabboxDivider = Library:Create('Frame', {
                BackgroundColor3 = Library.OutlineColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 0, 32);
                Size = UDim2.new(1, 0, 0, 1);
                ZIndex = 6;
                Parent = BoxInner;
            });

            Library:AddToRegistry(TabboxDivider, {
                BackgroundColor3 = 'OutlineColor';
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            local function RefreshTabboxButtonWidths()
                local count = 0;
                for _, btn in next, TabboxButtons:GetChildren() do
                    if not btn:IsA('UIListLayout') then
                        count = count + 1;
                    end;
                end;
                if count > 0 then
                    for _, btn in next, TabboxButtons:GetChildren() do
                        if not btn:IsA('UIListLayout') then
                            btn.Size = UDim2.new(1 / count, 0, 1, 0);
                        end;
                    end;
                end;
            end;

            function Tabbox:AddTab(Name)
                local SubTab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 7;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, -2);
                    TextSize = 14;
                    Text = Name;
                    TextColor3 = Color3.fromRGB(150, 150, 150);
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 8;
                    Parent = Button;
                });

                local ActiveIndicator = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, -2);
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(ActiveIndicator, {
                    BackgroundColor3 = 'AccentColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 6, 0, 38);
                    Size = UDim2.new(1, -12, 1, -44);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                local subLayout = Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Padding = UDim.new(0, 4);
                    Parent = Container;
                });

                function SubTab:Show()
                    for _, otherTab in next, Tabbox.Tabs do
                        otherTab:Hide();
                    end;

                    Tabbox.ActiveTab = SubTab;
                    Container.Visible = true;
                    ActiveIndicator.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    ButtonLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    SubTab:Resize();
                end;

                function SubTab:Hide()
                    Container.Visible = false;
                    ActiveIndicator.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    ButtonLabel.TextColor3 = Color3.fromRGB(150, 150, 150);
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function SubTab:Resize()
                    RefreshTabboxButtonWidths();

                    if (not Container.Visible) then
                        return;
                    end;

                    local contentHeight = 0;
                    if subLayout and subLayout.AbsoluteContentSize.Y > 0 then
                        contentHeight = subLayout.AbsoluteContentSize.Y;
                    else
                        for _, Element in next, Container:GetChildren() do
                            if (not Element:IsA('UIListLayout')) and Element.Visible then
                                contentHeight = contentHeight + Element.Size.Y.Offset;
                            end;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 42 + contentHeight + 10);
                end;

                subLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    if Container.Visible then
                        SubTab:Resize();
                    end;
                end);

                Button.MouseEnter:Connect(function()
                    if not Container.Visible then
                        Button.BackgroundColor3 = Color3.fromRGB(32, 34, 42);
                        ButtonLabel.TextColor3 = Color3.fromRGB(210, 210, 210);
                    end;
                end);

                Button.MouseLeave:Connect(function()
                    if not Container.Visible then
                        Button.BackgroundColor3 = Library.MainColor;
                        ButtonLabel.TextColor3 = Color3.fromRGB(150, 150, 150);
                    end;
                end);

                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        SubTab:Show();
                    end;
                end);

                SubTab.Container = Container;
                Tabbox.Tabs[Name] = SubTab;

                setmetatable(SubTab, BaseGroupbox);

                SubTab:AddBlank(3);
                RefreshTabboxButtonWidths();
                SubTab:Resize();

                -- Show the first added tab by default
                if Tabbox.ActiveTab == nil then
                    SubTab:Show();
                end;

                return SubTab;
            end;

            Tab.Tabboxes[tabboxName] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        function Tab:AddFullTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 'Full'; });
        end;

        Window.TabsList = Window.TabsList or {};
        table.insert(Window.TabsList, Tab);
        Window.Tabs[Name] = Tab;

        UpdateSidebarLayout();

        -- Show first added tab by default
        if Window.ActiveTab == nil then
            Tab:ShowTab();
        end;

        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;

    function Library:Toggle()
        if Fading then
            return;
        end;

        local FadeTime = Config.MenuFadeTime;
        Fading = true;
        Toggled = (not Toggled);
        ModalElement.Modal = Toggled;

        if Toggled then
            -- A bit scuffed, but if we're going from not toggled -> toggled we want to show the frame immediately so that the fade is visible.
            Outer.Visible = true;
        end;

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {};

            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency');
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency');
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency');
            end;

            local Cache = TransparencyCache[Desc];

            if (not Cache) then
                Cache = {};
                TransparencyCache[Desc] = Cache;
            end;

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop];
                end;

                if Cache[Prop] == 1 then
                    continue;
                end;

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
            end;
        end;

        task.wait(FadeTime);

        Outer.Visible = Toggled;

        Fading = false;
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    --============================================================
    --  Bouton flottant d'ouverture (mobile / tactile : pas de clavier)
    --============================================================
    local OpenButton = Library:Create('TextButton', {
        BackgroundColor3 = Library.AccentColor;
        BorderColor3 = Library.AccentColorDark;
        BorderMode = Enum.BorderMode.Inset;
        AnchorPoint = Vector2.new(1, 0.5);
        Position = UDim2.new(1, -20, 0.5, 0);
        Size = UDim2.new(0, 46, 0, 46);
        Text = 'GS';
        TextColor3 = Color3.new(1, 1, 1);
        TextSize = 16;
        Font = Library.Font;
        AutoButtonColor = false;
        ZIndex = 50;
        Visible = IsTouch;
        Parent = ScreenGui;
    });

    Library:AddToRegistry(OpenButton, {
        BackgroundColor3 = 'AccentColor';
        BorderColor3 = 'AccentColorDark';
    });

    -- déplaçable + tap pour ouvrir/fermer (tactile et souris)
    Library:GiveSignal(OpenButton.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
            and Input.UserInputType ~= Enum.UserInputType.Touch then
            return;
        end;

        local startPos = Vector2.new(Input.Position.X, Input.Position.Y);
        local startAbs = OpenButton.AbsolutePosition;
        local moved = false;
        local dragging = true;
        local activeInput = Input;

        local moveConn
        local endConn

        local function Disconnect()
            dragging = false;
            if moveConn then moveConn:Disconnect(); moveConn = nil; end;
            if endConn then endConn:Disconnect(); endConn = nil; end;
        end;

        moveConn = InputService.InputChanged:Connect(function(moveInput)
            if not dragging then return end;

            local isMatch = (moveInput == activeInput)
                or (activeInput.UserInputType == Enum.UserInputType.Touch and moveInput.UserInputType == Enum.UserInputType.Touch)
                or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and moveInput.UserInputType == Enum.UserInputType.MouseMovement);

            if isMatch and moveInput.Position then
                local dx = moveInput.Position.X - startPos.X;
                local dy = moveInput.Position.Y - startPos.Y;

                if (math.abs(dx) > 6) or (math.abs(dy) > 6) then
                    moved = true;
                end;

                local VP = GetViewport();
                local W, H = OpenButton.AbsoluteSize.X, OpenButton.AbsoluteSize.Y;

                OpenButton.AnchorPoint = Vector2.zero;
                OpenButton.Position = UDim2.fromOffset(
                    math.clamp(startAbs.X + dx, 6, math.max(6, VP.X - W - 6)),
                    math.clamp(startAbs.Y + dy, 6, math.max(6, VP.Y - H - 6))
                );
            end;
        end);

        endConn = InputService.InputEnded:Connect(function(endInput)
            if endInput == activeInput
                or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and endInput.UserInputType == Enum.UserInputType.MouseButton1)
                or (activeInput.UserInputType == Enum.UserInputType.Touch and endInput.UserInputType == Enum.UserInputType.Touch) then
                Disconnect();
                if not moved then
                    Library:Toggle();
                end;
            end;
        end);

        activeInput.Changed:Connect(function()
            if activeInput.UserInputState == Enum.UserInputState.End
                or activeInput.UserInputState == Enum.UserInputState.Cancel then
                Disconnect();
            end;
        end);
    end));

    if Config.AutoShow then task.spawn(Library.Toggle) end


    Window.ThemeManager = ThemeManager;
    Window.SaveManager = SaveManager;

    function Window:CreateSettingsTab(SettingsConfig)
        if Window.SettingsTab then
            return Window.SettingsTab;
        end;

        SettingsConfig = SettingsConfig or {};
        local TabName = SettingsConfig.Title or SettingsConfig.Name or 'Settings';
        local TabIcon = SettingsConfig.Icon or 'settings';

        local SettingsTab = Window:AddTab({
            Name = TabName,
            Icon = TabIcon,
            Position = 'Bottom',
        });
        Window.SettingsTab = SettingsTab;

        -- Dossier unifié de sauvegarde
        local folder = SettingsConfig.Folder or Config.Folder or Config.SettingsFolder or 'gamesense';
        local configFolder = SettingsConfig.ConfigFolder or Config.ConfigFolder or folder .. '/configs';

        -- 1. Thèmes (côté GAUCHE - groupe entier dédié)
        pcall(function()
            ThemeManager:SetLibrary(Library);
            ThemeManager:SetFolder(folder);
            ThemeManager:ApplyToTab(SettingsTab);
        end);

        -- 2. Configurations / Sauvegardes (côté DROIT - haut)
        pcall(function()
            SaveManager:SetLibrary(Library);
            SaveManager:IgnoreThemeSettings();
            SaveManager:SetIgnoreIndexes({
                'SaveManager_ConfigList', 'SaveManager_ConfigName', 'SaveManager_AutoLoadToggle',
                'MenuKeybind', 'KeybindMenuOpen', 'ShowWatermark', 'ShowCustomCursor', 'NotificationSide'
            });
            SaveManager:SetFolder(configFolder);
            SaveManager:BuildConfigSection(SettingsTab);
        end);

        -- 3. Menu Configuration (côté DROIT - sous la Configuration)
        local MenuBox = SettingsTab:AddRightGroupbox('Menu Configuration');

        if Library.KeybindFrame then
            MenuBox:AddToggle('KeybindMenuOpen', {
                Text = 'Show Keybinds Window',
                Default = false,
                Callback = function(v)
                    if Library.KeybindFrame then
                        Library.KeybindFrame.Visible = v;
                    end;
                end,
            });
        end;

        MenuBox:AddToggle('ShowWatermark', {
            Text = 'Show Watermark',
            Default = true,
            Callback = function(v)
                if Library.SetWatermarkVisibility then
                    Library:SetWatermarkVisibility(v);
                end;
            end,
        });

        MenuBox:AddToggle('ShowCustomCursor', {
            Text = 'Custom Cursor',
            Default = Library.ShowCustomCursor or false,
            Callback = function(v)
                Library.ShowCustomCursor = v;
            end,
        });

        if Library.SetNotifySide then
            MenuBox:AddDropdown('NotificationSide', {
                Text = 'Notification Side',
                Values = { 'Left', 'Right' },
                Default = 2,
                Callback = function(v)
                    Library:SetNotifySide(v);
                end,
            });
        end;

        MenuBox:AddDivider();

        MenuBox:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
            Default = SettingsConfig.DefaultKeybind or Config.DefaultKeybind or 'RightShift',
            NoUI = true,
            Mode = 'Toggle',
            Text = 'Menu keybind',
        });

        MenuBox:AddButton('Unload gamesense', function()
            Library:Unload();
        end);

        if Options.MenuKeybind then
            Library.ToggleKeybind = Options.MenuKeybind;
        end;

        -- 4. Auto-load des thèmes & configs par défaut
        task.defer(function()
            pcall(function() ThemeManager:LoadDefault() end);
            pcall(function() SaveManager:LoadAutoloadConfig() end);
        end);

        return SettingsTab;
    end;

    -- Support Config.Folder
    if Config.Folder then
        pcall(function()
            ThemeManager:SetFolder(Config.Folder);
            SaveManager:SetFolder(Config.ConfigFolder or (Config.Folder .. '/configs'));
        end);
    end;

    -- Auto-création du tab Settings par défaut (désactivable via AutoSettings = false)
    if Config.AutoSettings ~= false then
        task.defer(function()
            if not Window.SettingsTab then
                Window:CreateSettingsTab(type(Config.AutoSettings) == 'table' and Config.AutoSettings or {
                    Folder = Config.Folder or Config.SettingsFolder,
                    ConfigFolder = Config.ConfigFolder,
                    DefaultKeybind = Config.DefaultKeybind,
                });
            end;
        end);
    end;

    Window.Holder = Outer;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

getgenv().Library = Library


-- ══════════════════════════════════════════════════════════════
--  RETURN : Library, ThemeManager, SaveManager
--  Usage  : local Library, ThemeManager, SaveManager = loadstring(...)()
-- ══════════════════════════════════════════════════════════════
return Library, ThemeManager, SaveManager
