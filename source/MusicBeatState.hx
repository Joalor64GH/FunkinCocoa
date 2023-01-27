package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import lime.app.Application;

class MusicBeatState extends CustomState
{
	var lastBeat:Float = 0;
	var lastStep:Float = 0;

	public var curStep:Int;
	public var curBeat:Int;

	public var decStep:Float;
	public var decBeat:Float;

	var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;
		var oldDecStep:Float = decStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		if (oldDecStep != decStep && decStep > 0)
			decStepHit();

		Application.current.window.title = PlayState.applicationName;

		super.update(elapsed);
	}

	public function updateBeat():Void
	{
		curBeat = Std.int(Math.ffloor(curStep / 4));
		decBeat = decStep / 4;
	}

	public function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
		decStep = lastChange.stepTime + (Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet;
	}

	public static function switchState(nextState:FlxUIState, ?stopMusic:Bool = false)
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.7, false));
			if (nextState == leState)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}

			return;
		}

		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		var state:Dynamic = FlxG.state;
		var actualState:MusicBeatState = state;
		MusicBeatState.switchState(actualState, true);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function decStepHit():Void
	{
		if (decStep % 4 == 0)
			decBeatHit();
	}

	public function decBeatHit():Void
	{
		// do literally nothing dumbass
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}

class CustomState extends FlxUIState
{
	override function create():Void
	{
		super.create();

		Paths.checkModFolders();

		destroySubStates = false;

		// Custom made Trans out
		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(new CustomFadeTransition(.7, true));
		}

		FlxTransitionableState.skipNextTransOut = false;
	}
}
