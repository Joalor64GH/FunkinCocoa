package;

class AbsoluteAlphabet extends Alphabet
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var tracker:Alphabet;

	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold = false, ?scale:Float = 1)
	{
		super(0, 0, text, bold, 0.05, scale);
		isMenuItem = false;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	override function update(elapsed:Float)
	{
		if (tracker != null)
			setPosition(tracker.x + offsetX, tracker.y + offsetY);

		super.update(elapsed);
	}
}
