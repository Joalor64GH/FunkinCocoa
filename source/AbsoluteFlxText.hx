package;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUIText;

final class AbsoluteFlxText extends FlxUIText
{
	public var tracker:FlxSprite;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float, y:Float, FieldWidth:Float = 0, Text:String = "", Size:Int = 8)
	{
		super(x, y, FieldWidth, Text, Size);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (tracker != null)
		{
			setPosition(tracker.x + offsetX, tracker.y + offsetY);
			angle = tracker.angle;
			alpha = tracker.alpha;
		}
	}
}
