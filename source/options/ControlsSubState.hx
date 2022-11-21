package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;

class ControlsSubState extends MusicBeatSubstate
{
	static var curSelected:Int = -1;
	static var curAlt:Bool = false;

	static var defaultKey:String = 'Reset to Default Keys';

	var bindLength:Int = 0;

	var optionShit:Array<Array<String>> = [
		['NOTES'],
		['Left', 'NOTE_LEFT'],
		['Down', 'NOTE_DOWN'],
		['Up', 'NOTE_UP'],
		['Right', 'NOTE_RIGHT'],
		[''],
		['UI'],
		['Left', 'UI_LEFT'],
		['Down', 'UI_DOWN'],
		['Up', 'UI_UP'],
		['Right', 'UI_RIGHT'],
		[''],
		['MAIN'],
		['Reset', 'RESET'],
		['Accept', 'ACCEPT'],
		['Back', 'BACK'],
		['Pause', 'PAUSE'],
		[''],
		['FREEPLAY'],
		['Listen', 'FREEPLAY_LISTEN'],
		['Reset', 'FREEPLAY_RESET'],
		['Menu', 'FREEPLAY_MENU'],
	];

	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpInputs:Array<AbsoluteAlphabet> = [];
	var grpInputsAlt:Array<AbsoluteAlphabet> = [];
	var controlMap:Map<String, Array<FlxKey>>;
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new()
	{
		super();

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		controlMap = FunkySettings.controls.copy();
		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length)
		{
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);

			if (unselectableCheck(i, true))
				isCentered = true;

			var optionText:Alphabet = new Alphabet(0, (10 * i), optionShit[i][0], (!isCentered || isDefaultKey), false);
			optionText.isMenuItem = true;

			if (isCentered)
			{
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
				optionText.yAdd = -65;
			}
			else
				optionText.forceX = 200;

			optionText.yMult = 70;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (!isCentered)
			{
				addBindTexts(optionText, i);
				bindLength++;

				if (curSelected < 0)
					curSelected = i;
			}
		}

		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (!rebindingKey)
		{
			if (controls.UI_UP_P)
				changeSelection(-1);

			if (controls.UI_DOWN_P)
				changeSelection(1);

			if (FlxG.mouse.wheel != 0)
				changeSelection(-FlxG.mouse.wheel);

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
				changeAlt();

			if (controls.BACK)
			{
				FunkySettings.controls = controlMap.copy();
				FunkySettings.saveControls();
				grpOptions.forEachAlive(function(spr:Alphabet) spr.alpha = 0);
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (controls.ACCEPT && nextAccept <= 0)
			{
				if (optionShit[curSelected][0] == defaultKey)
				{
					controlMap = FunkySettings.defaultControls.copy();
					reloadKeys();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else if (!unselectableCheck(curSelected))
				{
					bindingTime = 0;
					rebindingKey = true;

					if (curAlt)
						grpInputsAlt[getInputTextNum()].alpha = 0;
					else
						grpInputs[getInputTextNum()].alpha = 0;

					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
		}
		else
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1)
			{
				var keysArray:Array<FlxKey> = controlMap.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite])
				{
					keysArray[opposite] = NONE;
				}
				controlMap.set(optionShit[curSelected][1], keysArray);

				reloadKey(getInputTextNum(), keysArray[curAlt ? 1 : 0]);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = false;
			}

			bindingTime += elapsed;

			if (bindingTime > 5)
			{
				if (curAlt)
					grpInputsAlt[curSelected].alpha = 1;
				else
					grpInputs[curSelected].alpha = 1;

				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if (nextAccept > 0)
			nextAccept -= 1;

		super.update(elapsed);
	}

	function getInputTextNum()
	{
		var num:Int = 0;
		for (i in 0...curSelected)
			if (optionShit[i].length > 1)
				num++;

		return num;
	}

	function changeSelection(change:Int = 0)
	{
		do
		{
			curSelected += change;

			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length)
			grpInputs[i].alpha = 0.6;

		for (i in 0...grpInputsAlt.length)
			grpInputsAlt[i].alpha = 0.6;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;

					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
						{
							if (grpInputsAlt[i].tracker == item)
							{
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					}
					else
					{
						for (i in 0...grpInputs.length)
						{
							if (grpInputs[i].tracker == item)
							{
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt()
	{
		curAlt = !curAlt;

		for (i in 0...grpInputs.length)
		{
			if (grpInputs[i].tracker == grpOptions.members[curSelected])
			{
				grpInputs[i].alpha = 0.6;

				if (!curAlt)
					grpInputs[i].alpha = 1;

				break;
			}
		}

		for (i in 0...grpInputsAlt.length)
		{
			if (grpInputsAlt[i].tracker == grpOptions.members[curSelected])
			{
				grpInputsAlt[i].alpha = 0.6;

				if (curAlt)
					grpInputsAlt[i].alpha = 1;

				break;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool
	{
		if (optionShit[num][0] == defaultKey)
			return checkDefaultKey;

		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	function addBindTexts(optionText:Alphabet, num:Int)
	{
		var keys:Array<Dynamic> = controlMap.get(optionShit[num][1]);
		var text1 = new AbsoluteAlphabet(InputFormatter.getKeyName(keys[0]), 380, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.tracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AbsoluteAlphabet(InputFormatter.getKeyName(keys[1]), 630, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.tracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKey(index:Int, key:FlxKey):Void
	{
		var item:AbsoluteAlphabet = grpInputs[index];

		if (curAlt)
			item = grpInputsAlt[index];

		item.changeText(InputFormatter.getKeyName(key));
		item.alpha = 1;
	}

	function reloadKeys()
	{
		while (grpInputs.length > 0)
		{
			var item:AbsoluteAlphabet = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}

		while (grpInputsAlt.length > 0)
		{
			var item:AbsoluteAlphabet = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		for (i in 0...grpOptions.length)
			if (!unselectableCheck(i, true))
				addBindTexts(grpOptions.members[i], i);

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length)
			grpInputs[i].alpha = 0.6;

		for (i in 0...grpInputsAlt.length)
			grpInputsAlt[i].alpha = 0.6;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
							if (grpInputsAlt[i].tracker == item)
								grpInputsAlt[i].alpha = 1;
					}
					else
					{
						for (i in 0...grpInputs.length)
							if (grpInputs[i].tracker == item)
								grpInputs[i].alpha = 1;
					}
				}
			}
		}
	}
}

class InputFormatter
{
	public static function getKeyName(key:FlxKey):String
	{
		switch (key)
		{
			case BACKSPACE:
				return "BckSpc";
			case CONTROL:
				return "Ctrl";
			case ALT:
				return "Alt";
			case CAPSLOCK:
				return "Caps";
			case PAGEUP:
				return "PgUp";
			case PAGEDOWN:
				return "PgDown";
			case ZERO:
				return "0";
			case ONE:
				return "1";
			case TWO:
				return "2";
			case THREE:
				return "3";
			case FOUR:
				return "4";
			case FIVE:
				return "5";
			case SIX:
				return "6";
			case SEVEN:
				return "7";
			case EIGHT:
				return "8";
			case NINE:
				return "9";
			case NUMPADZERO:
				return "#0";
			case NUMPADONE:
				return "#1";
			case NUMPADTWO:
				return "#2";
			case NUMPADTHREE:
				return "#3";
			case NUMPADFOUR:
				return "#4";
			case NUMPADFIVE:
				return "#5";
			case NUMPADSIX:
				return "#6";
			case NUMPADSEVEN:
				return "#7";
			case NUMPADEIGHT:
				return "#8";
			case NUMPADNINE:
				return "#9";
			case NUMPADMULTIPLY:
				return "#*";
			case NUMPADPLUS:
				return "#+";
			case NUMPADMINUS:
				return "#-";
			case NUMPADPERIOD:
				return "#.";
			case SEMICOLON:
				return ";";
			case COMMA:
				return ",";
			case PERIOD:
				return ".";
			// case SLASH:
			//	return "/";
			case GRAVEACCENT:
				return "`";
			case LBRACKET:
				return "[";
			// case BACKSLASH:
			//	return "\\";
			case RBRACKET:
				return "]";
			case QUOTE:
				return "'";
			case PRINTSCREEN:
				return "PrtScrn";
			case NONE:
				return '-';
			default:
				var label:String = '' + key;
				return if (label.toLowerCase() == 'null') '-' else '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
		}
	}
}
