package;

import flixel.FlxSprite;
import flixel.util.FlxTimer;

using StringTools;

class BabyArrow extends FlxSprite
{
	var colorSwap:ColorSwap;

	public var hold:Bool;
	public var player:Int;
	public var updateAlpha:Bool = true;

	var noteData:Int = 0;

	var timer:FlxTimer;
	public var holdTimer:Float;

	public function new(x:Float, y:Float, leData:Int, player:Int)
	{
		super(x, y);

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;

		var skin:String = 'NOTE_assets';
		if (PlayState.SONG != null)
			if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
				skin = PlayState.SONG.arrowSkin;
		var isPixelStage:Bool = PlayState.isPixelStage;

		if (isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + skin));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + skin), true, Math.floor(width), Math.floor(height));
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purplel', [4]);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			updateHitbox();
			antialiasing = false;

			switch (Math.abs(leData % 4))
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = !FunkySettings.noAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(leData % 4))
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}

		updateHitbox();
		scrollFactor.set();
	}

	public function postAddedToGroup() 
	{
		playAnim('static');

		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float)
	{
		if (hold)
		{
			if (animation.curAnim.name == 'confirm' && animation.curAnim.finished && holdTimer > 0)
			{
				holdTimer -= elapsed * 1.07;

				if (holdTimer <= 0)
				{
					playAnim('static');
					hold = false;
					holdTimer = 0;
				}
			}
		}
		
		if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage)
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();

		if (animation.curAnim.name == 'static')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			colorSwap.hue = FunkySettings.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = FunkySettings.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = FunkySettings.arrowHSV[noteData % 4][2] / 100;

			if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage)
			{
				centerOrigin();
			}
		}
	}
}
