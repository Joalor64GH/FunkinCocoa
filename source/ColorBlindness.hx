package;

import openfl.filters.ColorMatrixFilter;

enum ColorBlindnessFilter
{
	NONE;
	DEUTERANOPIA;
	PROTANOPIA;
	TRITANOPIA;
}

/**
	An optional color filter for color blind people.
**/
final class ColorBlindness extends ColorMatrixFilter
{
	public static var colorFilters:Array<ColorBlindnessFilter> = [NONE, DEUTERANOPIA, PROTANOPIA, TRITANOPIA];

	public var filterEnabled:Bool = true;

	public function new(type:ColorBlindnessFilter)
	{
		filterEnabled = type != NONE;

		if (!filterEnabled)
			return;

		var filter:Array<Float> = [];
		switch (type)
		{
			case DEUTERANOPIA:
				filter = [
					0.43, 0.72, -.15, 0, 0,
					0.34, 0.57, 0.09, 0, 0,
					-.02, 0.03,    1, 0, 0,
					   0,    0,    0, 1, 0,
				];
			case PROTANOPIA:
				filter = [
					0.20, 0.99, -.19, 0, 0,
					0.16, 0.79, 0.04, 0, 0,
					0.01, -.01,    1, 0, 0,
					   0,    0,    0, 1, 0,
				];
			case TRITANOPIA:
				filter = [
					0.97, 0.11, -.08, 0, 0,
					0.02, 0.82, 0.16, 0, 0,
					0.06, 0.88, 0.18, 0, 0,
					   0,    0,    0, 1, 0,
				];
			default:
		}

		super(filter);
	}

	public static function setFilter()
	{
		Main.ColorFilter = new ColorBlindness(FunkySettings.colorFilter);

		@:privateAccess
		if (FlxG.game._filters == null)
			FlxG.game._filters = [];

		if (FunkySettings.colorFilter != NONE)
		{
			FlxG.game.setFilters([Main.ColorFilter]);
		}
		else
		{
			FlxG.game.setFilters([]);
		}
	}
}