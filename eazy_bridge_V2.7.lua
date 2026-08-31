-- StarterPlayer > StarterPlayerScripts の中の LocalScript に配置してください

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- 状態管理（メイン機能）
local isBreakableEnabled = true
local isMainPanelVisible = true
local maxDistance = 80
local trackedParts = {}

-- 状態管理（プレイヤー機能GUI）
local isEspEnabled = false
local maxEspDistance = 200 -- ESPの表示距離上限
local isInvisible = false
local isPlayerPanelVisible = true
local walkSpeedValue = 16
local jumpPowerValue = 50
local trackedPlayers = {}

-- オープンチャットリンク
local OC_LINK = "https://line.me/ti/g2/PQE3S6_ciPLpS5qKSy8nY0nSUV8tvBa4V4bewA?utm_source=invitation&utm_medium=link_copy&utm_campaign=default"

-- アニメーション設定
local tweenBounce = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local tweenElastic = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenSlow = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- 骨格の接続定義 (R15 / R6 両対応)
local BONE_PAIRS = {
	{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
	{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

-- ==========================================
-- 頭上ネームタグ（モノトーン）
-- ==========================================
local function createHeadNameTag(character)
	if not character then return end
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local oldTag = head:FindFirstChild("LeionHeadTag")
	if oldTag then oldTag:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LeionHeadTag"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0) -- 頭上タグ位置
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "LEION on top"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBlack
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = label

	billboard.Parent = character
end

if localPlayer.Character then createHeadNameTag(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(createHeadNameTag)

-- ==========================================
-- 1. ロード画面（黒白基調）
-- ==========================================
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "ReionLoadingGui"
loadingGui.DisplayOrder = 999
loadingGui.ResetOnSpawn = false
loadingGui.Parent = playerGui

local loadBg = Instance.new("Frame")
loadBg.Size = UDim2.new(1, 0, 1, 0)
loadBg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
loadBg.BorderSizePixel = 0
loadBg.Parent = loadingGui

local loadContent = Instance.new("Frame")
loadContent.Size = UDim2.new(0, 300, 0, 230)
loadContent.Position = UDim2.new(0.5, -150, 0.4, -40)
loadContent.BackgroundTransparency = 1
loadContent.Parent = loadBg

-- ロード画面用デカール画像
local loadDecal = Instance.new("ImageLabel")
loadDecal.Name = "LoadDecal"
loadDecal.Size = UDim2.new(0, 80, 0, 80)
loadDecal.Position = UDim2.new(0.5, -40, 0, 0)
loadDecal.BackgroundTransparency = 1
loadDecal.Image = "rbxassetid://110433489567363"
loadDecal.ScaleType = Enum.ScaleType.Fit
loadDecal.Parent = loadContent

local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Position = UDim2.new(0, 0, 0, 90)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "SYSTEM INITIALIZING"
loadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadTitle.TextSize = 20
loadTitle.Font = Enum.Font.GothamBlack
loadTitle.Parent = loadContent

local loadCredit = Instance.new("TextLabel")
loadCredit.Size = UDim2.new(1, 0, 0, 20)
loadCredit.Position = UDim2.new(0, 0, 0, 122)
loadCredit.BackgroundTransparency = 1
loadCredit.Text = "CREATED BY れいおん"
loadCredit.TextColor3 = Color3.fromRGB(180, 180, 180)
loadCredit.TextSize = 12
loadCredit.Font = Enum.Font.GothamBold
loadCredit.Parent = loadContent

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -40, 0, 4)
barBg.Position = UDim2.new(0, 20, 0, 165)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBg.BorderSizePixel = 0
barBg.Parent = loadContent

Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local function showUnsupportedNotice()
	local noticeFrame = Instance.new("Frame")
	noticeFrame.Size = UDim2.new(0, 280, 0, 110)
	noticeFrame.Position = UDim2.new(0.5, -140, 0.4, -55)
	noticeFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	noticeFrame.BorderSizePixel = 0
	noticeFrame.Parent = playerGui:WaitForChild("ReionMainGui", 5) or playerGui

	Instance.new("UICorner", noticeFrame).CornerRadius = UDim.new(0, 10)
	local noticeStroke = Instance.new("UIStroke", noticeFrame)
	noticeStroke.Color = Color3.fromRGB(255, 255, 255)
	noticeStroke.Thickness = 1.5

	local noticeTitle = Instance.new("TextLabel")
	noticeTitle.Size = UDim2.new(1, 0, 0, 30)
	noticeTitle.Position = UDim2.new(0, 0, 0, 10)
	noticeTitle.BackgroundTransparency = 1
	noticeTitle.Text = "SYSTEM NOTICE"
	noticeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	noticeTitle.TextSize = 15
	noticeTitle.Font = Enum.Font.GothamBlack
	noticeTitle.Parent = noticeFrame

	local noticeMsg = Instance.new("TextLabel")
	noticeMsg.Size = UDim2.new(1, -20, 0, 35)
	noticeMsg.Position = UDim2.new(0, 10, 0, 38)
	noticeMsg.BackgroundTransparency = 1
	noticeMsg.Text = "対象パーツが見つかりませんでした"
	noticeMsg.TextColor3 = Color3.fromRGB(180, 180, 180)
	noticeMsg.TextSize = 12
	noticeMsg.Font = Enum.Font.GothamBold
	noticeMsg.Parent = noticeFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, -40, 0, 24)
	closeBtn.Position = UDim2.new(0, 20, 0, 75)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "閉じる"
	closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	closeBtn.TextSize = 11
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = noticeFrame

	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.Activated:Connect(function() noticeFrame:Destroy() end)
	task.delay(8, function() if noticeFrame then noticeFrame:Destroy() end end)
end

-- ==========================================
-- UIヘルパー
-- ==========================================
local function enableDragging(frame)
	local dragging, dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function createButton(parent, name, text, isON, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 180, 0, 30)
	btn.BackgroundColor3 = isON and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
	btn.Text = text
	btn.TextColor3 = isON and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBlack
	btn.AutoButtonColor = false
	btn.LayoutOrder = layoutOrder
	btn.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = btn

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, tweenFast, {BackgroundTransparency = 0.2}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, tweenFast, {BackgroundTransparency = 0}):Play()
	end)

	return btn
end

local function toggleBtnAnim(btn, state)
	local targetBg = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
	local targetText = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
	TweenService:Create(btn, tweenFast, {BackgroundColor3 = targetBg, TextColor3 = targetText}):Play()
end

local function createValueControl(parent, titleText, defaultVal, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 180, 0, 44)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	frame.LayoutOrder = layoutOrder
	frame.Parent = parent

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(60, 60, 60)
	stroke.Thickness = 1

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.Position = UDim2.new(0, 0, 0, 2)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.TextSize = 10
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = frame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 0, 20)
	box.Position = UDim2.new(0, 10, 0, 20)
	box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 11
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.Parent = frame

	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(80, 80, 80)
	boxStroke.Thickness = 1

	return lbl, box
end

-- ==========================================
-- 2-A. メインパネル GUI (左下)
-- ==========================================
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ReionMainGui"
mainGui.ResetOnSpawn = false
mainGui.Enabled = false
mainGui.Parent = playerGui

local MAIN_OPEN_POS = UDim2.new(0, 15, 1, -210)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 185)
mainFrame.Position = MAIN_OPEN_POS
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = mainGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 1.5

local mainScroll = Instance.new("ScrollingFrame")
mainScroll.Size = UDim2.new(1, 0, 1, -25)
mainScroll.Position = UDim2.new(0, 0, 0, 25)
mainScroll.BackgroundTransparency = 1
mainScroll.BorderSizePixel = 0
mainScroll.ScrollBarThickness = 2
mainScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
mainScroll.CanvasSize = UDim2.new(0, 0, 0, 150)
mainScroll.Parent = mainFrame

local mainList = Instance.new("UIListLayout")
mainList.Padding = UDim.new(0, 6)
mainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Parent = mainScroll

local mainCredit = Instance.new("TextLabel")
mainCredit.Size = UDim2.new(1, -20, 0, 20)
mainCredit.Position = UDim2.new(0, 10, 0, 4)
mainCredit.BackgroundTransparency = 1
mainCredit.Text = "CREATED BY れいおん"
mainCredit.TextColor3 = Color3.fromRGB(150, 150, 150)
mainCredit.TextSize = 10
mainCredit.Font = Enum.Font.GothamBold
mainCredit.TextXAlignment = Enum.TextXAlignment.Left
mainCredit.Parent = mainFrame

enableDragging(mainFrame)

local breakableBtn = createButton(mainScroll, "BreakableBtn", "崩れるパーツ [ON]", true, 1)
local distTitle, distBox = createValueControl(mainScroll, "崩れる検知距離: " .. maxDistance .. "m", maxDistance, 2)
local copyBtn1 = createButton(mainScroll, "CopyOcButton", "🔗 OC リンクコピー", false, 3)

local mainHideBtn = Instance.new("TextButton")
mainHideBtn.Size = UDim2.new(0, 28, 0, 28)
mainHideBtn.Position = UDim2.new(1, 6, 0, 0)
mainHideBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
mainHideBtn.Text = "◄"
mainHideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainHideBtn.TextSize = 12
mainHideBtn.Font = Enum.Font.GothamBlack
mainHideBtn.AutoButtonColor = false
mainHideBtn.Parent = mainFrame

Instance.new("UICorner", mainHideBtn).CornerRadius = UDim.new(0, 6)
local hideStroke = Instance.new("UIStroke", mainHideBtn)
hideStroke.Color = Color3.fromRGB(255, 255, 255)
hideStroke.Thickness = 1

local lastMainX = 15
mainHideBtn.Activated:Connect(function()
	isMainPanelVisible = not isMainPanelVisible
	local curYScale, curYOff = mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset
	if isMainPanelVisible then
		mainHideBtn.Text = "◄"
		TweenService:Create(mainFrame, tweenBounce, {Position = UDim2.new(mainFrame.Position.X.Scale, lastMainX, curYScale, curYOff)}):Play()
	else
		mainHideBtn.Text = "►"
		lastMainX = mainFrame.Position.X.Offset
		TweenService:Create(mainFrame, tweenBounce, {Position = UDim2.new(0, -205, curYScale, curYOff)}):Play()
	end
end)

-- ==========================================
-- 2-B. プレイヤーコントローラー GUI (右下)
-- ==========================================
local playerGuiGroup = Instance.new("ScreenGui")
playerGuiGroup.Name = "ReionPlayerGui"
playerGuiGroup.ResetOnSpawn = false
playerGuiGroup.Enabled = false
playerGuiGroup.Parent = playerGui

local espCanvasGui = Instance.new("ScreenGui")
espCanvasGui.Name = "ReionEspCanvas"
espCanvasGui.ResetOnSpawn = false
espCanvasGui.DisplayOrder = 10
espCanvasGui.Parent = playerGui

local PLAYER_OPEN_POS = UDim2.new(1, -215, 1, -330)
local playerFrame = Instance.new("Frame")
playerFrame.Name = "PlayerFrame"
playerFrame.Size = UDim2.new(0, 200, 0, 310)
playerFrame.Position = PLAYER_OPEN_POS
playerFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playerFrame.BackgroundTransparency = 0.1
playerFrame.BorderSizePixel = 0
playerFrame.Parent = playerGuiGroup

Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0, 10)
local playerStroke = Instance.new("UIStroke", playerFrame)
playerStroke.Color = Color3.fromRGB(255, 255, 255)
playerStroke.Thickness = 1.5

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, 0, 1, -25)
playerScroll.Position = UDim2.new(0, 0, 0, 25)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 2
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 280)
playerScroll.Parent = playerFrame

local playerList = Instance.new("UIListLayout")
playerList.Padding = UDim.new(0, 6)
playerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
playerList.SortOrder = Enum.SortOrder.LayoutOrder
playerList.Parent = playerScroll

local playerTitle = Instance.new("TextLabel")
playerTitle.Size = UDim2.new(1, -20, 0, 20)
playerTitle.Position = UDim2.new(0, 10, 0, 4)
playerTitle.BackgroundTransparency = 1
playerTitle.Text = "PLAYER CONTROLLER"
playerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerTitle.TextSize = 10
playerTitle.Font = Enum.Font.GothamBlack
playerTitle.TextXAlignment = Enum.TextXAlignment.Left
playerTitle.Parent = playerFrame

enableDragging(playerFrame)

local espBtn = createButton(playerScroll, "EspBtn", "プレイヤーESP [OFF]", false, 1)
local espDistTitle, espDistBox = createValueControl(playerScroll, "ESP表示距離: " .. maxEspDistance .. "m", maxEspDistance, 2)
local invisBtn = createButton(playerScroll, "InvisBtn", "透明化 [OFF]", false, 3)
local speedTitle, speedBox = createValueControl(playerScroll, "移動速度 (Default: 16)", 16, 4)
local jumpTitle, jumpBox = createValueControl(playerScroll, "ジャンプ力 (Default: 50)", 50, 5)

local playerHideBtn = Instance.new("TextButton")
playerHideBtn.Size = UDim2.new(0, 28, 0, 28)
playerHideBtn.Position = UDim2.new(0, -34, 0, 0)
playerHideBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playerHideBtn.Text = "►"
playerHideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerHideBtn.TextSize = 12
playerHideBtn.Font = Enum.Font.GothamBlack
playerHideBtn.AutoButtonColor = false
playerHideBtn.Parent = playerFrame

Instance.new("UICorner", playerHideBtn).CornerRadius = UDim.new(0, 6)
local pHideStroke = Instance.new("UIStroke", playerHideBtn)
pHideStroke.Color = Color3.fromRGB(255, 255, 255)
pHideStroke.Thickness = 1

local lastPlayerX = -215
playerHideBtn.Activated:Connect(function()
	isPlayerPanelVisible = not isPlayerPanelVisible
	local curYScale, curYOff = playerFrame.Position.Y.Scale, playerFrame.Position.Y.Offset
	if isPlayerPanelVisible then
		playerHideBtn.Text = "►"
		TweenService:Create(playerFrame, tweenBounce, {Position = UDim2.new(1, lastPlayerX, curYScale, curYOff)}):Play()
	else
		playerHideBtn.Text = "◄"
		lastPlayerX = playerFrame.Position.X.Offset
		TweenService:Create(playerFrame, tweenBounce, {Position = UDim2.new(1, 5, curYScale, curYOff)}):Play()
	end
end)

-- ==========================================
-- 3. ESP (距離指定/モノトーン/Bone/Box/Name)
-- ==========================================
local function createPlayerESP(player)
	if player == localPlayer then return end

	local espData = {
		box = Instance.new("Frame"),
		boxStroke = Instance.new("UIStroke"),
		infoLabel = Instance.new("TextLabel"),
		infoStroke = Instance.new("UIStroke"),
		bones = {},
		char = nil
	}

	espData.box.BackgroundTransparency = 1
	espData.box.BorderSizePixel = 0
	espData.box.Visible = false
	espData.box.Parent = espCanvasGui

	espData.boxStroke.Color = Color3.fromRGB(255, 255, 255)
	espData.boxStroke.Thickness = 1.2
	espData.boxStroke.Parent = espData.box

	espData.infoLabel.BackgroundTransparency = 1
	espData.infoLabel.Size = UDim2.new(0, 200, 0, 30)
	espData.infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	espData.infoLabel.TextSize = 11
	espData.infoLabel.Font = Enum.Font.GothamBlack
	espData.infoLabel.Visible = false
	espData.infoLabel.Parent = espCanvasGui

	espData.infoStroke.Color = Color3.fromRGB(0, 0, 0)
	espData.infoStroke.Thickness = 1.5
	espData.infoStroke.Parent = espData.infoLabel

	for i = 1, #BONE_PAIRS do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Visible = false
		line.Parent = espCanvasGui
		table.insert(espData.bones, line)
	end

	local function setupChar(char) espData.char = char end
	if player.Character then setupChar(player.Character) end
	player.CharacterAdded:Connect(setupChar)

	trackedPlayers[player] = espData
end

for _, p in ipairs(Players:GetPlayers()) do createPlayerESP(p) end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(function(p)
	if trackedPlayers[p] then
		local data = trackedPlayers[p]
		data.box:Destroy()
		data.infoLabel:Destroy()
		for _, b in ipairs(data.bones) do b:Destroy() end
		trackedPlayers[p] = nil
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local myChar = localPlayer.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for player, data in pairs(trackedPlayers) do
		local char = data.char
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if isEspEnabled and char and hrp and hum and hum.Health > 0 and myHrp then
			local dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
			local hrpPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

			if onScreen and dist <= maxEspDistance then
				local cframe, size = char:GetBoundingBox()
				local offsetVector = Vector3.new(0, 3.0, 0) -- 上方向へ+3.0スタッド移動
				
				-- 枠線 (Box) の描画位置変更
				local topPos = camera:WorldToViewportPoint((cframe * CFrame.new(0, size.Y/2, 0)).Position + offsetVector)
				local bottomPos = camera:WorldToViewportPoint((cframe * CFrame.new(0, -size.Y/2, 0)).Position + offsetVector)
				local height = math.abs(topPos.Y - bottomPos.Y)
				local width = height * 0.55

				data.box.Size = UDim2.new(0, width, 0, height)
				data.box.Position = UDim2.new(0, topPos.X - width/2, 0, topPos.Y)
				data.box.Visible = true

				data.infoLabel.Text = string.format("👤 %s\n[%dm]", player.DisplayName, dist)
				data.infoLabel.Position = UDim2.new(0, topPos.X - 100, 0, topPos.Y - 38)
				data.infoLabel.Visible = true

				-- 骨格線 (Bone) の描画位置変更（各関節位置に+3.0スタッド追加）
				for i, pair in ipairs(BONE_PAIRS) do
					local partA = char:FindFirstChild(pair[1])
					local partB = char:FindFirstChild(pair[2])
					local line = data.bones[i]

					if partA and partB and line then
						local posA, visA = camera:WorldToViewportPoint(partA.Position + offsetVector)
						local posB, visB = camera:WorldToViewportPoint(partB.Position + offsetVector)

						if visA and visB then
							local startVec = Vector2.new(posA.X, posA.Y)
							local endVec = Vector2.new(posB.X, posB.Y)
							local distance = (endVec - startVec).Magnitude
							local center = (startVec + endVec) / 2
							local angle = math.atan2(endVec.Y - startVec.Y, endVec.X - startVec.X)

							line.Size = UDim2.new(0, distance, 0, 1)
							line.Position = UDim2.new(0, center.X, 0, center.Y)
							line.Rotation = math.deg(angle)
							line.Visible = true
						else
							line.Visible = false
						end
					elseif line then
						line.Visible = false
					end
				end
			else
				data.box.Visible = false
				data.infoLabel.Visible = false
				for _, b in ipairs(data.bones) do b.Visible = false end
			end
		else
			data.box.Visible = false
			data.infoLabel.Visible = false
			for _, b in ipairs(data.bones) do b.Visible = false end
		end
	end

	-- 移動速度 & 強制ジャンプ
	if myChar then
		local hum = myChar:FindFirstChildOfClass("Humanoid")
		if hum and myHrp then
			hum.WalkSpeed = walkSpeedValue
			if walkSpeedValue > 16 and hum.MoveDirection.Magnitude > 0 then
				local extraSpeed = walkSpeedValue - 16
				myHrp.CFrame = myHrp.CFrame + (hum.MoveDirection * (extraSpeed * deltaTime))
			end
			if hum.Jump and jumpPowerValue > 50 then
				myHrp.AssemblyLinearVelocity = Vector3.new(
					myHrp.AssemblyLinearVelocity.X,
					jumpPowerValue * 1.2,
					myHrp.AssemblyLinearVelocity.Z
				)
			end
		end

		for _, part in ipairs(myChar:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				if part.Name ~= "HumanoidRootPart" and isInvisible then
					part.Transparency = 1
				end
			end
		end
	end
end)

-- ==========================================
-- 4. Breakable 追跡機能
-- ==========================================
local function createTrackerUI(part)
	if trackedParts[part] then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BreakableTracker"
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 110, 0, 28)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false

	local tagFrame = Instance.new("Frame")
	tagFrame.Size = UDim2.new(0, 0, 0, 0)
	tagFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	tagFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	tagFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	tagFrame.BackgroundTransparency = 0.2
	tagFrame.BorderSizePixel = 0
	tagFrame.Parent = billboard

	Instance.new("UICorner", tagFrame).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", tagFrame)
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "崩れる ❌"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 11
	label.Font = Enum.Font.GothamBlack
	label.Parent = tagFrame

	billboard.Parent = mainGui
	trackedParts[part] = {gui = billboard, frame = tagFrame, isVisible = false}

	part.AncestryChanged:Connect(function(_, parent)
		if not parent and trackedParts[part] then
			billboard:Destroy()
			trackedParts[part] = nil
		end
	end)
end

local floatOffset = 0
RunService.RenderStepped:Connect(function(dt)
	floatOffset = floatOffset + dt * 2
	local yOffset = math.sin(floatOffset) * 0.2
	local character = localPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	for part, data in pairs(trackedParts) do
		if data and data.gui and part:IsA("BasePart") then
			data.gui.StudsOffset = Vector3.new(0, 2.2 + yOffset, 0)
			if isBreakableEnabled and hrp then
				local distance = (hrp.Position - part.Position).Magnitude
				if distance <= maxDistance then
					if not data.isVisible then
						data.isVisible = true
						data.gui.Enabled = true
						TweenService:Create(data.frame, tweenElastic, {Size = UDim2.new(1, 0, 1, 0)}):Play()
					end
				else
					if data.isVisible then
						data.isVisible = false
						data.gui.Enabled = false
					end
				end
			else
				if data.isVisible then
					data.isVisible = false
					data.gui.Enabled = false
				end
			end
		end
	end
end)

-- ==========================================
-- 5. イベント接続
-- ==========================================
breakableBtn.Activated:Connect(function()
	isBreakableEnabled = not isBreakableEnabled
	breakableBtn.Text = isBreakableEnabled and "崩れるパーツ [ON]" or "崩れるパーツ [OFF]"
	toggleBtnAnim(breakableBtn, isBreakableEnabled)
end)

espBtn.Activated:Connect(function()
	isEspEnabled = not isEspEnabled
	espBtn.Text = isEspEnabled and "プレイヤーESP [ON]" or "プレイヤーESP [OFF]"
	toggleBtnAnim(espBtn, isEspEnabled)
end)

invisBtn.Activated:Connect(function()
	isInvisible = not isInvisible
	invisBtn.Text = isInvisible and "透明化 [ON]" or "透明化 [OFF]"
	toggleBtnAnim(invisBtn, isInvisible)

	if not isInvisible then
		local char = localPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
				elseif part:IsA("Decal") then
					part.Transparency = 0
				end
			end
		end
	end
end)

distBox.FocusLost:Connect(function()
	local num = tonumber(distBox.Text)
	if num then
		maxDistance = math.clamp(math.floor(num), 5, 2000)
		distTitle.Text = "崩れる検知距離: " .. maxDistance .. "m"
	end
end)

espDistBox.FocusLost:Connect(function()
	local num = tonumber(espDistBox.Text)
	if num then
		maxEspDistance = math.clamp(math.floor(num), 5, 2000)
		espDistTitle.Text = "ESP表示距離: " .. maxEspDistance .. "m"
	end
end)

speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text)
	if num then walkSpeedValue = math.clamp(num, 0, 500) end
end)

jumpBox.FocusLost:Connect(function()
	local num = tonumber(jumpBox.Text)
	if num then jumpPowerValue = math.clamp(num, 0, 500) end
end)

copyBtn1.Activated:Connect(function()
	if setclipboard then setclipboard(OC_LINK) end
	copyBtn1.Text = "✅ コピーしました！"
	task.delay(2, function() copyBtn1.Text = "🔗 OC リンクコピー" end)
end)

-- ==========================================
-- 6. パーツ判定・初期化
-- ==========================================
local function isBreakable(instance)
	if not instance:IsA("BasePart") then return false end
	if instance:GetAttribute("breakable") ~= nil or instance:FindFirstChild("breakable") ~= nil then return true end
	local name = instance.Name:lower()
	if name:find("glass") or name:find("break") or name:find("fall") or name:find("fake") or name:find("trap") then return true end
	return false
end

task.spawn(function()
	local tweenBar = TweenService:Create(barFill, tweenSlow, {Size = UDim2.new(1, 0, 1, 0)})
	tweenBar:Play()
	
	local foundBreakable = false
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if isBreakable(instance) then
			foundBreakable = true
			createTrackerUI(instance)
		end
	end

	Workspace.DescendantAdded:Connect(function(instance)
		if isBreakable(instance) then createTrackerUI(instance) end
	end)

	tweenBar.Completed:Wait()
	mainGui.Enabled = true
	playerGuiGroup.Enabled = true
	loadingGui:Destroy()

	if not foundBreakable then showUnsupportedNotice() end
end)
