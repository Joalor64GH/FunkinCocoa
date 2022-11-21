package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import sys.FileSystem;

class CreditsState extends MusicBeatState
{
	public static var pisspoop:Array<Array<Dynamic>> = [/*check credits.hx*/];

	var creGroup:FlxTypedGroup<Alphabet> = new FlxTypedGroup();
	var iconGroup:FlxTypedGroup<CreditsIcon> = new FlxTypedGroup();
	var curIcon:CreditsIcon;

	var bg:FlxSprite;
	var bgTween:FlxTween;
	var curSelected:Int = -1;

	var moveTween:FlxTween;
	var descBox:FlxSprite;
	var descText:FlxText;

	override function create():Void
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		add(bg);

		var scriptFile:String = Paths.mods('credits.hx');
		if (!FileSystem.exists(scriptFile))
			scriptFile = Paths.getPath('credits.hx');
		if (FileSystem.exists(scriptFile))
		{
			var script:FunkinScript = new FunkinScript(scriptFile);
			script.clear();
		}

		for (i in 0...pisspoop.length)
		{
			var alphabet:Alphabet = new Alphabet(0, 70 * i, pisspoop[i][0], !isSelectable(i));
			alphabet.isMenuItem = true;
			alphabet.menuType = 'Centered';
			alphabet.targetY = i;
			alphabet.yAdd -= 70;
			creGroup.add(alphabet);

			if (isSelectable(i))
			{
				var icon:CreditsIcon = new CreditsIcon(pisspoop[i][1]);
				icon.alphabet = alphabet;

				if (pisspoop[i][5] != null)
				{
					var pissX:Null<Float> = Std.parseFloat(pisspoop[i][5][0]);
					var pissY:Null<Float> = Std.parseFloat(pisspoop[i][5][1]);

					if (pissX != null && !Math.isNaN(pissX))
						icon.offsetX = pissX;
					if (pissY != null && !Math.isNaN(pissY))
						icon.offsetY = pissY;
				}

				iconGroup.add(icon);

				if (curSelected == -1)
					curSelected = i;
			}
		}

		add(creGroup);
		add(iconGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height - 75 - 60, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		add(descText);

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		for (i in iconGroup)
			if (i.alpha == 1)
			{
				curIcon = i;
				break;
			}

		if (curIcon != null)
		{
			var lerp:Float = CoolUtil.boundTo(1 - (elapsed * 10), 0, 1);
			var X:Float = FlxMath.lerp(1, curIcon.scale.x, lerp);
			var Y:Float = FlxMath.lerp(1, curIcon.scale.y, lerp);
			curIcon.scale.set(X, Y);
		}

		if (descBox != null && descText != null)
			descBox.setPosition(descText.x, descText.y - 20);

		if (controls.UI_DOWN_P)
			changeSelection(1);
		else if (controls.UI_UP_P)
			changeSelection(-1);
		else if (controls.BACK)
			MusicBeatState.switchState(new MainMenuState());
		else if (FlxG.mouse.wheel != 0)
			changeSelection(-FlxG.mouse.wheel);
		else if (controls.ACCEPT && pisspoop[curSelected][3] != null && isSelectable(curSelected))
			CoolUtil.browserLoad(pisspoop[curSelected][3]);
	}

	override function beatHit()
	{
		super.beatHit();

		if (curIcon != null)
		{
			curIcon.scale.set(1.12, 1.12);
		}
	}

	function changeSelection(add:Int = 0)
	{
		do
		{
			curSelected += add;
			if (curSelected < 0)
				curSelected = pisspoop.length - 1;
			if (curSelected >= pisspoop.length)
				curSelected = 0;
		}
		while (!isSelectable(curSelected));

		var bullShit:Int = 0;

		for (item in creGroup)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (isSelectable(bullShit - 1))
			{
				item.alpha = 0.6;

				if (item.targetY == 0)
					item.alpha = 1;
			}
		}

		for (icon in iconGroup)
			icon.scale.set(1, 1);

		if (bgTween != null)
			bgTween.cancel();

		if (pisspoop[curSelected][4] != null)
		{
			var newColor:FlxColor = FlxColor.fromString('#${pisspoop[curSelected][4]}');
			bgTween = FlxTween.color(bg, 1, bg.color, newColor, {onComplete: function(twn:FlxTween) bgTween = null});
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.8);

		descText.text = pisspoop[curSelected][2];
		descText.y = FlxG.height - 75 - 60;

		if (moveTween != null)
			moveTween.cancel();

		moveTween = FlxTween.tween(descText, {y: descText.y + 35}, 0.2, {ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) moveTween = null});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 40));
		descBox.updateHitbox();
	}

	function isSelectable(id:Int)
	{
		return pisspoop[id].length > 1;
	}
}
