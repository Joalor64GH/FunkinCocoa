package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;

using StringTools;

class Tankmen extends FlxSprite
{
	public var tankSpeed:Float = 1700;
	public var goingRight:Bool = false;

	var runAnimPlayedTimes:Int = 0;
	var runAnimPlayedTimesMax:Int = 1;

	override public function new()
	{
		super();
		frames = Paths.getSparrowAtlas("stages/warzone/tankmanKilled1");
		antialiasing = true;
		animation.addByPrefix("run", "tankman running", 24, false);
		animation.addByPrefix("shot", "John Shot " + FlxG.random.int(1, 2), 24, false);
		animation.play("run");

		// scrollFactor.set();
		updateHitbox();
		setGraphicSize(Std.int(width * 0.8));
	}

	public function resetShit(xPos:Float, yPos:Float, right:Bool, ?stepsMax:Int, ?speedModifier:Float = 1)
	{
		x = xPos;
		y = yPos;
		goingRight = right;
		if (stepsMax == null)
			stepsMax = 1;

		if (speedModifier == null)
			speedModifier = 1;

		runAnimPlayedTimesMax = stepsMax;

		var newSpeedModifier:Float = speedModifier * 2;

		tankSpeed = FlxG.random.float(0.6, 1) * 250;

		if (goingRight)
		{
			velocity.x = tankSpeed * newSpeedModifier;
			if (animation.curAnim.name == "shot")
			{
				offset.x = 300;
				velocity.x = 0;
			}
		}
		else
		{
			velocity.x = tankSpeed * (newSpeedModifier * -1);

			if (animation.curAnim.name == "shot")
				velocity.x = 0;
		}
	}

	override public function update(elapsed:Float)
	{
		if (goingRight == true)
		{
			if (animation.curAnim.name == "shot")
			{
				offset.x = 400;
				velocity.x = 10;
			}

			flipX = true;
		}
		else
		{
			flipX = false;

			if (animation.curAnim.name == "shot")
			{
				offset.x = 0;
				velocity.x = 10;
			}
		}

		super.update(elapsed);

		if (animation.curAnim.name == "run" && animation.curAnim.finished == true && runAnimPlayedTimes < runAnimPlayedTimesMax)
		{
			animation.play("run", true);
			runAnimPlayedTimes++;
		}

		if (animation.curAnim.name == "run" && animation.curAnim.finished == true && runAnimPlayedTimes >= runAnimPlayedTimesMax)
		{
			animation.play("shot", true);
			runAnimPlayedTimes = 0;
		}

		if (animation.curAnim.name == "shot" && animation.curAnim.curFrame >= animation.curAnim.frames.length - 1)
		{
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				alpha -= 0.2;

				if (alpha == 0)
					destroy();
			}, 5);
		}
	}
}

typedef TankmenSpawn =
{
	public var right:Array<Int>;
	public var left:Array<Int>;
}

typedef Pico =
{
	public var right:Array<Int>;
	public var left:Array<Int>;
}
