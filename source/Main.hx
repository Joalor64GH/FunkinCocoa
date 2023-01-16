package;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import sys.io.Process;

using StringTools;
#if CRASHES_ALLOWED
import Discord.DiscordClient;
import haxe.CallStack;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var FPS:FPS = new FPS(10, 3, 0xFFFFFF);
	public static var ColorFilter:ColorBlindness;
	public static var Memory(default, null):Int;

	final macScript = "detail=`system_profiler SPHardwareDataType -detailLevel mini`
	memory=`echo \"$detail\" | grep -m 1 \"Memory\" | awk -F': ' '{print $2}'`
	echo $memory";

	final linuxScript:String = "cat /proc/meminfo | grep MemTotal | awk -F ':' '{print $2}'";

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		CocoaSave.save.bind("funkin", "Cocoa");
		haxe.Log.trace = function(v, ?posInfos)
		{
			function formatOutput(v:Dynamic, infos:haxe.PosInfos):String 
			{
				var fileName;
				fileName = infos.fileName.replace('source/', '');
				var str = Std.string(v);
				if (infos == null)
					return str;
				var pstr = fileName + ", Line " + infos.lineNumber;
				if (infos.customParams != null)

					for (v in infos.customParams)
						str += ", " + Std.string(v);
				return pstr + ": " + str;
			}

			Sys.println(formatOutput(v, posInfos));
		};

		Lib.current.addChild(new Main());
	}

	function getMemory():Void
	{
		var cmd:String = #if windows "wmic OS get TotalVisibleMemorySize /Value <nul" #elseif mac macScript #elseif linux linuxScript #else null; throw "Unsupported OS." #end;
		var p:Process = new Process(cmd);
		p.exitCode();
		var mem:String = p.stdout.readAll().toString();
		p.close();

		#if linux
		Memory = Std.parseInt(mem);
		#elseif mac
		Memory = Std.parseInt(mem) * 1024 * 1024;
		#elseif windows
		function fixMem(mem:String)
		{
			while (mem.indexOf(" ") != -1)
				mem = mem.coolReplace(" ", "");
			while (mem.indexOf("\t") != -1)
				mem = mem.coolReplace("\t", "");

			return mem = mem.coolReplace("TotalVisibleMemorySize=", "");
		}

		Memory = Std.parseInt(fixMem(mem));
		#else
		throw "Unsupported OS.";
		#end

		Memory = cast Math.fround(Memory / 1024);
		Memory = cast Math.fround(Memory / 1024);
		trace('RAM is ${Memory}GB!');
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		addChild(FPS);
		if (FPS != null)
		{
			FPS.visible = FunkySettings.fpsStyle != 'Disabled';
		}
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if CRASHES_ALLOWED
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		
		getMemory();
	}

	//sqirra-rng
	#if CRASHES_ALLOWED
	function onCrash(exception:UncaughtErrorEvent):Void
	{
		var error:String = "";
		var date:String = DateTools.format(Date.now(), "%Y-%m-%d %H.%M.%S");
		var callstack:Array<StackItem> = CallStack.exceptionStack(true);

		for (i in callstack)
			switch (i)
			{
				case FilePos(s, f, l, c):
					error += 'Called from $f: (line $l)\n';
				default:
					Sys.println(i);
			}

		error += '\nUncaught Exception: ${exception.error}\nReport this to Github Repository:\nhttps://github.com/TheWorldMachinima/FunkinCocoa';

		if (!FileSystem.exists('./logs/'))
			FileSystem.createDirectory('./logs/');

		File.saveContent('./logs/CocoaLog_$date.log', '$error\n');

		Application.current.window.alert(error, "Game crashed!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}
