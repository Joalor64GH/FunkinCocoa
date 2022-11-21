package;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

class FunkySettings
{
	// controls
	public static var controls:Map<String, Array<FlxKey>> = [
		'NOTE_LEFT' => [A, LEFT],
		'NOTE_DOWN' => [S, DOWN],
		'NOTE_UP' => [W, UP],
		'NOTE_RIGHT' => [D, RIGHT],
		// control name for ControlsSubState.hx and Controls.hx (check loadKeybinds)
		// then the key array (default keys, these keys will be changed in the menu by user)
		'UI_LEFT' => [A, LEFT],
		'UI_DOWN' => [S, DOWN],
		'UI_UP' => [W, UP],
		'UI_RIGHT' => [D, RIGHT],
		'BACK' => [ESCAPE, BACKSPACE],
		'ACCEPT' => [ENTER, SPACE],
		'PAUSE' => [ESCAPE, ENTER],
		'RESET' => [R],
		'FREEPLAY_RESET' => [R],
		'FREEPLAY_LISTEN' => [SPACE],
		'FREEPLAY_MENU' => [CONTROL]
	];

	public static var defaultControls(default, null):Map<String, Array<FlxKey>> = controls.copy().copy();

	// ui
	public static var timeLeft:Bool = true;
	public static var timeStyle:String = "Time Left";
	public static var longTimeBar:Bool;
	public static var showFPS:Bool = true;
	public static var scoreTween:Bool = true;
	public static var hideHud:Bool;
	public static var bounce:Bool = true;
	public static var sustainStyle:String = "Funkin";
	public static var hideOpponent:Bool;
	public static var splashOpacity:Float = .6;
	public static var strumOpacity:Float = .8;
	public static var splashSkin:String = "AllnoteSplashes";

	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

	// gameplay
	public static var ghostTapping:Bool = true;
	public static var downScroll:Bool;
	public static var middleScroll:Bool;
	public static var hitSounds:Float;
	public static var mult:Float = 1;
	public static var flashing:Bool = true;
	public static var allowSwap:Bool = true;

	// graphics
	public static var lowGraphics:Bool;
	public static var noAntialiasing:Bool;
	public static var framerate:Int = 60;

	public static var colorFilter:ColorBlindnessFilter = NONE;

	// offsets
	public static var comboOffsets:Array<Float> = [0, 0, 0, 0];

	// gets set everytime you change a setting!
	public static function save():Bool
	{
		var save:FlxSave = new FlxSave();
		save.bind('settings', 'Cocoa');
		save.data.timeLeft = timeLeft;
		save.data.timeStyle = timeStyle;
		save.data.longTimeBar = longTimeBar;
		save.data.showFPS = showFPS;
		save.data.scoreTween = scoreTween;
		save.data.ghostTapping = ghostTapping;
		save.data.downScroll = downScroll;
		save.data.middleScroll = middleScroll;
		save.data.hitSounds = hitSounds;
		save.data.mult = mult;
		save.data.lowGraphics = lowGraphics;
		save.data.noAntialiasing = noAntialiasing;
		save.data.comboOffsets = comboOffsets;
		save.data.framerate = framerate;
		save.data.arrowHSV = arrowHSV;
		save.data.flashing = flashing;
		save.data.allowSwap = allowSwap;
		save.data.bounce = bounce;
		save.data.sustainStyle = sustainStyle;
		save.data.hideOpponent = hideOpponent;
		save.data.colorFilter = colorFilter;
		save.data.splashOpacity = splashOpacity;
		save.data.strumOpacity = strumOpacity;
		save.data.splashSkin = splashSkin;

		var achieveSave:FlxSave = bind('achievements');
		achieveSave.data.achievementMap = Achievements.achievementMap;
		achieveSave.data.achievementStats = Achievements.achievementStats;
		achieveSave.flush();

		saveControls();

		var flush:Bool = save.flush() && achieveSave.flush();
		// trace(flush);
		return flush && FlxG.save.flush();
	}

	public static function load():Bool
	{
		var save:FlxSave = new FlxSave();
		save.bind('settings', 'Cocoa');

		GameplayOption.loadGameplayOptions();
		Highscore.loadTotalScore();

		if (save.data.timeLeft != null)
			timeLeft = save.data.timeLeft;

		if (save.data.timeStyle != null)
			timeStyle = save.data.timeStyle;

		if (save.data.longTimeBar != null)
			longTimeBar = save.data.longTimeBar;

		if (save.data.showFPS != null)
			showFPS = save.data.showFPS;

		if (save.data.scoreTween != null)
			scoreTween = save.data.scoreTween;

		if (save.data.ghostTapping != null)
			ghostTapping = save.data.ghostTapping;

		if (save.data.downScroll != null)
			downScroll = save.data.downScroll;

		if (save.data.middleScroll != null)
			middleScroll = save.data.middleScroll;

		if (save.data.hitSounds != null)
			hitSounds = save.data.hitSounds;

		if (save.data.mult != null)
			mult = save.data.mult;

		if (save.data.allowSwap != null)
			allowSwap = save.data.allowSwap;

		if (save.data.lowGraphics != null)
			lowGraphics = save.data.lowGraphics;

		if (save.data.noAntialiasing != null)
			noAntialiasing = save.data.noAntialiasing;

		if (save.data.framerate != null)
		{
			framerate = save.data.framerate;

			if (framerate > FlxG.drawFramerate)
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

		if (save.data.comboOffsets != null)
			comboOffsets = save.data.comboOffsets;

		if (save.data.arrowHSV != null)
			arrowHSV = save.data.arrowHSV;

		if (save.data.flasing != null)
			flashing = save.data.flashing;

		if (save.data.bounce != null)
			bounce = save.data.bounce;

		if (save.data.sustainStyle != null)
			sustainStyle = save.data.sustainStyle;

		if (save.data.hideOpponent != null)
			hideOpponent = save.data.hideOpponent;

		if (save.data.colorFilter != null)
			colorFilter = save.data.colorFilter;

		if (save.data.splashOpacity != null)
			splashOpacity = save.data.splashOpacity;

		if (save.data.strumOpacity != null)
			strumOpacity = save.data.strumOpacity;

		if (save.data.splashSkin != null)
			splashSkin = save.data.splashSkin;

		/*if (!Achievements.loadAchievements())
			trace('ERROR LOADING ACHIEVEMENTS'); */

		FlxG.sound.volume = FlxG.save.data.volume;
		FlxG.sound.muted = FlxG.save.data.mute;

		return loadControls();
	}

	public static function bind(bind:String):FlxSave
	{
		var save:FlxSave = new FlxSave();
		save.bind(bind, 'Cocoa');

		return save;
	}

	public static function loadControls():Bool
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls', 'Cocoa');

		if (save.data.controls != null)
			controls = save.data.controls;

		PlayerSettings.player1.controls.loadKeybinds();

		return save.flush();
	}

	public static function saveControls():Bool
	{
		var control:FlxSave = new FlxSave();
		control.bind('controls', 'Cocoa');

		if (control.data != null)
			control.data.controls = controls;

		PlayerSettings.player1.controls.loadKeybinds();

		return control.flush();
	}
}
