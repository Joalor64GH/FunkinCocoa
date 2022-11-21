var boyfriend:Boyfriend;

function onChangeFramerate()
{
	if (FunkySettings.framerate > FlxG.drawFramerate)
	{
		FlxG.updateFramerate = FunkySettings.framerate;
		FlxG.drawFramerate = FunkySettings.framerate;
	}
	else
	{
		FlxG.drawFramerate = FunkySettings.framerate;
		FlxG.updateFramerate = FunkySettings.framerate;
	}
}

public function create()
{
	title = 'Graphics';

	var character:String = 'bf';

	if (FlxG.random.bool(10))
		character = 'bf-holding-gf';

	var option:Option = new Option('Low Quality', [
		'Game will disable some details to improve performance.',
		"Game won't disable anything."
	], 'lowGraphics', 'bool');
	addOption(option);

	var option:Option = new Option('No Antialiasing', [
		"Your game's performance will be increased\nat the cost of looking sharper.",
		'Your game will look more pleasing\nat the cost of your performance based on your device.'
	], 'noAntialiasing', 'bool');
	addOption(option);

	var option:Option = new Option('Framerate', ["Pretty self explanatory, isn't it?"], 'framerate', 'int');
	option.minValue = 60;
	option.maxValue = 240;
	option.onChange = onChangeFramerate;
	addOption(option);

	var option:Option = new Option('Color Blindness Filter:', ['Sets a color filter to the entire game\nfor color blind people if not "NONE".'],
		'colorFilter', 'dynamic', ColorBlindness.colorFilters);
	option.onChange = ColorBlindness.setFilter;
	addOption(option);

	boyfriend = new Boyfriend(840, 170, character);
	boyfriend.dance();
	boyfriend.animation.finishCallback = function(name:String) { boyfriend.dance(); };
	boyfriend.visible = false;
	boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.7));

	if (character == 'bf-holding-gf')
		boyfriend.x -= 75;
	
	add(boyfriend);
}

function update(elapsed:Float)
{
	if (boyfriend != null)
	{
		boyfriend.visible = curOption.name == 'No Antialiasing';
		boyfriend.antialiasing = !FunkySettings.noAntialiasing;
	}
}