package;

import flixel.math.FlxMath;
import flixel.system.FlxSound;

import haxe.Json;

// lmao using CocoaTools in CocoaTools
using CocoaTools;
using StringTools;

class CocoaTools
{
	public static function resetMusic(?checkPlaying:Bool = true)
	{
		if (FlxG.sound.music != null)
		{
			if (checkPlaying)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.sound('freakyMenu'));
			}
			else
			{
				FlxG.sound.playMusic(Paths.sound('freakyMenu'));
			}
		}
	}

	public static function destroyMusic(music:FlxSound):Void
	{
		if (music == null)
			return;

		music.pause();
		music.stop();
	}

	static final Abbreviations:Array<String> = ['', 'K', 'M', 'B', 'T', 'Q', 'S', 'SX', 'O', 'N', 'D', 'U', 'TR', 'QT', 'QD', 'SD', 'ST', 'OC', 'NV', 'V', 'C'];
	public static function formatScore(score:Float):String
	{
		var size:Float = score;
		var ks:Int = 0;
		
		while (size >= 1000 && ks < Abbreviations.length - 1)
		{
			ks++;
			size /= 1000;
		}
		
		size = FlxMath.roundDecimal(size, 1);
		return size + Abbreviations[ks];
	}	

	public static function beautifyEvents(event:Array<Array<Dynamic>>):Array<Array<Dynamic>>
	{
		for (i in event)
			if (i == null)
			{
				var index:Int = event.indexOf(i);
				event.remove(i);
				i = [];
				event.insert(index, i);
			}

		return event;
	}

	public static function toLowerCase(array:Array<String>):Array<String>
	{
		var copiedArray:Array<String> = array.copy();

		for (copy in copiedArray)
		{
			var index:Int = copiedArray.indexOf(copy);
			copiedArray.remove(copy);
			copy = copy.toLowerCase();
			copiedArray.insert(index, copy);
		}

		return copiedArray.copy();
	}

	public static function toUpperCase(array:Array<String>):Array<String>
	{
		var copiedArray:Array<String> = array.copy();

		for (copy in copiedArray)
		{
			var index:Int = copiedArray.indexOf(copy);
			copiedArray.remove(copy);
			copy = copy.toUpperCase();
			copiedArray.insert(index, copy);
		}

		return copiedArray.copy();
	}

	public static function replace(array:Array<String>, sub:String, by:String):Array<String>
	{
		var copy:Array<String> = array.copy();

		for (i in copy)
		{
			var index:Int = copy.indexOf(i);
			copy.remove(i);
			i.split(sub).join(by);
			copy.insert(index, i);
		}

		return array = copy;
	}
}
