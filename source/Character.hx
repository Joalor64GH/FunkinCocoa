package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var miss_duration:Null<Float>;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var missTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var missDuration:Float = 2; // Multiplier of how long a character holds the miss pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"

	public var healthIcon:String = 'face';

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var animationsArray:Array<AnimArray> = [];
	public var script:FunkinScript = new FunkinScript();

	public static final DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map();

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = !FunkySettings.noAntialiasing;

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
			default:
				var characterPath:String = 'characters/' + curCharacter;
				var path:String = Paths.mods(characterPath + '.cocoa');
				if (!FileSystem.exists(path))
				{
					path = Paths.getPath(characterPath + '.cocoa');
				}
				if (!FileSystem.exists(path))
					path = Paths.getPath('characters/$DEFAULT_CHARACTER.cocoa');

				/*-var yath:CharacterFile = Yaml.read(path.substring(0, path.length - 5) + "yaml", yaml.Parser.options().useObjects());
				File.saveContent(path, JsonToCharacter(yath));*/

				try 
				{
					script.doString(File.getContent(path));
					var anims:String = script.call("createCharacter", [this]);
					animationsArray = cast Json.parse(CoolUtil.decode(anims)).anims;
				}
				catch (e)
				{
					trace('FAILED TO LOAD $curCharacter!!!');
				}
				
			/*for (i in characters)
			{
				
				//trace(i);
				var path:String = 'assets/characters/${i}.cocoa';
				var string:String = File.getContent(path);
				var icon:String = new SScript().doString(string).call('returnIcon', []);
				trace(icon);
				string = string.replace('return "$icon"', 'return "${CoolUtil.encode(icon)}"');
				File.saveContent(path, string);
			}*/
				// trace('Loaded file to character ' + curCharacter);
		}

		originalFlipX = flipX;

		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;
		}
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			recalculateDanceIdle();

			if (specialAnim)
			{
				holdTimer = 0;
				heyTimer = 0;
			}

			if (heyTimer > 0)
			{
				heyTimer -= elapsed;

				if (heyTimer <= 0)
				{
					dance();
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (((!isPlayer && !PlayState.leftSide) || (isPlayer && PlayState.leftSide)) && !specialAnim)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if (((!isPlayer && PlayState.leftSide) || (isPlayer && !PlayState.leftSide)) && !specialAnim)
			{
				if (!animation.curAnim.name.endsWith('miss')
					&& animation.curAnim.name.startsWith('sing')
					&& !isPlayer
					&& PlayState.leftSide)
				{
					holdTimer += elapsed;
				}

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.name.startsWith('sing') && animation.curAnim.finished)
				{
					missTimer += elapsed;

					if (missTimer >= Conductor.stepCrochet * 0.001 * missDuration)
					{
						dance();
						missTimer = 0;
					}
				}
			}
		}

		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null)
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set();

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function recalculateDanceIdle()
	{
		danceIdle = animation.exists('danceLeft') && animation.exists('danceRight');
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public static function JsonToCharacter(json:CharacterFile):String
	{
		var script:String = 'function createCharacter(char:Character)';
				script += '\n{';
				script += '\n\t';
				if (Paths.exists('images/' + json.image + '.txt'))
				{
					script += 'char.frames = Paths.getPackerAtlas(\"${json.image}\");';
				}
				else if (Paths.exists('images/${json.image}.json'))
				{
					script += 'char.frames = Paths.getJsonAtlas(\"${json.image}\");';
				}
				else
				{
					script += 'char.frames = Paths.getSparrowAtlas(\"${json.image}\");';
				}
				script += '\n\tchar.imageFile = "${json.image}";';
				script += '\n\n';
				var anims:Array<AnimArray> = try json.animations catch(e) [{anim: "idle", name: "BF idle dance", fps: 24, indices: null, offsets: [0, 0], loop: false}];
				for (anim in anims)
				{
					var animAnim:String = '' + anim.anim;
					var animName:String = '' + anim.name;
					var animFps:Int = anim.fps;
					var animLoop:Bool = !!anim.loop; 
					var animIndices:Array<Int> = anim.indices;
					var literal:String = '\n';
					if (anims.indexOf(anim) == anims.length - 1)
						literal = '';

					if (animIndices != null && animIndices.length > 0)
						script += '\tchar.animation.addByIndices(\"$animAnim\", \"$animName\", $animIndices, "", $animFps, $animLoop);$literal';
					else
						script += '\tchar.animation.addByPrefix(\"$animAnim\", \"$animName\", $animFps, $animLoop);$literal';
				}
				script += '\n\n';
				for (anim in anims)
					if (anim.offsets != null && anim.offsets.length > 0)
					{
						var literal = '\n';
						if (anims.indexOf(anim) == anims.length - 1)
							literal = '';

						script += '\tchar.addOffset("${"" + anim.anim}", ${anim.offsets[0]}, ${anim.offsets[1]});$literal';
					}

				var anim:{anims:Array<AnimArray>} = {anims: json.animations};
				var anim:String = CoolUtil.encode(Json.stringify(anim, "\t"));
				script += '\n\n';
				script += '\tchar.scale.set(${json.scale}, ${json.scale});\n';
				script += '\tchar.updateHitbox();\n';
				script += '\n\tchar.positionArray = ${json.position};';
				script += '\n\tchar.cameraPosition = ${json.camera_position};';
				script += '\n\n\tchar.healthIcon = "${json.healthicon}";';
				script += '\n\tchar.singDuration = ${json.sing_duration};';
				script += '\n\tchar.missDuration = ${json.miss_duration != null ? json.miss_duration : 1.3};\n';
				script += '\n\tchar.flipX = ${!!json.flip_x};';
				script += '\n\n\tchar.healthColorArray = ${json.healthbar_colors != null && json.healthbar_colors.length > 2 ? json.healthbar_colors : [0, 0, 0]};';
				script += '\n\n\tchar.antialiasing = ${!json.no_antialiasing};';
				script += '\n\tchar.noAntialiasing = !char.antialiasing;';
				script += '\n\n\t//DO NOT CHANGE THIS';
				script += '\n\treturn "$anim";';
				script += '\n}';

				script += '\n\nfunction returnIcon()';
				script += '\n{';
				script += '\n\treturn "${CoolUtil.encode(json.healthicon)}";';
				script += '\n}';
			
			return script;
	}
}
