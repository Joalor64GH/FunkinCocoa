package;

import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;

#if openfl
import openfl.system.System;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	public var memoryMegas:Float;
	public var memoryTotal:Float;

	@:noCompletion var cacheCount:Int;
	@:noCompletion var currentTime:Float;
	@:noCompletion var times:Array<Float>;

	public function new(x:Float = 18, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 15, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		memoryMegas = 0;
		memoryTotal = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	final intervalArray:Array<String> = ['MB', 'GB'];
	// yoinked from forever
	final function getInterval(num:Float):String
	{
		var size:Float = num;
		var data:Int = 0;
		while (size >= 1024 && data < intervalArray.length - 1)
		{
			data++;
			size /= 1024;
		}

		size = Math.round(size * 100) / 100;
		return size + intervalArray[data];
	}

	// Event Handlers
	@:noCompletion
	#if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount:Int = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		if (currentCount != cacheCount)
		{
			text = 'FPS: $currentFPS\n';

			#if openfl
			memoryMegas = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 2));
			if (memoryMegas > memoryTotal)
				memoryTotal = memoryMegas;

			text += 'RAM: ${getInterval(memoryMegas)} / ${getInterval(memoryTotal)}';
			#end

			textColor = 0xFFFFFFFF;

			text += "\n";
		}

		cacheCount = currentCount;
	}
}
