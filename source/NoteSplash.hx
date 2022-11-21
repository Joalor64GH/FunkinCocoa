package;

import flixel.FlxSprite;
import haxe.Json;

using StringTools;

private typedef NoteSplashMeta = {
	public var offsets:Array<Array<Float>>;
	public var menuOffsets:Array<Array<Float>>;
	public var framerate:Int;
};

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = new ColorSwap();
	public var skin:String;
	public var meta:NoteSplashMeta;
	public static var DEFAULT_SKIN:String = "AllnoteSplashes";

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		alpha = FunkySettings.splashOpacity;

		var skin:String = try PlayState.SONG.splashSkin catch(e) null;

		if (skin == null || skin.length < 1)
			skin = FunkySettings.splashSkin;

		if (skin != DEFAULT_SKIN)
		{
			scale.set(.7, .7);
			updateHitbox();
		}

		meta = Json.parse(Paths.splash(skin));

		this.skin = skin;

		frames = Paths.getSparrowAtlas(skin);

		animation.addByPrefix('splash 0 0', 'purple0', 24, false);
		animation.addByPrefix('splash 0 1', 'blue0', 24, false);
		animation.addByPrefix('splash 0 2', 'green0', 24, false);
		animation.addByPrefix('splash 0 3', 'red0', 24, false);
		animation.addByPrefix('dodge splash', 'yellow0', 24, false);
		animation.addByPrefix('hurt splash', 'hurt0', 24, false);

		if (!PlayState.isPixelStage)
			antialiasing = !FunkySettings.noAntialiasing;
		else
			antialiasing = false;
	}

	public function spawnSplashNote(note:Note, ?noteData:Int, ?setOffset:Bool = true)
	{
		colorSwap.hue = FunkySettings.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = FunkySettings.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = FunkySettings.arrowHSV[noteData % 4][2] / 100;

		shader = colorSwap.shader;

		var noteData:Null<Int> = noteData;
		if (noteData == null)
			noteData = note.noteData;
		noteData = noteData % 4;

		if (note != null)
		{
			if (note.noteType == 'Hurt Note')
				animation.play('hurt splash', true);
			else if (note.noteType == 'Must Press Note')
				animation.play('dodge splash', true);
			else if (note.noteSplashTexture != null)
				animation.play(note.noteSplashTexture, true);
			else
				animation.play('splash 0 ${note.noteData}', true);
		}
		else
			animation.play('splash 0 ${noteData % 4}', true);

		animation.finishCallback = function(name:String)
		{
			kill();
		};

		animation.curAnim.frameRate = try meta.framerate catch(e) 24;

		if (setOffset)
		{
			offset.set(width * .3, height * .3);
			if (meta != null && meta.offsets != null)
			{
				offset.x += meta.offsets[noteData][0];
				offset.y += meta.offsets[noteData][1];
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
