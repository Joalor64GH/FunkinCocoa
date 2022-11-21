package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import yaml.Yaml;
import yaml.Renderer;
import yaml.Parser;

using StringTools;

private enum CharacterType 
{
	COCOA;
	//UNDERSCORE_;
}

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
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static final DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, type:CharacterType = COCOA)
	{
		super(x, y);

		animOffsets = new Map();

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = !FunkySettings.noAntialiasing;

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode him instead':
			default:
			if (type == COCOA)
			{
				var characterPath:String = 'characters/' + curCharacter;
				var path:String = Paths.mods(characterPath + '.yaml');
				if (!FileSystem.exists(path))
				{
					path = Paths.getPath(characterPath + '.yaml');
				}

				if (!FileSystem.exists(path))
				{
					path = Paths.mods('$characterPath.char');
					if (!FileSystem.exists(path))
					{
						if (!FileSystem.exists(path))
							path = Paths.getPath('$characterPath.char');
						if (!FileSystem.exists(path))
							path = Paths.getPath('characters/bf.char');

						if (FileSystem.exists(path))
						{
							var cot:String = File.getContent(path);
							var encode:String = CoolUtil.decode(CoolUtil.decode(cot));
							path = path.substring(0, path.length - 4) + 'yaml';
							var characterFile:CharacterFile = Json.parse(encode);
							Yaml.write(path, characterFile, Renderer.options().setFlowLevel(1));
						}
						else 
						{
							path = Paths.mods('$characterPath.json');
							if (!FileSystem.exists(path))
								path = Paths.getPath('$characterPath.json');
							if (!FileSystem.exists(path))
								path = Paths.getPath('characters/bf.json');

							if (FileSystem.exists(path))
							{
								var cot:String = File.getContent(path);
								var encodedFile:CharacterFile = Json.parse(cot);
								path = path.substring(0, path.length - 4) + 'yaml';
								Yaml.write(path, encodedFile, Renderer.options().setFlowLevel(1));
							}
						}
					}
					else
					{
						var cot:String = File.getContent(path);
						var encode:String = CoolUtil.decode(CoolUtil.decode(cot));
						path = path.substring(0, path.length - 4) + 'yaml';
						var characterFile:CharacterFile = Json.parse(encode);
						Yaml.write(path, characterFile, Renderer.options().setFlowLevel(1));
					}
				}

				var json:CharacterFile = cast Yaml.read(path.substring(0, path.length - 4) + 'yaml', Parser.options().useObjects());
				if (Paths.exists('images/' + json.image + '.txt'))
				{
					frames = Paths.getPackerAtlas(json.image);
				}
				else if (Paths.exists('images/${json.image}.json'))
				{
					frames = Paths.getJsonAtlas(json.image);
				}
				else
				{
					frames = Paths.getSparrowAtlas(json.image);
				}
				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;

				if (json.miss_duration != null)
					missDuration = json.miss_duration;
				else
					missDuration = 1.5;

				flipX = !!json.flip_x;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (FunkySettings.noAntialiasing)
					antialiasing = false;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;
						if (animIndices != null && animIndices.length > 0)
						{
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						}
						else
						{
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (anim.offsets != null && anim.offsets.length > 1)
						{
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
				// trace('Loaded file to character ' + curCharacter);
			}
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
}
