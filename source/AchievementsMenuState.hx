package;

#if desktop
import Discord.DiscordClient;
#end
import Achievements;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class AchievementsMenuState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	var options:Array<String> = [];
	var grpOptions:FlxTypedGroup<Alphabet>;

	static var curSelected:Int = 0;

	var curAchievement:String;

	var achievementArray:Array<AttachedAchievement> = [];
	var achievementIndex:Array<Int> = [];
	var descText:FlxText;

	var achieveText:FlxText;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = !FunkySettings.noAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		Achievements.loadAchievements();
		for (i in 0...Achievements.achievementsStuff.length)
			if (!Achievements.achievementsStuff[i][3] || Achievements.achievementMap.exists(Achievements.achievementsStuff[i][2]))
			{
				options.push(Achievements.achievementsStuff[i]);
				achievementIndex.push(i);
			}

		for (i in 0...options.length)
		{
			var achieveName:String = Achievements.achievementsStuff[achievementIndex[i]][2];
			var optionText:Alphabet = new Alphabet(0, (100 * i) + 210,
				Achievements.isUnlocked(achieveName) ? Achievements.achievementsStuff[achievementIndex[i]][0] : '?', false, false);
			optionText.isMenuItem = true;
			optionText.x += 280;
			optionText.xAdd = 200;
			optionText.targetY = i;
			grpOptions.add(optionText);

			var icon:AttachedAchievement = new AttachedAchievement(optionText.x - 105, optionText.y, achieveName);
			icon.tracker = optionText;
			achievementArray.push(icon);
			add(icon);
		}

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		changeSelection();

		var controls = FunkySettings.controls.copy().get('ACCEPT')[0];
		achieveText = new FlxText(75, FlxG.height - 680, 0, 'Press $controls to show advanced information about this achievement.');
		achieveText.setFormat(Paths.font('vcr.ttf'), 24, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		achieveText.borderQuality = 2;
		achieveText.screenCenter(X);
		achieveText.y -= 20;
		achieveText.scrollFactor.set();
		add(achieveText);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		curAchievement = Achievements.achievementsStuff[achievementIndex[curSelected]][2];

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			changeSelection(-FlxG.mouse.wheel);
		}

		achieveText.visible = Achievements.isUnlocked(curAchievement);

		if (controls.ACCEPT)
			openSubState(new AchievementsSubstate(curAchievement));

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		for (i in 0...achievementArray.length)
		{
			achievementArray[i].alpha = 0.6;

			if (i == curSelected)
				achievementArray[i].alpha = 1;
		}

		descText.text = Achievements.achievementsStuff[achievementIndex[curSelected]][1];
		if (descText.text == Achievements.getDesc('ten_million'))
			descText.text += '\nGained Score: ${CocoaTools.formatScore(Highscore.totalScore)}';
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	#end
}
