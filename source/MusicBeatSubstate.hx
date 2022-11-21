package;

import Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUISubState;

class MusicBeatSubstate extends CustomSubstate
{
	public function new()
	{
		super();
	}

	var lastBeat:Float = 0;
	var lastStep:Float = 0;

	var curStep:Int = 0;
	var curBeat:Int = 0;
	var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
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

class CustomSubstate extends FlxUISubState
{
	public function new()
	{
		super();
	}

	override public function destroy():Void
	{
	}
}
