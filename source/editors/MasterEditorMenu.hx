package editors;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		'Chart Editor',
		'Old Chart Editor',
		'Splash Editor',
	];

	var grpTexts:FlxTypedGroup<Alphabet>;

	var curSelected = 0;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
		}

		changeSelection();
		super.create();
	}

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

		if (controls.BACK)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			switch (options[curSelected])
			{
				case 'Character Editor':
					MusicBeatState.switchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Week Editor':
					MusicBeatState.switchState(new WeekEditorState());
				case 'Menu Character Editor':
					MusicBeatState.switchState(new MenuCharacterEditorState());
				case 'Dialogue Portrait Editor':
					MusicBeatState.switchState(new DialogueCharacterEditorState());
				case 'Dialogue Editor':
					MusicBeatState.switchState(new DialogueEditorState());
				case 'Chart Editor':
					if (Main.Memory < 8 && !CocoaSave.save.data.dontShow)
					{
						openSubState(new RAMWarningSubstate());
						return;
					}
					MusicBeatState.switchState(new ChartingState(true));
				case 'Old Chart Editor':
					MusicBeatState.switchState(new OldChartingState(true));
				case 'Splash Editor':
					MusicBeatState.switchState(new SplashEditorState());
			}
			FlxG.sound.music.volume = 0;
		}

		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}
}

private class RAMWarningSubstate extends MusicBeatSubstate
{
	public var warningText:FlxText;
	public var yes:FlxText;
	public var no:FlxText;

	var niggaBG:FlxSprite;
	var onYes:Bool = true;

	var dontShow:FlxText;

	var checkbox:CoolCheckbox;

	public function new()
	{
		super();

		FlxG.mouse.visible = true;

		niggaBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		niggaBG.screenCenter();
		niggaBG.alpha = .0;
		add(niggaBG);

		warningText = new FlxText();
		warningText.setFormat(Paths.font('vcr.ttf'), 56, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.borderSize = 1.35;
		warningText.borderQuality = 10;
		warningText.text = 'Your RAM is ${Main.Memory}GB which is below 8.\nNew chart editor is not recommended.\n\nProceed anyway?';
		warningText.screenCenter();
		warningText.y -= 100;
		add(warningText);

		yes = new FlxText(warningText.x + 395, warningText.y + 325, 0, "Yes");
		yes.setFormat(Paths.font('vcr.ttf'), 64, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yes.borderSize = 2;
		yes.borderQuality = 10;
		add(yes);

		no = new FlxText(yes.x + 300, yes.y, 0, "No");
		no.setFormat(Paths.font('vcr.ttf'), 64, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		no.borderSize = 2;
		no.borderQuality = 10;
		add(no);

		var checked:Bool = cast CocoaSave.save.data.dontShow;
		checkbox = new CoolCheckbox(checked);
		checkbox.setPosition(yes.x - 30, yes.y + 100);
		add(checkbox);

		dontShow = new FlxText(checkbox.x + 120, checkbox.y, "Don't show\nthis again");
		dontShow.setFormat(Paths.font('vcr.ttf'), 54, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dontShow.borderSize = 2;
		dontShow.borderQuality *= 10;
		add(dontShow);

		updateOpt();

		for (i in members)
			oldAlphas.push(cast (i, FlxSprite).alpha);

		FlxTween.tween(niggaBG, {alpha: .8}, .7, {ease: FlxEase.quadInOut, onUpdate: function(tween:FlxTween) 
		{ 
			for (i in members)
			{
				var i:FlxSprite = cast i;
				i.alpha = niggaBG.alpha; 
			}
		}, onComplete: function(tween:FlxTween)
		{
			for (i in members)
			{
				var il:FlxSprite = cast i;
				if (il != niggaBG)
					FlxTween.tween(il, {alpha: oldAlphas[members.indexOf(i)]}, .2); 
			}
		}});
	}

	var oldAlphas:Array<Float> = new Array();
	var allowEnter:Bool;
	var allowTimer:FlxTimer;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
			close();

		if (!allowEnter && allowTimer == null)
		{
			allowTimer = new FlxTimer().start(.6, function(tmr:FlxTimer) allowEnter = true);
		}

		if (controls.UI_LEFT_P && !onYes)
		{
			onYes = true;
			updateOpt();
		}
		else if (controls.UI_RIGHT_P && onYes)
		{
			onYes = false;
			updateOpt();
		}
		if (FlxG.mouse.overlaps(yes) && !controls.UI_RIGHT)
		{
			onYes = true;
			updateOpt();
		}
		else if (FlxG.mouse.overlaps(no) && !controls.UI_LEFT)
		{
			onYes = false;
			updateOpt();
		}

		if (allowEnter)
		{
			if (controls.ACCEPT && onYes)
			{
				FlxG.sound.music.volume = 0;
				MusicBeatState.switchState(new ChartingState(true));
				FlxG.sound.music.volume = 0;
			}
			else if (controls.ACCEPT && !onYes)
				close();
		}

		if (FlxG.mouse.overlaps(checkbox) || FlxG.mouse.overlaps(dontShow))
		{
			checkbox.alpha = 1;

			if (FlxG.mouse.justPressed)
			{
				checkbox.checked = !checkbox.checked;

				CocoaSave.save.data.dontShow = checkbox.checked;
				CocoaSave.save.flush();
			}
		}
		else 
			checkbox.alpha = .6;

		dontShow.alpha = checkbox.alpha;
	}

	function updateOpt():Void
	{
		yes.scale.set(onYes ? 1 : .8, onYes ? 1 : .8);
		yes.alpha = onYes ? 1 : .6;

		no.scale.set(!onYes ? 1 : .8, !onYes ? 1 : .8);
		no.alpha = !onYes ? 1 : .6;
	}
}
