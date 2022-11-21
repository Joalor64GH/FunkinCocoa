package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var tracker:FlxSprite;
	public var animated:Bool;

	var isOldIcon:Bool = false;
	var isPlayer:Bool = false;
	var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (tracker != null)
			setPosition(tracker.x + tracker.width + 10, tracker.y - 30);
	}

	public function changeIcon(char:String):Void
	{
		if (this.char != char)
		{
			var name:String = 'icons/$char';

			if (!Paths.exists('images/$name.png'))
				name = 'icons/face'; // Prevents crash from missing icon

			var graphic:FlxGraphic = Paths.image(name);
			var animd:Bool = Paths.exists('images/$name.xml');
			var jsonAtlas:Bool = false;
			if (!animd)
			{
				animd = Paths.exists('images/$name.json');
				jsonAtlas = animd;
			}
			animated = animd;

			if (!animd)
			{
				// load the image with no function at all just for getting width and height size
				loadGraphic(graphic);
				loadGraphic(graphic, true, Std.int(width / 2), Std.int(height));
				// then load the real graphic

				animation.add(char, [0, 1], 0, false, isPlayer);
				animation.play(char);
			}
			else
			{	
				frames = jsonAtlas ? Paths.getJsonAtlas(name) : Paths.getSparrowAtlas(name);
				animation.addByPrefix('idle', 'idle');
				animation.addByPrefix('dead', 'dead');
				animation.play('idle');
			}

			this.char = char;

			antialiasing = !FunkySettings.noAntialiasing;

			if (char.endsWith('-pixel'))
				antialiasing = false;
		}
	}

	override public function updateHitbox()
	{
		//if you don't actually update the hitbox it looks better
		centerOrigin();
	}

	public function getCharacter():String
	{
		return char;
	}
}
