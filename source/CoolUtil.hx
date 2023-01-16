package;

import flixel.FlxG;
import haxe.crypto.*;
import haxe.io.*;
import openfl.utils.Assets;

using CoolUtil;
using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class CoolUtil
{
	public static var difficultyStuff:Array<String> = ['Easy', 'Normal', 'Hard',];

	public static function difficultyString():String
	{
		return difficultyStuff[PlayState.storyDifficulty].toUpperCase();
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		var newValue:Float = value;
		if (newValue < min)
			newValue = min;
		else if (newValue > max)
			newValue = max;
		return newValue;
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		if (FileSystem.exists(path))
			daList = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolStringFile(path:String, ?keyword:String = '\n'):Array<String>
	{
		var daList:Array<String> = path.trim().split(keyword);

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolTruncater(number:Float, precision:Int):Float
	{
		if (precision < 1)
			return Math.ffloor(number);
		
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	// uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String):Void
	{
		if (!Assets.cache.hasSound(Paths.sound(sound, true)))
		{
			FlxG.sound.cache(Paths.sound(sound, true));
		}
	}

	// copied From FlxStringUtil lololol
	public static function coolTimeFormatter(seconds:Float):String
	{
		var timeString:String = Std.int(seconds / 60) + ":";
		var timeStringHelper:Int = Std.int(seconds) % 60;

		if (timeStringHelper < 10)
			timeString += "0";

		timeString += timeStringHelper;

		return timeString;
	}

	public static function coolReplace(string:String, sub:String, by:String):String
	{
		return string = string.split(sub).join(by);
	}

	public static function coolSongFormatter(song:String):String
	{
		var swag:String = coolReplace(song, '-', ' ');
		var splitSong:Array<String> = swag.split(' ');

		for (i in 0...splitSong.length)
		{
			var firstLetter = splitSong[i].substring(0, 1);
			var coolSong:String = coolReplace(splitSong[i], firstLetter, firstLetter.toUpperCase());
			var splitCoolSong:Array<String> = coolSong.split('');

			coolSong = Std.string(splitCoolSong[0]).toUpperCase();

			for (e in 0...splitCoolSong.length)
				coolSong += Std.string(splitCoolSong[e + 1]).toLowerCase();

			coolSong = coolReplace(coolSong, 'null', '');

			for (a in 0...splitSong.length)
			{
				var stringSong:String = Std.string(splitSong[a + 1]);
				var stringFirstLetter:String = stringSong.substring(0, 1);

				var splitStringSong = stringSong.split('');
				stringSong = Std.string(splitStringSong[0]).toUpperCase();

				for (l in 0...splitStringSong.length)
					stringSong += Std.string(splitStringSong[l + 1]).toLowerCase();

				stringSong = coolReplace(stringSong, 'null', '');

				coolSong += ' $stringSong';
			}

			return coolSong.replace(' Null', '');
		}

		return swag;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site, "&"]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function coolDirectory(file:String):Array<String>
	{
		if (!file.endsWith('/'))
			file = '$file/';

		var path:String = Paths.mods(file);
		if (!FileSystem.exists(path))
			path = Paths.getPath(file);

		var absolutePath:String = FileSystem.absolutePath(path);
		var directory:Array<String> = FileSystem.readDirectory(absolutePath);

		if (directory != null)
		{
			var dirCopy:Array<String> = directory.copy();

			for (i in dirCopy)
			{
				var index:Int = dirCopy.indexOf(i);
				var file:String = '$path$i';
				dirCopy.remove(i);
				dirCopy.insert(index, file);
			}

			directory = dirCopy;
		}

		return if (directory != null) directory else [];
	}

	static final CHARS = Base64.CHARS;
	public static function encode(string:String):String
	{
		var baseCode:BaseCode = new BaseCode(Bytes.ofString(CHARS));
		var returnString = baseCode.encodeString(string);
		return returnString;
	}

	public static function decode(string:String):String
	{
		var baseCode:BaseCode = new BaseCode(Bytes.ofString(CHARS));
		var returnString = baseCode.decodeString(string);
		return returnString;
	}
}
