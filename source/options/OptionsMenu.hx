package options;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;
	var text:FlxText;
	var controlsStrings:Array<String>;
	var grpControls:FlxTypedGroup<Alphabet>;
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		var strings:Array<String> = [];
		var modPath:String = Paths.mods('options/optionsList.txt');
		if (!FileSystem.exists(modPath))
			modPath = Paths.getPath('options/optionsList.txt');
		if (!FileSystem.exists(modPath))
			modPath = 'optionsList.txt';
		if (!FileSystem.exists(modPath))
			strings = [
				'Controls',
				'Gameplay',
				'Visuals and UI',
				'Graphics',
				'Note',
			];

		controlsStrings = strings.length > 0 ? strings : CoolUtil.coolStringFile(File.getContent(modPath), '??');

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlsStrings.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 10, controlsStrings[i], true, false);
			controlLabel.screenCenter();
			controlLabel.y += (100 * (i - (controlsStrings.length / 2))) + 50;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);


		changeSelection();

		destroySubStates = false;

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
			FlxG.switchState(new MainMenuState());

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		var modPath:String = Paths.mods('options/${controlsStrings[curSelected]}.hx');
		if (!FileSystem.exists(modPath))
			modPath = Paths.getPath('options/${controlsStrings[curSelected]}.hx');

		if (controls.ACCEPT)
		{
			if (curSelected != -1)
			{
				switch (controlsStrings[curSelected])
				{
					case 'Controls':
						openSubState(new ControlsSubState());
					case 'Note':
						openSubState(new NotesSubstate());
					case 'Gameplay':
						openSubState(new GameplaySubstate());
					case 'Visuals and UI':
						openSubState(new UISubstate());
					default:
						openSubState(new TypedOptionsSubstate(modPath));
				}
			}
		}
	}

	var isSettingControl:Bool = false;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		super.closeSubState();

		FunkySettings.save();
	}
}
