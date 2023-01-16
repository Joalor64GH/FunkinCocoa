package;

import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if openfl
import openfl.system.System;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	public var memoryMegas:Float;

	@:noCompletion var cacheCount:Int;
	@:noCompletion var currentTime:Float;
	@:noCompletion var times:Array<Float>;

	public function new(x:Float = 18, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		embedFonts = true;
		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Paths.font("vetica.ttf"), 16, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		memoryMegas = 0;
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

	var oldStyle:String = FunkySettings.fpsStyle;
	var oldMemory:Float = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 2));
	var oldRender:Bool = FunkySettings.GPURender ? true : false;
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

		if (currentCount != cacheCount 
			|| FunkySettings.fpsStyle != oldStyle
			|| memoryMegas != oldMemory
			|| FunkySettings.GPURender != oldRender)
		{
			memoryMegas = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 2));

			textColor = 0xFFFFFFFF;

			switch (FunkySettings.fpsStyle.toLowerCase())
			{
				case "both":
					text = 'FPS: $currentFPS';
					text += '\nRAM: ${getInterval(memoryMegas)} / ${Main.Memory}GB';
				case "only memory":
					text = 'RAM: ${getInterval(memoryMegas)} / ${Main.Memory}GB';
				case "only fps":
					text = 'FPS: $currentFPS';
			}

			if (FunkySettings.GPURender)
				text += '\nVRAM: ${getInterval(Math.fround(FlxG.stage.context3D.totalGPUMemory / 1024 / 1024))}';

			text += "\n";
		}

		cacheCount = currentCount;
		oldStyle = FunkySettings.fpsStyle;
		oldMemory = memoryMegas;
		oldRender = FunkySettings.GPURender;
	}
}
