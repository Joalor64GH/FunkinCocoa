package;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import Song;

using StringTools;

typedef StageFile =
{
	var defaultZoom:Float;
	var isPixelStage:Bool;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;

	var hide_girlfriend:Null<Bool>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = '';
		if (SONG.stage != null)
		{
			stage = SONG.stage;
		}
		else if (SONG.song != null)
		{
			switch (SONG.song.toLowerCase().replace(' ', '-'))
			{
				case 'spookeez' | 'south' | 'monster':
					stage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					stage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					stage = 'limo';
				case 'cocoa' | 'eggnog':
					stage = 'mall';
				case 'winter-horrorland':
					stage = 'mallEvil';
				case 'senpai' | 'roses':
					stage = 'school';
				case 'thorns':
					stage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					stage = 'warzone';
				default:
					stage = 'stage';
			}
		}
		else
		{
			stage = 'stage';
		}
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getPath('stages/' + stage + '.json');

		var modPath:String = Paths.mods('stages/' + stage + '.json');
		if (FileSystem.exists(modPath))
		{
			try 
			{
				rawJson = File.getContent(modPath);
			}
			catch (e)
			{
				rawJson = null;
			}
		}
		else
		{
			try 
			{
				rawJson = File.getContent(path);
			}
			catch (e)
			{
				rawJson = null;
			}
		}

		return if (rawJson != null) Json.parse(rawJson) else null;
	}
}
