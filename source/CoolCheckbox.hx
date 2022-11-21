package;

import flixel.FlxSprite;

class CoolCheckbox extends FlxSprite
{
	public var tracker:FlxSprite;
	public var daValue(default, set):Bool;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked = false)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('UI/checkboxanim');
		animation.addByPrefix("unchecked", "checkbox0", 24, false);
		animation.addByPrefix("unchecking", "checkbox anim reverse", 24, false);
		animation.addByPrefix("checking", "checkbox anim0", 24, false);
		animation.addByPrefix("checked", "checkbox finish", 24, false);

		antialiasing = !FunkySettings.noAntialiasing;
		setGraphicSize(Std.int(0.9 * width));
		updateHitbox();

		playAnim(checked ? 'checking' : 'unchecking');
		animation.finishCallback = animationFinished;
	}

	override function update(elapsed:Float)
	{
		if (tracker != null)
		{
			setPosition(tracker.x - 130 + offsetX, tracker.y + 30 + offsetY);

			if (copyAlpha)
				alpha = tracker.alpha;
		}
		super.update(elapsed);
	}

	public function playAnim(name:String, force:Bool = true)
	{
		animation.play(name, force);

		if (name == 'checking')
			offset.set(34, 25);
		else if (name == 'unchecking')
			offset.set(25, 28);
		else
			offset.set();
	}

	function set_daValue(check:Bool):Bool
	{
		if (check)
		{
			if (animation.curAnim.name != 'checked' && animation.curAnim.name != 'checking')
			{
				animation.play('checking', true);
				offset.set(34, 25);
			}
		}
		else if (animation.curAnim.name != 'unchecked' && animation.curAnim.name != 'unchecking')
		{
			animation.play("unchecking", true);
			offset.set(25, 28);
		}

		return daValue = check;
	}

	function animationFinished(name:String)
	{
		switch (name)
		{
			case 'checking':
				animation.play('checked', true);
				offset.set(3, 12);

			case 'unchecking':
				animation.play('unchecked', true);
				offset.set(0, 2);
		}
	}
}
