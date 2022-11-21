package;

import flixel.FlxSprite;

class EventNote extends FlxSprite
{
	public var event:String;
	public var strumTime:Float;
	public var val1:String;
	public var val2:String;
	public var val3:String;
	public var childs:Array<AbsoluteFlxText>;

	public function new(event:String, strumTime:Float, val1:String, val2:String, val3:String)
	{
		this.event = event;
		this.strumTime = strumTime;
		this.val1 = val1;
		this.val2 = val2;
		this.val3 = val3;

		super();

		antialiasing = !FunkySettings.noAntialiasing;
		loadGraphic(Paths.image('eventArrow'));
	}
}
