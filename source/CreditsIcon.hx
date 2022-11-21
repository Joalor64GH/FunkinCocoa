package;

import flixel.FlxSprite;

class CreditsIcon extends FlxSprite
{
	public var offsetX:Null<Float> = 0;
	public var offsetY:Null<Float> = 0;
	public var alphabet:Alphabet;

	public function new(name:String)
	{
		super();

		loadGraphic(Paths.image('credits/$name'));
		antialiasing = !FunkySettings.noAntialiasing;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (alphabet != null)
		{
			setPosition(alphabet.x - 155 + offsetX, alphabet.y + offsetY);
			alpha = alphabet.alpha;
		}
	}
}
