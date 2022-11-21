package;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSave;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	var curOption:GameplayOption;
	var curSelected:Int;
	var optionsArray:Array<GameplayOption> = [];

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CoolCheckbox>;
	var grpTexts:FlxTypedGroup<AbsoluteAlphabet>;

	function createOptions()
	{
		var option:GameplayOption = new GameplayOption('Scroll Speed Multiplier', 'scroll_speed', 'float');
		option.changeValue = 0.1;
		option.maxValue = 3;
		option.minValue = 0.1;
		option.scrollSpeed = 1.2;
		addOption(option);

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'health_gain', 'float');
		option.changeValue = 0.1;
		option.maxValue = 5;
		option.minValue = 0.1;
		option.scrollSpeed = 1.4;
		addOption(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'health_miss', 'float');
		option.changeValue = 0.1;
		option.maxValue = 5;
		option.minValue = 0.1;
		option.scrollSpeed = 1.4;
		addOption(option);

		var option:GameplayOption = new GameplayOption('Mirror Notes', 'mirror_notes');
		var option2:GameplayOption = new GameplayOption('Randomize Notes', 'randomize_notes');

		option.incompatibleOption = option2;
		option2.incompatibleOption = option;

		addOption(option);
		addOption(option2);
		addOption(new GameplayOption('No Note Types', 'no_note_types'));
		addOption(new GameplayOption('Instakill on Miss', 'instakill'));
		addOption(new GameplayOption('Practice Mode', 'practice_mode'));
		addOption(new GameplayOption('Botplay', 'botplay'));
		addOption(new GameplayOption('Opponent Mode', 'opponent_mode'));
	}

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.screenCenter();
		bg.alpha = 0;
		add(bg);

		FlxTween.tween(bg, {alpha: 0.66}, 0.6, {ease: FlxEase.quadInOut});

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AbsoluteAlphabet>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CoolCheckbox>();
		add(checkboxGroup);

		createOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70 * i, optionsArray[i].optionName, true, false, 0.05, 0.8);
			optionText.isMenuItem = true;
			optionText.x += 360;
			optionText.xAdd += 150;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool')
			{
				var checkbox:CoolCheckbox = new CoolCheckbox(optionText.x - 105, optionText.y - 50, optionsArray[i].value == true);
				checkbox.tracker = optionText;
				checkbox.offsetY = -50;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 120;
				optionText.xAdd -= 120;

				var valueText:AbsoluteAlphabet = new AbsoluteAlphabet('' + optionsArray[i].value, optionText.width + 80, true, 0.8);
				valueText.tracker = optionText;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionText.x -= valueText.width / 1.7;
				optionsArray[i].setChild(valueText);
			}
		}

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:GameplayOption)
	{
		if (optionsArray == null || optionsArray.length < 1)
			optionsArray = [];

		optionsArray.push(option);
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			changeSelection(-FlxG.mouse.wheel);
		}

		if (controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox = true;
			if (curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if (usesCheckbox)
			{
				if (controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.value = !curOption.value;
					reloadCheckboxes();
					changeSelection();

					var curOption:GameplayOption = optionsArray[curSelected];
					if (curOption.incompatibleOption != null
						&& curOption.type == 'bool'
						&& curOption.value
						&& curOption.incompatibleOption.type == 'bool')
					{
						curOption.incompatibleOption.value = false;
						reloadCheckboxes();
					}
				}
			}
			else
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if (holdTime > 0.5 || pressed)
					{
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != 'string')
							{
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.value + add;
									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											optionsArray[curSelected].value = holdValue;

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											optionsArray[curSelected].value = holdValue;
									}

								case 'string':
									var num:Int = curOption.curOption; // lol
									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
									{
										num = curOption.optionArray.length - 1;
									}
									else if (num >= curOption.optionArray.length)
									{
										num = 0;
									}

									curOption.curOption = num;
									optionsArray[curSelected].curOption = num;
									curOption.value = curOption.optionArray[num];
									changeSelection();
							}

							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if (holdValue < curOption.minValue)
								holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue)
								holdValue = curOption.maxValue;

							switch (curOption.type)
							{
								case 'int':
									curOption.value = Math.round(holdValue);

								case 'float' | 'percent':
									curOption.value = FlxMath.roundDecimal(holdValue, curOption.decimals);
							}
						}

						updateTextFrom(optionsArray[curSelected]);
					}

					if (curOption.type != 'string')
					{
						holdTime += elapsed;
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					clearHold();
				}
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption)
	{
		var val:Float = option.value;
		if (option.type == 'percent')
			val *= 100;
		option.child.changeText('$val');
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		curOption = optionsArray[curSelected]; // shorter lol

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		for (text in grpTexts)
		{
			text.alpha = 0.6;

			if (text.ID == curSelected)
			{
				text.alpha = 1;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.daValue = optionsArray[checkbox.ID].value == true;
	}

	override function close():Void
	{
		GameplayOption.saveGameplayOptions();
		super.close();
	}
}

class GameplayOption
{
	public var optionName:String;
	public var option:String;
	public var value(default, set):Dynamic;
	public var curOption:Int;
	public var optionArray:Array<String>;
	public var child:Alphabet;
	public var incompatibleOption:GameplayOption;

	public var changeValue:Float = 1;
	public var minValue:Float;
	public var maxValue:Float;
	public var scrollSpeed:Float;
	public var decimals:Int = 1;

	@:isVar public var type(get, set):String;

	public function new(optionName:String, option:String, type:String = 'bool', ?optionArray:Array<String>)
	{
		this.optionName = optionName;
		this.option = option;
		this.type = type;
		this.optionArray = optionArray;

		value = options[option];
	}

	public static var options:Map<String, Dynamic> = [
		'scroll_speed' => 1.0, 'health_gain' => 1, 'health_miss' => 1, 'opponent_mode' => false, 'botplay' => false, 'practice_mode' => false,
		'randomize_notes' => false, 'no_note_types' => false, 'mirror_notes' => false, 'instakill' => false, 'two_hand' => false,
	];

	public static function loadGameplayOptions():Bool
	{
		var save:FlxSave = FunkySettings.bind('gamechangers');

		if (save.data.options == null)
			return saveGameplayOptions();
		else
			options = save.data.options;

		return false;
	}

	public static function saveGameplayOptions():Bool
	{
		var save:FlxSave = FunkySettings.bind('gamechangers');
		save.data.options = options;
		return save.flush();
	}

	public function setChild(alpha:Alphabet)
	{
		return child = alpha;
	}

	public function setIncompatibleOption(option:GameplayOption):GameplayOption
	{
		incompatibleOption = option;
		return this;
	}

	function get_type():String
	{
		var returnValue:String = 'bool';
		switch (type.toLowerCase())
		{
			case 'float' | 'int' | 'string':
				returnValue = type;
		}

		return returnValue;
	}

	function set_type(value:String):String
	{
		return type = value.toLowerCase();
	}

	function set_value(value:Dynamic):Dynamic
	{
		options[option] = value;
		saveGameplayOptions();
		return this.value = value;
	}
}
