--! Tween.luau
--! Tween helpers with sane defaults and cleanup tracking.

local TweenService = game:GetService("TweenService")

export type TweenOpts = {
	time: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?,
	repeatCount: number?,
	reverses: boolean?,
	delayTime: number?,
	completed: (() -> ())?,
}

local function defaultOpts(opts: TweenOpts?): TweenInfo
	local o = opts or {}
	return TweenInfo.new(
		o.time or 0.3,
		o.easingStyle or Enum.EasingStyle.Quad,
		o.easingDirection or Enum.EasingDirection.Out,
		o.repeatCount or 0,
		o.reverses or false,
		o.delayTime or 0
	)
end

local Tween = {}

function Tween.create(instance: Instance, props: { [string]: any }, opts: TweenOpts?): TweenBase
	return TweenService:Create(instance, defaultOpts(opts), props)
end

function Tween.play(instance: Instance, props: { [string]: any }, opts: TweenOpts?): TweenBase
	local t = Tween.create(instance, props, opts)
	t:Play()
	return t
end

-- Convenience used by UI fades. Mirrors Tween.play + optional completed callback.
function Tween.To(instance: Instance, props: { [string]: any }, opts: TweenOpts?): TweenBase
	local o = opts or {}
	local t = Tween.create(instance, props, o)
	if o.completed ~= nil then
		t.Completed:Connect(o.completed)
	end
	t:Play()
	return t
end

return Tween
