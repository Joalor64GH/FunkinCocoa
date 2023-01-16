package;

import Section.SwagSection;
import haxe.Exception;
import haxe.Json;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end


typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
	var ?by:String;
	var events:Array<Dynamic>;

	/**
	 	Use with caution!
	**/
	var ?dynamicAccess:Dynamic;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var stage:String;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function availableSongs(jsonInput:String)
	{
		var songs:Array<String> = [];

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			var song:SwagSong = try loadFromJson(jsonInput, i) catch (e) null;
			if (song != null)
			{
				songs.push(CoolUtil.difficultyStuff[i]);
			}
		}

		return songs;
	}	

	public static function loadFromJson(jsonInput:String, difficulty:Int = 0):SwagSong
	{
		var time:Float = Sys.time();
		function loadFromJson(jsonInput:String, difficulty:Int)
		{
			var rawJson = null;

			var formattedFolder:String = Paths.formatToSongPath(jsonInput);
			var formattedSong:String = Paths.formatToSongPath(CoolUtil.difficultyStuff[difficulty]);

			var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);

			if (FileSystem.exists(moddyFile))
			{
				rawJson = File.getContent(moddyFile).trim();
			}

			if (rawJson == null)
				rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();

			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
				// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
			}

			var songJson:SwagSong = parseJSONshit(rawJson);

			var eventFile:String = Paths.modsJson('$formattedFolder/events');

			if (!FileSystem.exists(eventFile))
				eventFile = Paths.json('$formattedFolder/events');

			try 
			{
				songJson.events = parseEVENTshit(eventFile);
				
				if (songJson.events == null)
					songJson.events = [];
			}
			catch (e:Exception)
			{
				songJson.events = [];
			}

			// trace(songJson.events);

			return songJson;
		}
		var song:SwagSong = try loadFromJson(jsonInput, difficulty) catch (e) null;
		var index:Int = 0;
		if (song == null)
		{
			for (i in 0...CoolUtil.difficultyStuff.length)
			{
				try 
				{
					song = loadFromJson(jsonInput, i);
					index = i;
				} 
				catch (e) song = null;
			}
			if (song != null)
			{
				PlayState.storyDifficulty = index;
			}
		}
		//trace('${CoolUtil.coolSongFormatter(jsonInput)} took ${CoolUtil.coolTruncater(Sys.time() - time, 4)} seconds to parse');
		return song;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		var dynamicAccess:Dynamic = Json.parse(rawJson);
		swagShit.validScore = true;
		swagShit.dynamicAccess = dynamicAccess;
		return swagShit;
	}

	public static function parseEVENTshit(rawJson:String):Array<Array<Dynamic>>
	{
		var events:Dynamic = Json.parse(File.getContent(rawJson.trim()).trim());
		var songEvents = events.song;
		return if (songEvents != null) songEvents.events else events.events;
	}
}
