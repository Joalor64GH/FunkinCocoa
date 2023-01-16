package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef AchievementStats =
{
	public var date:Date;
	public var song:String;
	public var diff:Null<Int>;
	public var accuracy:Null<Float>;
	public var misses:Null<Int>;
}

typedef AchievementMeta = {
	public var name:String;
	public var desc:String;
	public var save_tag:String;
	public var hidden:Bool;

	public var ?week_nomiss:String;
	public var ?lua_code:String;
	/**
		If null or -1, gets pushed instead of getting inserting to specified index.
	**/
	public var ?index:Int;
	/**
		If not null, replaces achievements completely.
		
		Using global is dangerous and it should be used just once in a modpack.
	**/
	public var ?global:Array<Dynamic>;
	/**
	    If true, clears the vanilla achievements.
		
		Same goes for clearAchievements, it should be used just once in a modpack and global should be null aswell.
	**/
	public var ?clearAchievements:Bool; 
}


class Achievements
{
	public static var achievementsStuff:Array<Dynamic> = [
		// Name,
		// Description,
		// Achievement save tag,
		// Hidden achievement
		[
			"Freaky on a Friday Night",
			"Play on a Friday... Night.",
			'friday_night_play',
			true
		],
		[
			"She Calls Me Daddy Too",
			"Beat Week 1 on Hard with no Misses.",
			'week1_nomiss',
			false
		],
		["No More Tricks", "Beat Week 2 on Hard with no Misses.", 'week2_nomiss', false],
		[
			"Call Me The Hitman",
			"Beat Week 3 on Hard with no Misses.",
			'week3_nomiss',
			false
		],
		["Lady Killer", "Beat Week 4 on Hard with no Misses.", 'week4_nomiss', false],
		[
			"Missless Christmas",
			"Beat Week 5 on Hard with no Misses.",
			'week5_nomiss',
			false
		],
		["Highscore!!", "Beat Week 6 on Hard with no Misses.", 'week6_nomiss', false],
		[
			"You'll Pay For That...",
			"Beat Week 7 on Hard with no Misses.",
			'week7_nomiss',
			false
		],
		[
			"What a Funkin' Disaster!",
			"Complete a Song with a rating lower than 20%.",
			'ur_bad',
			false
		],
		[
			"Perfectionist",
			"Complete a Song with %100 accuracy.",
			'ur_good',
			false
		],
		[
			"Road to 10 Million",
			"Gain 10 million scores in total.",
			'ten_million',
			false
		],
		[
			"Roadkill Enthusiast",
			"Watch the Henchmen die over 100 times.",
			'roadkill_enthusiast',
			false
		],
		["Oversinging Much...?", "Hold down a note for 10 seconds.", 'oversinging', false],
		["Hyperactive", "Finish a Song without going Idle.", 'hype', false],
		["Just the Two of Us", "Finish a Song pressing only two keys.", 'two_keys', false],
		[
			"Toaster Gamer",
			"Have you tried to run the game on a toaster?",
			'toastie',
			false
		],
		["Debugger", "Beat the \"Test\" Stage from the Chart Editor.", 'debugger', true],
	];
	public static var copyAchievements = achievementsStuff.copy();

	public static var achievementMap:Map<String, Bool> = new Map();
	public static var achievementStats:Map<String, AchievementStats> = new Map();

	public static var henchmenDeath:Int = 0;

	public static function unlockAchievement(name:String, stats:AchievementStats):Bool
	{
		achievementMap.set(name, true);
		achievementStats.set(name, stats);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

		return FunkySettings.save();
	}

	public static function exists(name:String) {
		for (i in achievementsStuff) 
			if (i[2] == name) 
				return true;

		return false;
	}

	public static function isUnlocked(name:String):Bool
	{
		return if (achievementMap.exists(name)) achievementMap.get(name) else false;
	}

	public static function getIndex(name:String):Int
	{
		for (i in achievementsStuff)
		{
			if (i[2] == name)
				return achievementsStuff.indexOf(i);
		}

		return -1;
	}

	public static function loadModAchievements() {
		achievementsStuff = copyAchievements.copy();

		var paths:Array<String>= [Paths.mods('achievements/'),Paths.getPath('achievements/'),];
		for(i in paths.copy()){
			if(FileSystem.exists(i)){
				for(l in FileSystem.readDirectory(i)){
					if(l.endsWith('.json')){
						var meta:AchievementMeta = cast haxe.Json.parse(File.getContent(i + l));
						if(meta!=null){
							if(meta.clearAchievements)
								achievementsStuff=[];

							if(meta.global==null||meta.global.length<1){
								var achievement:Array<Dynamic> = [];
								achievement.push(meta.name);
								achievement.push(meta.desc);
								achievement.push(meta.save_tag);
								achievement.push(meta.hidden);
								var index:Null<Int> = meta.index;
								if(!achievementsStuff.contains(achievement)) {
									if(index==null||index<0){
										achievementsStuff.push(achievement.copy());
									}
									else {
										achievementsStuff.insert(index,achievement);
									}
								}
							}
							else{
								achievementsStuff = meta.global.copy();
							}
						}
					}
				}
			}
		}
	}

	public static function getModAchievements():Array<String> {
		var paths:Array<String>= [Paths.mods('achievements/'),Paths.getPath('achievements/'),];

		var luas:Array<String> = [];
		for(i in paths){
			if(FileSystem.exists(i)){
				for(l in FileSystem.readDirectory(i)){
					var pushedLuas = [];
					var file = l.substr(0, l.length - 4);
					//ignore lua files that does not have a json file
					if (l.endsWith('.lua') && FileSystem.exists(i+file+'.json') && !pushedLuas.contains(l)) {
						luas.push(i+l);
						pushedLuas.push(l);
					}
				}
			}
		}
		return luas.copy();
	}

	public static function getModAchievementMetas():Array<AchievementMeta> {
		var paths:Array<String>= [Paths.mods('achievements/'),Paths.getPath('achievements/'),];

		var metas = [];
		for(i in paths.copy())
			if(FileSystem.exists(i))
				for(l in FileSystem.readDirectory(i))
					if(l.endsWith('.json'))
					{
						try {
							var meta:AchievementMeta = cast haxe.Json.parse(File.getContent(i + l));
							metas.push(meta);
						}
						catch(e) {
							trace(e.stack);
						}
					}

		return metas.copy();
	}

	public static function getName(name:String)
	{
		if (!exists(name))
			return null;

		return achievementsStuff[getIndex(name)][0];
	}

	public static function getDesc(name:String)
	{
		if (!exists(name))
			return null;

		return achievementsStuff[getIndex(name)][1];
	}

	public static function getStats(name:String):AchievementStats
	{
		return if (achievementStats.exists(name)) achievementStats.get(name) else createStat();
	}

	public static function createStat(?song:String, ?date:Date, ?diff:Int, ?accuracy:Float, ?misses:Int)
	{
		var stat:AchievementStats = {
			song: song,
			date: date,
			diff: diff,
			accuracy: accuracy,
			misses: misses
		};

		return fixStat(stat);
	}

	public static function fixStat(stat:AchievementStats):AchievementStats
	{
		if (stat.song == null)
			stat.song = 'None';
		if (stat.date == null)
			stat.date = Date.now();
		if (stat.diff == null)
			stat.diff = -1;
		if (stat.misses == null)
			stat.misses = -1;

		return stat;
	}

	public static function loadAchievements():Bool
	{
		loadModAchievements();
		loadStats();

		var achieveSave:CocoaSave = FunkySettings.bind('achievements');

		if (achieveSave.data.henchmenDeath != null)
			henchmenDeath = achieveSave.data.henchmenDeath;

		if (achieveSave.data.achievementMap == null)
		{
			for (i in achievementsStuff)
				if (!i[3])
					achievementMap.set(i[2], false);

			return FunkySettings.save();
		}
		else
			achievementMap = achieveSave.data.achievementMap;

		return false;
	}

	public static function loadStats():Bool
	{
		var achieveSave:CocoaSave = FunkySettings.bind('achievements');

		if (achieveSave.data.achievementStats != null)
		{
			achievementStats = achieveSave.data.achievementStats;
			return true;
		}
		else
			FunkySettings.save();

		return false;
	}
}

class AttachedAchievement extends FlxSprite
{
	public var tracker:FlxSprite;
	public var id:String;

	public function new(x:Float = 0, y:Float = 0, id:String)
	{
		super(x, y);

		this.id = id;

		if (Achievements.isUnlocked(id))
			loadGraphic(Paths.image('achievements/$id'));
		else
			loadGraphic(Paths.image('achievements/lockedachievement'));

		setGraphicSize(Std.int(width * 0.7), Std.int(height * 0.7));
		updateHitbox();
		antialiasing = !FunkySettings.noAntialiasing;
	}

	override function update(elapsed:Float)
	{
		if (tracker != null)
			setPosition(tracker.x - 130, tracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	public function new(id:String, ?camera:FlxCamera = null)
	{
		super(x, y);

		var index:Int = Achievements.getIndex(id);

		FunkySettings.save();
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievements/$id'), true, 150, 150);
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = !FunkySettings.noAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280,
			Achievements.achievementsStuff[index][0], 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[index][1], 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if (camera != null)
		{
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween)
			{
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
					startDelay: 2.5,
					onComplete: function(twn:FlxTween)
					{
						alphaTween = null;
						remove(this);
						kill();
						if (onFinish != null)
							onFinish();
						destroy();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (alphaTween != null)
		{
			alphaTween.cancel();
		}

		super.destroy();
	}
}
