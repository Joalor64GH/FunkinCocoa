package;

import Achievements.AchievementStats;
import Achievements.AttachedAchievement;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class AchievementsSubstate extends MusicBeatSubstate
{
	var achievement:String;
	var stat:AchievementStats;
	var stats:Array<Dynamic> = [];

	var name:FlxText;
	var desc:FlxText;

	var statText:FlxText;
	var left:FlxText;
	var right:FlxText;

	var tweens:Array<FlxTween> = [];

	var canMove:Bool;

	static var curSelected:Int;

	public function new(achievement:String)
	{
		super();

		this.achievement = achievement;

		stat = Achievements.getStats(achievement);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.updateHitbox();
		add(bg);

		var icon:AttachedAchievement = new AttachedAchievement(achievement);
		icon.screenCenter();
		icon.y -= FlxG.height * 2;
		// make sure it is off the screen??
		icon.setGraphicSize(Std.int(icon.width * 1.1));
		icon.updateHitbox();
		add(icon);

		var achieveName:String = Achievements.getName(achievement);
		var description:String = Achievements.getDesc(achievement);

		name = new FlxText(0, 0, 1250, achieveName, 48);
		name.screenCenter();
		name.y = FlxG.height / 2 - 20;
		var nameX:String = Std.string(name.x);
		name.x -= FlxG.height * 2;
		name.setFormat(Paths.font('muff.ttf'), 72, FlxColor.WHITE, CENTER);
		add(name);

		desc = new FlxText(0, 0, 1250, description, 36);
		desc.screenCenter();
		desc.y = FlxG.height / 2 + 50;
		var descX:String = Std.string(desc.x);
		desc.x += FlxG.height * 2;
		desc.setFormat(Paths.font('muff.ttf'), 60, FlxColor.WHITE, CENTER);
		add(desc);

		left = new FlxText(20, "<");
		left.y += FlxG.height * 2;
		left.setFormat(Paths.font('muff.ttf'), 60, LEFT);
		add(left);

		right = new FlxText(FlxG.width - 45, ">");
		right.y += FlxG.height * 2;
		right.setFormat(Paths.font('muff.ttf'), 60, RIGHT);
		add(right);

		statText = new FlxText(0, 0, 1200);
		statText.screenCenter();
		statText.y += FlxG.height * 2;
		statText.setFormat(Paths.font('muff.ttf'), 60, CENTER);
		add(statText);

		FlxTween.tween(bg, {alpha: 0.3}, 0.4, {ease: FlxEase.quadInOut});

		new FlxTimer().start(0.2, function(tmr)
		{
			tweens.push(FlxTween.tween(icon, {y: FlxG.height / 2 - 140}, 1, {ease: FlxEase.expoInOut}));

			new FlxTimer().start(0.2, function(tmr)
			{
				tweens.push(FlxTween.tween(name, {x: Std.parseFloat(nameX)}, 1, {ease: FlxEase.expoInOut}));

				new FlxTimer().start(0.2, function(tmr)
				{
					tweens.push(FlxTween.tween(desc, {x: Std.parseFloat(descX)}, 1, {ease: FlxEase.expoInOut}));

					new FlxTimer().start(0.4, function(tmr)
					{
						tweens.push(FlxTween.tween(left, {y: FlxG.height / 2 + 250}, 1, {ease: FlxEase.expoInOut}));
						tweens.push(FlxTween.tween(right, {y: FlxG.height / 2 + 250}, 1, {ease: FlxEase.expoInOut}));

						new FlxTimer().start(0.1, function(tmr)
						{
							tweens.push(FlxTween.tween(statText, {y: FlxG.height / 2 + 250}, 1, {ease: FlxEase.expoInOut}));
							canMove = true;
						});
					});
				});
			});
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
			close();

		/*if (controls.ACCEPT)
			for (tween in tweens)
				if (tween.active)
				{
					@:privateAccess
					tween.finish();
					tweens.remove(tween);
					tween = null;
				}*/

		if (canMove)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

				if (curSelected <= 0)
					curSelected = 4;
				else
					curSelected--;
			}

			if (controls.UI_LEFT)
			{
				left.color = FlxColor.BLACK;
				left.scale.set(0.8, 0.8);
				left.updateHitbox();
			}
			else
			{
				left.color = FlxColor.WHITE;
				left.scale.set(1, 1);
				left.updateHitbox();
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

				if (curSelected >= 4)
					curSelected = 0;
				else
					curSelected++;
			}

			if (controls.UI_RIGHT)
			{
				right.color = FlxColor.BLACK;
				right.scale.set(0.8, 0.8);
				right.updateHitbox();
			}
			else
			{
				right.color = FlxColor.WHITE;
				right.scale.set(1, 1);
				right.updateHitbox();
			}

			switch (curSelected)
			{
				case 0:
					statText.text = 'Date: ${DateTools.format(stat.date, "%Y/%m/%d %H:%M:%S")}';
				case 1:
					statText.text = 'Song: ${stat.song}';
				case 2:
					if (stat.diff > -1)
						statText.text = 'Used Difficulty: ${CoolUtil.difficultyStuff[stat.diff]}';
					else
						statText.text = 'Used Difficulty: None';
				case 3:
					if (stat.accuracy != Math.NEGATIVE_INFINITY && stat.accuracy != null)
						statText.text = 'Accuracy: ${stat.accuracy}';
					else
						statText.text = 'Accuracy: None';
				case 4:
					if (stat.misses > -1)
						statText.text = 'Misses: ${stat.misses}';
					else
						statText.text = 'Misses: None';
			}
		}
	}
}
