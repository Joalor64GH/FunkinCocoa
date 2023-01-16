package;

import flixel.FlxSprite;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

private typedef NoteSplashType = {
	public var noteType:String;
	public var noteData:Int;
	public var name:String;
}

private typedef NoteSplashAnim = {
	public var name:String;
	public var prefix:String;
	public var fps:Int;
	public var noteType:NoteSplashType;
	public var offsets:Array<Int>;
	public var indices:Array<Int>;
}

private typedef NoteSplashMeta = {
	public var animations:Map<String, NoteSplashAnim>;
	public var scale:Array<Float>;
	public var affectedByShader:Bool;
}

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = new ColorSwap();
	public var skin:String;
	public var meta(default, set):NoteSplashMeta;
	public static var DEFAULT_SKIN:String = "AllnoteSplashes";

	public var babyArrow:BabyArrow;

	var noteDataMap:Map<Int, String> = new Map();
	var noteTypeMap:Map<String, NoteSplashType> = new Map();
	var offsetTypeMap:Map<String, Array<Int>> = new Map();

	public function new(?splash:String)
	{
		super();

		alpha = FunkySettings.splashOpacity;

		var skin:String = splash;
		
		if (skin == null || skin.length < 1)
			skin = try PlayState.SONG.splashSkin catch(e) null;

		if (skin == null || skin.length < 1)
			skin = DEFAULT_SKIN;
		
		this.skin = skin;

		try frames = Paths.getSparrowAtlas(skin) catch (e) active = visible = false;

		var path:String = Paths.mods('images/$skin.json');
		if (!FileSystem.exists(path))
			path = Paths.getPath('images/$skin.json');
		if (FileSystem.exists(path))
		{
			var meta:Dynamic = Json.parse(File.getContent(path));

			if (meta != null)
			{
				var tempMeta:NoteSplashMeta = {
					animations: new Map(),
					scale: meta.scale,
					affectedByShader: meta.affectedByShader
				}
				for (i in Reflect.fields(meta.animations))
				{
					tempMeta.animations.set(i, Reflect.field(meta.animations, i));
				}

				this.meta = tempMeta;
			}
		}

		if (meta == null)
			meta = createMeta();
		
		if (meta.affectedByShader)
			shader = colorSwap.shader;

		if (!PlayState.isPixelStage)
			antialiasing = !FunkySettings.noAntialiasing;
		else
			antialiasing = false;
	}

	public function spawnSplashNote(note:Note, ?noteData:Int, ?customAnim:String, ?specialType:Bool, ?noteType:String)
	{	
		if (babyArrow != null)
			setPosition(babyArrow.x, babyArrow.y);

		colorSwap.hue = FunkySettings.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = FunkySettings.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = FunkySettings.arrowHSV[noteData % 4][2] / 100;

		if (shader != colorSwap.shader)
			shader = colorSwap.shader;

		var noteData:Null<Int> = noteData;
		if (noteData == null)
			noteData = note != null ? note.noteData : 0;
		noteData = noteData % 4;

		var anim:String = null;

		function playDefaultAnim(playAnim:Bool = true)
		{
			var animation:String = noteDataMap.get(noteData);
			if (animation != null && this.animation.exists(animation))
			{
				if (playAnim) 
					this.animation.play(animation);
				anim = animation;
			}
			else
				visible = false;
		}

		playDefaultAnim(false);

		if ((customAnim == null || customAnim.length < 1))
		{
			var note:Note = note;
			if (specialType && meta != null && noteType != null && noteType.length > 0 && meta.animations.exists(noteType))
			{
				note = new Note(0, noteData);
				note.noteType = try meta.animations.get(noteType).noteType.name catch (e) null;
			}

			if (note != null)
			{
				if (note.noteType != null && note.noteType.length > 0)
				{
					var noteType = null;
					for (i in noteTypeMap)
					{
						if (i.noteType == note.noteType || i.name == note.noteType)
							noteType = i;
					}
					if (noteType != null && (noteType.noteData % 4 == note.noteData % 4 || noteType.noteData == -1))
					{
						animation.play(noteType.name, true);
						anim = noteType.name;
					}
					else
					{	
						playDefaultAnim();
					}
				}
				else
					playDefaultAnim();
			}
			else
				playDefaultAnim();
		}
		else if (animation.exists(customAnim)) 
		{
			animation.play(customAnim, true);
			anim = customAnim;
		}
		else
			active = false;

		var offsets:Array<Int> = offsetTypeMap.get(anim);
		if (offsets != null)
		{
			offset.set(offsets[0], offsets[1]);
		}
		else if (noteType != null && noteType.length > 0)
		{
			offsets = offsetTypeMap.get(noteType);
			offset.set(offsets[0], offsets[1]);
		}
		animation.finishCallback = function(name:String)
		{
			kill();
		};
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (babyArrow != null)
		{
			//cameras = babyArrow.cameras;
			setPosition(babyArrow.x, babyArrow.y);
		}
	}

	public static function createMeta():NoteSplashMeta
	{
		return {
			animations: new Map(),
			scale: [1, 1],
			affectedByShader: true
		}
	}

	public static function addAnimationToMeta(scale:Array<Float>, meta:NoteSplashMeta, name:String, prefix:String, fps:Int, offsets:Array<Int>, indices:Array<Int>, noteType:String, noteData:Int):NoteSplashMeta
	{
		if (meta == null)
			meta = {
				animations: new Map(),
				scale: [1, 1],
				affectedByShader: true
			};

		meta.animations.set(name, {name: name, prefix: prefix, indices: indices, fps: fps, offsets: offsets, noteType: {noteType: noteType, noteData: noteData, name: name}});
		meta.scale = scale;
		return meta;
	}

	function set_meta(value:NoteSplashMeta):NoteSplashMeta 
	{
		if (value == null)
			return meta = createMeta();
		/*return try 
		{*/
			for (i in value.animations)
			{
				var key:String = i.name;
				if (i.prefix.length > 0 && key != null && key.length > 0)
				{
					if (i.indices != null && i.indices.length > 0 && key != null && key.length > 0)
						animation.addByIndices(key, i.prefix, i.indices, "", i.fps, false);
					else
						animation.addByPrefix(key, i.prefix, i.fps, false);
					offsetTypeMap.set(key, i.offsets);
					noteTypeMap.set(key, i.noteType);
					noteDataMap.set(i.noteType.noteData, key);
				}
			}
			scale.set(value.scale[0], value.scale[1]);
			return meta = value;
		//}
		/*catch (e)
		{
			trace(e.details());
			null;
		}*/
	}
}