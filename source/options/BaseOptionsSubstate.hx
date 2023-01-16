package options;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class BaseOptionsSubstate extends MusicBeatSubstate
{
	var curOption:Option = null;
	var curSelected:Int = 0;
	var optionsArray:Array<Option>;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CoolCheckbox>;
	var grpTexts:FlxTypedGroup<AbsoluteAlphabet>;

	var descBox:FlxSprite;
	var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public function new()
	{
		super();

		if (title == null)
			title = 'Options';
		if (rpcTitle == null)
			rpcTitle = 'Options Menu';

		#if desktop
		DiscordClient.changePresence(rpcTitle, null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = !FunkySettings.noAntialiasing;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AbsoluteAlphabet>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CoolCheckbox>();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		var titleText:Alphabet = new Alphabet(0, 0, title, true, false, 0, 0.6);
		titleText.x += 60;
		titleText.y += 40;
		titleText.alpha = 0.5;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70 * i, optionsArray[i].name, false, false);
			optionText.isMenuItem = true;
			optionText.x += 360;
			optionText.xAdd += 100;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool')
			{
				var checkbox:CoolCheckbox = new CoolCheckbox(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.tracker = optionText;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 120;
				optionText.xAdd -= 120;

				var valueText:AbsoluteAlphabet = new AbsoluteAlphabet('' + optionsArray[i].getValue(), optionText.width + 80);
				valueText.tracker = optionText;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionText.x -= valueText.width / 1.7;
				optionsArray[i].setChild(valueText);
			}

			updateTextFrom(optionsArray[i]);
		}

		changeSelection(false);
		reloadCheckboxes();
		updateText();
	}

	public function addOption(option:Option)
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
		var num:Int = optionsArray[curSelected].curOption;
		var optionalDesc:String = optionsArray[curSelected].description[num];

		// trace(optionsArray[curSelected].changeDescIfString);

		if (optionsArray[curSelected].type == 'string' && optionsArray[curSelected].changeDescIfString)
			updateText(optionalDesc);

		if (controls.UI_UP_P)
		{
			changeSelection(-1, true, optionalDesc);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1, true, optionalDesc);
		}

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			changeSelection(-FlxG.mouse.wheel, false, optionalDesc);
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
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
					updateText();
					changeSelection(false);
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
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string' | 'dynamic':
									var num:Int = curOption.curOption; // lol
									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
									{
										num = curOption.options.length - 1;
									}
									else if (num >= curOption.options.length)
									{
										num = 0;
									}

									var optionalDesc:String = optionsArray[curSelected].description[num];

									curOption.curOption = num;
									optionsArray[curSelected].curOption = num;
									optionsArray[curSelected].setOption(num);
									curOption.setValue(curOption.options[num]); // lol
									updateText(optionalDesc);
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string' && curOption.type != 'dynamic')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if (holdValue < curOption.minValue)
								holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue)
								holdValue = curOption.maxValue;

							switch (curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));

								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
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

			if (controls.RESET)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:Option = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	override function close()
	{
		super.close();
	}

	function updateText(?desc:String):Bool
	{
		if (optionsArray[curSelected].type == 'bool')
		{
			if (optionsArray[curSelected].getValue())
				descText.text = optionsArray[curSelected].description[0];
			else if (optionsArray[curSelected].description[1] != null)
				descText.text = optionsArray[curSelected].description[1];
			else
				descText.text = optionsArray[curSelected].description[0];
		}
		else if (optionsArray[curSelected].type == 'string' && optionsArray[curSelected].changeDescIfString)
			descText.text = desc;
		else
			descText.text = optionsArray[curSelected].description[0];

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		return true;
	}

	function updateTextFrom(option:Option)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent')
			val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		holdTime = 0;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true, ?desc:String)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		curOption = optionsArray[curSelected]; // shorter lol

		descText.screenCenter(Y);
		descText.y += 270;

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

		if (!updateText(desc))
			FlxG.log.add('Description failed to change its description!');

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		FunkySettings.save();
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.checked = (optionsArray[checkbox.ID].getValue() == true);
	}
}
