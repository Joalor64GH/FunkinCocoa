package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = [
		'Resume', 
		'Restart Song', 
		'Change Difficulty', 
		'Exit to menu',
	];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var botplayText:FlxText;
	var opponentText:FlxText;

	var holdTime:Float;

	public function new(x:Float, y:Float)
	{
		super();

		if (PlayState.isStoryMode)
			menuItemsOG.insert(2, 'Restart Song w/ Cutscene');

		if (PlayState.chartingMode)
		{
			var num:Int = 2;

			menuItemsOG.insert(num, 'Toggle Botplay');
			menuItemsOG.insert(num + 1, 'Toggle Practice Mode');
			menuItemsOG.insert(num + 2, 'Leave Charting Mode');
		}

		if (CoolUtil.difficultyStuff.length < 2)
			menuItemsOG.remove('Change Difficulty');

		difficultyChoices = Song.availableSongs(PlayState.SONG.song).copy();
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		blueballedTxt.text = "Blueballed: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.practiceMode;
		add(practiceText);

		botplayText = new FlxText(20, FlxG.height - 40, 0, "BOTPLAY", 32);
		botplayText.scrollFactor.set();
		botplayText.setFormat(Paths.font('vcr.ttf'), 32);
		botplayText.x = FlxG.width - (botplayText.width + 20);
		botplayText.updateHitbox();
		botplayText.visible = PlayState.cpuControlled;
		add(botplayText);

		opponentText = new FlxText(20, botplayText.y - 45, 0, "OPPONENT MODE", 32);
		opponentText.scrollFactor.set();
		opponentText.setFormat(Paths.font('vcr.ttf'), 32);
		opponentText.updateHitbox();
		opponentText.visible = PlayState.leftSide;
		add(botplayText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		menuItems = menuItemsOG;
		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];
			for (i in 0...difficultyChoices.length - 1)
			{
				if (difficultyChoices[i] == daSelected)
				{
					var name:String = PlayState.SONG.song.toLowerCase();
					var poop = Highscore.formatSong(name);
					PlayState.SONG = Song.loadFromJson(poop, curSelected);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.cpuControlled = false;
					return;
				}
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.practiceMode = !PlayState.practiceMode;
					PlayState.usedPractice = true;
					practiceText.visible = PlayState.practiceMode;
				case "Restart Song":
					MusicBeatState.resetState();
				case 'Restart Song w/ Cutscene':
					PlayState.seenCutscene = false;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
				case 'Toggle Botplay':
					PlayState.cpuControlled = !PlayState.cpuControlled;
					PlayState.usedPractice = true;
					botplayText.visible = PlayState.cpuControlled;
					PlayState.instance.botplayTxt.visible = PlayState.cpuControlled;
				case 'Leave Charting Mode':
					PlayState.chartingMode = false;
					menuItemsOG.remove('Toggle Botplay');
					menuItemsOG.remove('Toggle Practice Mode');
					menuItemsOG.remove('Leave Charting Mode');
					menuItems = menuItemsOG;
					regenMenu();
					MusicBeatState.resetState();
				case "Exit to menu":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					PlayState.chartingMode = false;
					PlayState.campaignMisses = 0;
					CocoaTools.destroyMusic(FlxG.sound.music);
					if (PlayState.isStoryMode)
					{
						var weekSave = FunkySettings.bind('weeks');
						var map:Map<String, Dynamic> = weekSave.data.week;
						if (map == null) 
							map = new Map();
						var index:Array<String> = PlayState.storyPlayListOld.copy();
						for (i in index)
						{
							var intIndex:Int = index.indexOf(i);
							index.remove(i);
							i = CoolUtil.coolSongFormatter(i);
							index.insert(intIndex, i);
						}
						var intIndex:Int = index.indexOf(CoolUtil.coolSongFormatter(PlayState.SONG.song));
						map.set(WeekData.getWeekFileName(), {song: index[intIndex], index: intIndex});
						weekSave.data.week = map.copy();
						weekSave.flush();
						MusicBeatState.switchState(new StoryMenuState(true));
					}
					else
					{
						MusicBeatState.switchState(new FreeplayState(true));
					}
					
					//CocoaTools.resetMusic();
					PlayState.usedPractice = false;
					PlayState.changedDifficulty = false;
					PlayState.cpuControlled = false;

				case 'BACK':
					menuItems = menuItemsOG;
					regenMenu();
			}
		}
	}

	override function close():Void
	{
		pauseMusic.destroy();
		
		super.close();
	}

	override function destroy()
	{
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function regenMenu():Void
	{
		grpMenuShit.clear();

		for (i in 0...menuItems.length)
		{
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);
		}

		curSelected = 0;
		changeSelection();
	}
}
