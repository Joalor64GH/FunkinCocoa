package;

#if desktop
import Discord.DiscordClient;
#end
import Achievements;
import Controls.Control;
import DialogueBoxPsych;
import FunkinLua;
import Song.SwagSong;
import StageData;
import Tankmen.Pico;
import Tankmen.TankmenSpawn;
import animateatlas.AtlasFrameMaker;
import editors.CharacterEditorState;
import editors.ChartingState;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingMap:Map<Int, String> = new Map();

	public static var instance:PlayState;

	public static var chartingMode:Bool;
	public static var leftSide:Bool;

	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, CocoaSave> = new Map();
	public var modchartGroups:Map<String, FlxTypedSpriteGroup<ModchartSprite>> = new Map();

	// event variables
	var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyPlayListOld:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;

	public var boyfriend:Boyfriend;

	public var sustainNotes:FlxTypedGroup<Note>;
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var events:Array<EventNote> = [];

	var strumLine:FlxSprite;
	var curSection:Int = 0;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	static var prevCamFollow:FlxPoint;
	static var prevCamFollowPos:FlxObject;

	var cameraSpeed:Float = 2.4;
	var camIntensity:Float = 0.03;

	public static var applicationName(default, set):String = 'Friday Night Funkin\'';

	public var strumLineNotes:FlxTypedGroup<BabyArrow>;
	public var cpuStrums:FlxTypedGroup<BabyArrow>;
	public var playerStrums:FlxTypedGroup<BabyArrow>;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	final missAnims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var camZooming:Bool = false;
	var curSong:String = "";

	var gfSpeed:Int = 2;

	public var health:Float = 1;

	var combo:Int = 0;

	var gainMultiplier:Float = 1;
	var lossMultiplier:Float = 1;

	var sickGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
	var sickNumberGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

	var healthBarBG:AbsoluteSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	var timeBarBG:FlxSprite;

	public var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	var updateTime:Bool = false;

	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;
	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var tower:BGSprite;
	public var tankRolling:BGSprite;
	public var tankmanRun:FlxTypedGroup<Tankmen>;
	public var tankSprites:FlxTypedSpriteGroup<BGSprite> = new FlxTypedSpriteGroup();
	public var tankBop1:BGSprite;
	public var tankBop2:BGSprite;
	public var tankBop3:BGSprite;
	public var tankBop4:BGSprite;
	public var tankBop5:BGSprite;
	public var tankBop6:BGSprite;

	var Pico:Pico;
	var Tankmen:TankmenSpawn;

	public var songScore:Int = 0;
	public var misses:Int = 0;

	public static var weekMisses:Int;

	public var scoreTxt:FlxText;

	public var accuracy:Float = Math.POSITIVE_INFINITY;
	public var totalNotesMissed:Int;
	public var totalNotesHit:Float;

	public var sicks:Int;
	public var goods:Int;
	public var bads:Int;
	public var shits:Int;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var instakillEnabled:Bool;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;

	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var scriptArray:Array<FunkinScript> = [];
	public var luaArray:Array<FunkinLua> = [];
	public var achievementArray:Array<FunkinLua> = [];
	public var achievementWeeks:Array<String> = [];

	var keysArray:Array<Array<FlxKey>> = [];

	// Achievement shit
	var keysPressed:Array<Bool> = [false, false, false, false];
	var keysAchievement:Array<Bool> = [false, false, false, false];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public var backgroundGroup:FlxTypedGroup<FlxSprite>;
	public var foregroundGroup:FlxTypedGroup<FlxSprite>;

	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var curSongSpeed(default, set):Float;

	var noteKill:Float;
	var firstTimeSettingSpeed:Bool = true;

	override public function create()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Paths.inst(SONG.song);
		if (SONG.needsVoices)
			Paths.voices(SONG.song);

		var comboimage:String = 'judgements/combo';
		if (isPixelStage)
			comboimage += '-pixel';

		for (i in ["shit", "bad", "good", "sick"])
		{
			var judgementPath:String = 'judgements/${i}';
			if (isPixelStage)
			{
				judgementPath += '-pixel';
			}
			Paths.image(judgementPath);
		}
		for (i in 0...10)
		{
			var numPath:String = 'numbers/num$i${isPixelStage ? "-pixel" : ""}';
			Paths.image(numPath);
		}

		Paths.image(comboimage);

		var loader:Loader = new Loader();
		var name:String = '$applicationName';

		instance = this;

		practiceMode = false;
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		// FlxG.cameras.setDefaultDrawTarget(camGame, true);

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		leftSide = GameplayOption.options.get('opponent_mode');
		cpuControlled = GameplayOption.options.get('botplay');
		instakillEnabled = GameplayOption.options.get('instakill');
		practiceMode = GameplayOption.options.get('practice_mode');
		gainMultiplier = GameplayOption.options.get('health_gain');
		lossMultiplier = GameplayOption.options.get('health_miss');

		persistentUpdate = true;
		persistentDraw = true;

		for (i in 0...10)
			ratingMap.set(i, "You stink!");
		for (a in 10...20)
			ratingMap.set(a, "Shit");
		for (b in 20...30)
			ratingMap.set(b, "Very bad");
		for (c in 30...50)
			ratingMap.set(c, "Bad");
		for (l in 50...60)
			ratingMap.set(l, "Maybe");
		for (e in 60...70)
			ratingMap.set(e, "Meh");
		for (e in 70...80)
			ratingMap.set(e, "Good");
		for (f in 80...90)
			ratingMap.set(f, "Perfect");
		for (g in 90...100)
			ratingMap.set(g, "Sick!");

		ratingMap.set(69, "Noice");
		ratingMap.set(100, "Marvelous!!");
		ratingMap.set(420, "Cock and balls");

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		var key:Map<String, Array<FlxKey>> = FunkySettings.controls.copy();

		keysArray = [
			copyKey(key.get('NOTE_LEFT')),
			copyKey(key.get('NOTE_DOWN')),
			copyKey(key.get('NOTE_UP')),
			copyKey(key.get('NOTE_RIGHT'))
		];

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', 1);

		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficultyStuff[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = SONG.stage;
		// trace('stage is: ' + curStage);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly nice':
					curStage = 'philly';
				case 'milf' | 'satin panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'warzone';
				default:
					curStage = 'stage';
			}
		}

		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);

		if (stageData == null)
		{
			stageData = {
				defaultZoom: 0.8,
				isPixelStage: false,
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],

				hide_girlfriend: false,
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		backgroundGroup = new FlxTypedGroup<FlxSprite>();
		foregroundGroup = new FlxTypedGroup<FlxSprite>();

		switch (curStage)
		{
			case 'stage':
				var bg:BGSprite = new BGSprite('stages/stage/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!FunkySettings.lowGraphics)
				{
					var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stages/stage/stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky':
				if (!FunkySettings.lowGraphics)
					halloweenBG = new BGSprite('stages/spooky/halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				else
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);

				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

			case 'philly': // Week 3
				if (!FunkySettings.lowGraphics)
				{
					var bg:BGSprite = new BGSprite('stages/philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('stages/philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('stages/philly/win' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if (!FunkySettings.lowGraphics)
				{
					var streetBehind:BGSprite = new BGSprite('stages/philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('stages/philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('week3/train_passes'));
				CoolUtil.precacheSound('week3/train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('stages/philly/street', -40, 50);
				add(street);

			case 'limo': // Week 4
				var skyBG:BGSprite = new BGSprite('stages/limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!FunkySettings.lowGraphics)
				{
					limoMetalPole = new BGSprite('stages/limo/gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('stages/limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('stages/limo/gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					// PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					// PRECACHE SOUND
					CoolUtil.precacheSound('week4/dancerdeath');
				}

				limo = new BGSprite('stages/limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('stages/limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': // Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('stages/mall/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!FunkySettings.lowGraphics)
				{
					upperBoppers = new BGSprite('stages/mall/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('stages/mall/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('stages/mall/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('stages/mall/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('stages/mall/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('stages/mall/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('week5/Lights_Shut_off');

			case 'mallEvil': // Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('stages/mall/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('stages/mall/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('stages/mall/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': // Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'week6/fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'pixel/gameOver-pixel';
				GameOverSubstate.endSoundName = 'pixel/gameOverEnd-pixel';
				GameOverSubstate.characterName = 'week6/bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if (!FunkySettings.lowGraphics)
				{
					var fgTrees:BGSprite = new BGSprite('stages/school/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if (!FunkySettings.lowGraphics)
				{
					var treeLeaves:BGSprite = new BGSprite('stages/school/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if (!FunkySettings.lowGraphics)
				{
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': // Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'pixel/fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'pixel/gameOver-pixel';
				GameOverSubstate.endSoundName = 'pixel/gameOverEnd-pixel';
				GameOverSubstate.characterName = 'pixel/bf-pixel-dead';

				var posX = 400;
				var posY = 200;
				if (!FunkySettings.lowGraphics)
				{
					var bg:BGSprite = new BGSprite('stages/school/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('stages/school/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('stages/school/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'warzone': // Week 7 - Ugh, Guns, Stress
				Pico = haxe.Json.parse(File.getContent(Paths.json('stress/pico')));
				Tankmen = haxe.Json.parse(File.getContent(Paths.json('stress/tank')));

				var sky:BGSprite = new BGSprite('stages/warzone/tankSky', -400, -400, 0, 0);
				add(sky);

				if (!FunkySettings.lowGraphics)
				{
					var clouds:BGSprite = new BGSprite('stages/warzone/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('stages/warzone/tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('stages/warzone/tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('stages/warzone/tankRuins', -200, 0, .35, .35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!FunkySettings.lowGraphics)
				{
					var smokeLeft:BGSprite = new BGSprite('stages/warzone/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('stages/warzone/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tower = new BGSprite('stages/warzone/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tower);
				}

				tankRolling = new BGSprite('stages/warzone/tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankRolling);

				tankmanRun = new FlxTypedGroup<Tankmen>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('stages/warzone/tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				tankSprites.add(new BGSprite('stages/warzone/tank0', -500, 650, 1.7, 1.5, ['fg']));

				if (!FunkySettings.lowGraphics)
					tankSprites.add(new BGSprite('stages/warzone/tank1', -300, 1250, 2, 0.2, ['fg']));

				tankSprites.add(new BGSprite('stages/warzone/tank2', 450, 940, 1.5, 1.5, ['foreground']));

				if (!FunkySettings.lowGraphics)
					tankSprites.add(new BGSprite('stages/warzone/tank4', 1300, 900, 1.5, 1.5, ['fg']));

				tankSprites.add(new BGSprite('stages/warzone/tank5', 1620, 700, 1.5, 1.5, ['fg']));

				if (!FunkySettings.lowGraphics)
					tankSprites.add(new BGSprite('stages/warzone/tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}

			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		add(backgroundGroup);

		if (curStage == 'philly')
			add(phillyCityLightsEvent);

		boyfriendGroup = new FlxSpriteGroup();
		dadGroup = new FlxSpriteGroup();
		gfGroup = new FlxSpriteGroup();

		add(gfGroup);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.mods(luaFile)))
		{
			luaFile = Paths.mods(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (curStage == 'philly')
		{
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('stages/philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(GF_X, GF_Y, gfVersion);
			gf.x += gf.positionArray[0];
			gf.y += gf.positionArray[1];
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(DAD_X, DAD_Y, SONG.player2);
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
		dadGroup.add(dad);

		boyfriend = new Boyfriend(BF_X, BF_Y, SONG.player1);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriendGroup.add(boyfriend);

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		switch (curStage)
		{
			case 'limo':
				resetFastCar();
				add(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				add(evilTrail);

			case 'warzone':
				add(tankSprites);
		}

		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
			if (isStoryMode)
			{
				camPos.x += 300;
				camPos.y -= 30;
				tweenCamIn();
			}
		}

		add(foregroundGroup);

		var file:String = Paths.json(songName + '/dialogue');
		if (FileSystem.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;

		Conductor.songPosition = -5000;

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		strumLine = new FlxSprite(FunkySettings.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (FunkySettings.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 16, 400, "", 36);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.borderQuality = 4;
		timeTxt.visible = FunkySettings.timeLeft;

		timeBarBG = new FlxSprite(timeTxt.x, timeTxt.y + (timeTxt.height / 4));

		var fillDirection:FlxBarFillDirection = LEFT_TO_RIGHT;

		if (FunkySettings.timeStyle == 'Time Left')
			fillDirection = RIGHT_TO_LEFT;

		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<BabyArrow>();
		add(strumLineNotes);

		sustainNotes = new FlxTypedGroup();
		add(sustainNotes);
		
		notes = new FlxTypedGroup<Note>();
		add(notes);

		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash();
		splash.x = 100;
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		cpuStrums = new FlxTypedGroup<BabyArrow>();
		playerStrums = new FlxTypedGroup<BabyArrow>();

		generateSong();

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.mods('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}

		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.mods('custom_notetypes/' + notetype + '.hx');
			if (FileSystem.exists(luaToLoad))
			{
				scriptArray.push(new FunkinScript(luaToLoad));
			}
		}

		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.mods('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
		}

		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.mods('custom_events/' + event + '.hx');
			if (FileSystem.exists(luaToLoad))
			{
				scriptArray.push(new FunkinScript(luaToLoad));
			}
		}
		#end

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		add(sickNumberGroup);
		add(sickGroup);

		healthBarBG = new AbsoluteSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !FunkySettings.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (FunkySettings.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !FunkySettings.hideHud;
		add(healthBar);
		healthBarBG.tracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !FunkySettings.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !FunkySettings.hideHud;
		add(iconP2);
		refillHealthbar();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.5;
		scoreTxt.visible = !FunkySettings.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.borderQuality = 2;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if (FunkySettings.downScroll)
		{
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		sustainNotes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		updateTime = true;

		var doPush:Bool = false;
		var luaFile:String = 'songs/${Paths.formatToSongPath(SONG.song)}';
		var dir:Array<String> = CoolUtil.coolDirectory(luaFile);

		#if LUA_ALLOWED
		for (i in dir)
		{
			if (i.endsWith('.lua'))
				doPush = true;
			else
				doPush = false;

			if (doPush)
				luaArray.push(new FunkinLua(i));
		}
		#end

		#if SCRIPT_ALLOWED
		for (i in dir)
			if (i.endsWith('.hx'))
				scriptArray.push(new FunkinScript(i));
		#end

		var doPush:Bool = false;
		var luaDir:String = 'scripts/';
		var dir:Array<String> = CoolUtil.coolDirectory(luaDir);

		#if LUA_ALLOWED
		for (i in dir)
		{
			if (i.endsWith('.lua'))
				doPush = true;
			else
				doPush = false;

			if (doPush)
				luaArray.push(new FunkinLua(i));
		}
		#end

		#if (LUA_ALLOWED && ACHIEVEMENTS_ALLOWED)
		var luaFiles:Array<String> = Achievements.getModAchievements().copy();
		if(luaFiles.length > 0){
			for(luaFile in luaFiles)
			{
				var lua = new FunkinLua(luaFile);
				luaArray.push(lua);
				achievementArray.push(lua);
			}
		}

		var achievementMetas = Achievements.getModAchievementMetas().copy();
		for (i in achievementMetas) {
			if(i.lua_code != null) {
				var lua = new FunkinLua(null, i.lua_code);
				luaArray.push(lua);
				achievementArray.push(lua);
			}
			if(i.week_nomiss != null) {
				achievementWeeks.push(i.week_nomiss);
			}
		}
		#end

		#if SCRIPT_ALLOWED
		for (i in dir)
			if (i.endsWith('.hx'))
				scriptArray.push(new FunkinScript(i));

		for (i in [dad, boyfriend, gf])
		{
			if (i.script != null)
				scriptArray.push(i.script);
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					FlxTween.tween(camHUD, {alpha: 0});
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							FlxTween.tween(camHUD, {alpha: 1});
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					FlxTween.tween(camHUD, {alpha: 0});
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							remove(blackScreen);
						}
					});

					FlxG.sound.play(Paths.sound('week5/Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						FlxTween.tween(camHUD, {alpha: 1});
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if (daSong == 'roses')
						FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro(daSong);

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}

		loader.percent += 10;
		applicationName = '$name - [${loader.text}]';

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, inputSystem);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, inputRelease);

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if (curStage == 'spooky')
			add(halloweenWhite);

		applicationName = name;

		calculateRating(true);

		callOnLuas('onCreatePost', []);
		super.create();
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function refillHealthbar()
	{
		if (!leftSide)
			healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		else
			healthBar.createFilledBar(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]),
				FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));

		if (!leftSide)
			healthBar.fillDirection = RIGHT_TO_LEFT;
		else
			healthBar.fillDirection = LEFT_TO_RIGHT;

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:String)
	{
		switch (type.toLowerCase())
		{
			case 'boyfriend' | 'bf':
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(BF_X, BF_Y, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
				}

			case 'gf' | 'girlfriend':
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(GF_X, GF_Y, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.visible = false;
				}

			case 'dad' | 'opponent' | 'cpu' | _:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(DAD_X, DAD_Y, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad);
					newDad.visible = false;
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var dialogueCount:Int = 0;

	// You don't have to add a song, just saying. You can just do "dialogueIntro(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.nextDialogueThing = startNextDialogue;
			doof.cameras = [camHUD];
			add(doof);
		}
		else
		{
			startCountdown();
			return;
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('stages/school/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);

				new FlxTimer().start(0.2, function(tmr)
				{
					camHUD.alpha -= 0.2;
					Main.FPS.alpha -= 0.2;
				}, 5);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('week6/Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);

										new FlxTimer().start(0.2, function(tmr)
										{
											camHUD.alpha += 0.2;
											Main.FPS.alpha += 0.2;
										}, 5);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro(week:String)
	{
		var tempDad:FlxSprite = new FlxSprite(dad.x, dad.y);
		tempDad.antialiasing = !FunkySettings.noAntialiasing;
		add(tempDad);

		// inCutscene = true;
		dadGroup.alpha = 0;
		FlxTween.tween(camHUD, {alpha: 0}, 0.7, {ease: FlxEase.quadInOut});

		if (week != "stress")
		{
			FlxG.sound.playMusic(Paths.music('warzone/DISTORTO'), 0, false);
			FlxG.sound.music.fadeIn(1, 0, 0.5);
		}

		moveCamera(true);

		var tankmanEnd:Void->Void = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			FlxTween.tween(camHUD, {alpha: 1}, 0.7, {ease: FlxEase.quadInOut});
			moveCamera(true);

			tempDad.kill();
			remove(tempDad);
			tempDad.destroy();

			dadGroup.alpha = 1;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();

			startCountdown();
		};

		switch (week)
		{
			case 'ugh':
				CoolUtil.precacheSound('warzone/wekk');
				tempDad.frames = Paths.getSparrowAtlas('cutscenes/warzone/ugh');
				tempDad.animation.addByPrefix('wellx3', 'TANK TALK 1 P1', 24, false);
				tempDad.animation.addByPrefix('boredTank', 'TANK TALK 1 P2', 24, false);
				tempDad.antialiasing = !FunkySettings.noAntialiasing;
				tempDad.animation.play('wellx3', true);

				new FlxTimer().start(0.01, function(tmr:FlxTimer)
				{
					var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('warzone/wekk'));
					sound.play();
					FlxG.sound.list.add(sound);
				});

				new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					camFollow.x += 400;
					camFollow.y += 50;

					new FlxTimer().start(1.5, function(tmr:FlxTimer)
					{
						boyfriend.playAnim('singUP', true);
						FlxG.sound.play(Paths.sound('warzone/beep'));
					});

					new FlxTimer().start(2.9, function(tmr:FlxTimer)
					{
						camFollow.x -= 400;
						camFollow.y -= 50;
						tempDad.animation.play('boredTank', true);
						FlxG.sound.play(Paths.sound('warzone/bored'));

						new FlxTimer().start(6.16, function(tmr:FlxTimer) tankmanEnd());
					});
				});

			case 'guns':
				tempDad = new FlxSprite(dad.x, dad.y);
				tempDad.frames = Paths.getSparrowAtlas('cutscenes/warzone/guns');
				tempDad.animation.addByPrefix('momClothes', 'TANK TALK ', 24, false);
				tempDad.antialiasing = !FunkySettings.noAntialiasing;
				add(tempDad);

				tempDad.animation.play('momClothes', true);
				boyfriend.animation.curAnim.finish();

				new FlxTimer().start(0.01, function(tmr:FlxTimer)
				{
					FlxG.sound.play(Paths.sound('warzone/momclothes'));
				});

				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});

				new FlxTimer().start(4.2, function(tmr:FlxTimer)
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

				new FlxTimer().start(11.6, function(tmr:FlxTimer)
				{
					tankmanEnd();

					gf.dance();
					gf.animation.finishCallback = null;
				});

			case 'stress':
				boyfriendGroup.alpha = 0;
				gfGroup.alpha = 0;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				tankSprites.forEach(function(spr:FlxSprite)
				{
					spr.y += 100;
				});

				tempDad.frames = Paths.getSparrowAtlas('cutscenes/warzone/stress');
				tempDad.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);

				var tankDad:FlxSprite = new FlxSprite(16, 312);
				tankDad.frames = Paths.getSparrowAtlas('cutscenes/warzone/stress2');
				tankDad.alpha = 0;
				tankDad.antialiasing = !FunkySettings.noAntialiasing;
				addBehindDad(tankDad);

				var gfDance:Character = new Character(gf.x - 107, gf.y + 140, "gf-tankmen");
				gfDance.animation.finishCallback = function(name) gfDance.dance();
				addBehindGF(gfDance);

				var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/warzone/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				gfCutscene.alpha = 0;
				gfCutscene.antialiasing = !FunkySettings.noAntialiasing;
				addBehindGF(gfCutscene);

				var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/warzone/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.antialiasing = !FunkySettings.noAntialiasing;
				picoCutscene.alpha = 0;

				var boyfried:Character = new Boyfriend(boyfriend.x + 5, boyfriend.y + 20);
				boyfried.animation.finishCallback = function(name) boyfried.dance();
				addBehindBF(boyfried);

				new FlxTimer().start(0.1, function(tmr)
				{
					var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('warzone/stressCutscene'));
					sound.play();
					FlxG.sound.list.add(sound);
				});

				tempDad.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 2.4;

					calledTimes++;
					if (calledTimes > 1)
					{
						tankSprites.forEach(function(spr)
						{
							spr.y -= 100;
						});
					}
				}

				new FlxTimer().start(15.2, function(tmr)
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);

					gfCutscene.animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') // Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfried.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};

							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				new FlxTimer().start(17.5, function(tmr)
				{
					zoomBack();
				});

				new FlxTimer().start(19.5, function(tmr)
				{
					tankDad.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankDad.animation.play('lookWhoItIs', true);
					tankDad.alpha = 1;
					tankDad.animation.finishCallback = function(name)
					{
						remove(tankDad);
						tankDad.kill();
						tankDad.destroy();
						tankmanEnd();
					};
					tempDad.visible = false;
				});

				new FlxTimer().start(20, function(tmr)
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				new FlxTimer().start(31.2, function(tmr)
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				new FlxTimer().start(32.2, function(tmr)
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	var perfectMode:Bool = false;
	var finishedCountdown:Bool;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);

		if (ret != FunkinLua.Function_Stop)
		{
			generateStaticArrows(0);
			generateStaticArrows(1);

			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...cpuStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, cpuStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, cpuStrums.members[i].y);
			}

			var fakeCrochet:Float = ((60 / SONG.bpm) * 1000);
			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= fakeCrochet * 5;
			setOnLuas('startedCountdown', true);

			var swagCounter:Int = 0;
			startTimer = new FlxTimer().start(fakeCrochet / 1000, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft % gfSpeed == 0)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % 2 == 0)
				{
					if (boyfriend.animation.curAnim != null
						&& !boyfriend.animation.curAnim.name.startsWith('sing')
						&& !boyfriend.specialAnim)
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.specialAnim)
					{
						dad.dance();
					}
				}
				else if (dad.danceIdle
					&& dad.animation.curAnim != null
					&& !dad.specialAnim
					&& !dad.curCharacter.startsWith('gf')
					&& !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('school', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
				introAssets.set('schoolEvil', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = !FunkySettings.noAntialiasing;
				var altSuffix:String = "";

				for (value in introAssets.keys())
				{
					if (value == curStage)
					{
						introAlts = introAssets.get(value);
						altSuffix = '-pixel';
					}
				}

				switch (curStage)
				{
					case 'school' | 'schoolEvil':
						antialias = false;

					case 'mall':
						if (!FunkySettings.lowGraphics)
							upperBoppers.dance(true);

						bottomBoppers.dance(true);
						santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();

						if (isPixelStage)
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

						ready.screenCenter();
						ready.antialiasing = antialias;
						add(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								ready.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.scrollFactor.set();

						if (isPixelStage)
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						set.screenCenter();
						set.antialiasing = antialias;
						add(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								set.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.scrollFactor.set();

						if (isPixelStage)
							go.setGraphicSize(Std.int(go.width * daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						go.antialiasing = antialias;
						add(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								go.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
					case 4:
						/*blackBy = new FlxSprite().makeGraphic(320, 120, FlxColor.BLACK);
						blackBy.screenCenter();
						blackBy.x -= FlxG.width;
						blackBy.alpha = 0.5;
						blackBy.y = FlxG.height - 600;
						blackBy.cameras = [camHUD];

						byText = new FlxText(0, 0, 425);
						byText.cameras = [camHUD];
						byText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						byText.borderSize *= 1.25;
						byText.borderQuality *= 1.25;
						byText.screenCenter();
						byText.x -= FlxG.width;
						byText.y = FlxG.height - 588.5;
						byText.text = CoolUtil.coolSongFormatter(SONG.song);
						byText.text += '\n By: ${SONG.by == null || SONG.by.length < 1 ? '?' : SONG.by}';
						
						blackBy.setGraphicSize(Std.int(byText.width + 20), Std.int(byText.height + 25));
						blackBy.updateHitbox();

						add(blackBy);
						add(byText);

						FlxTween.tween(blackBy, {x: 0}, 3, {ease: FlxEase.expoInOut});
						FlxTween.tween(byText, {x: 0}, 3, {ease: FlxEase.expoInOut});

						new FlxTimer().start(4.75, function(tmr:FlxTimer)
						{
							FlxTween.tween(blackBy, {x: -700}, 1.6, {ease: FlxEase.expoInOut, onComplete: function(twn:FlxTween)
							{
								remove(blackBy);
								blackBy.kill();
								blackBy.destroy();
							}});
							FlxTween.tween(byText, {x: -650}, 1.6, {ease: FlxEase.expoInOut, onComplete: function(twn:FlxTween)
							{
								remove(byText);
								byText.kill();
								byText.destroy();
							}});
						});*/
					
						finishedCountdown = true;
				}

				callOnLuas('onCountdownTick', [swagCounter]);

				if (generatedMusic)
				{
					notes.sort(FlxSort.byY, FunkySettings.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
					sustainNotes.sort(FlxSort.byY, FunkySettings.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}

				swagCounter += 1;
			}, 5);

			callOnLuas('onCountdownEnd', []);
		}
	}

	function startNextDialogue()
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();
		
		if (paused) 
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBarBG, {alpha: 1}, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);

		for (character in [gf, dad, boyfriend])
			if (character.animation.exists('hey-countdown'))
			{
				character.playAnim('hey-countdown', true);
				character.specialAnim = false;
				character.heyTimer = 1;
			}
	}

	var debugNum:Int = 0;
	var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	function generateSong():Void
	{
		var songData = SONG;
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(FlxG.sound.music);
		FlxG.sound.list.add(vocals);
		
		var stepCrochet:Float = Conductor.crochet / 4;

		curSongSpeed = SONG.speed;

		// NEW SHIT
		var noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = songNotes[3];

				if (!Note.typesToAvoidRandomize.contains(daNoteType))
				{
					if (GameplayOption.options.get('mirror_notes'))
					{
						switch (daNoteData)
						{
							case 0:
								daNoteData = 3;
							case 1:
								daNoteData = 2;
							case 2:
								daNoteData = 1;
							case 3:
								daNoteData = 0;
						}
					}
					else if (GameplayOption.options.get('randomize_notes'))
						daNoteData = FlxG.random.int(0, 3);

					if (GameplayOption.options.get('no_note_types'))
						daNoteType = null;
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3 && !leftSide)
				{
					gottaHitNote = !section.mustHitSection;
				}
				else if (songNotes[1] <= 3 && leftSide)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = daNoteType;
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(swagNote.sustainLength / stepCrochet);
				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (stepCrochet * susNote)
							+ (stepCrochet / FlxMath.roundDecimal(curSongSpeed, 2)), daNoteData,
							oldNote, true);
						sustainNote.noteType = daNoteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						sustainNote.mustPress = gottaHitNote;
					}
				}
				swagNote.mustPress = gottaHitNote;
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}

			daBeats += 1;
		}

		if (SONG.events != null && SONG.events.length > 0)
			for (event in SONG.events)
			{
				var eventArray:Array<Array<Dynamic>> = cast event[1];
				for (i in eventArray)
				{
					var eventNote:EventNote = new EventNote(i[0], event[0], i[1], i[2], i[3]);
					eventNote.visible = false;
					eventNote.strumTime -= eventNoteEarlyTrigger(eventNote);
					events.push(eventNote);
					eventPushed(eventNote);
				}
				// trace(eventNote.strumTime);
			}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		if (events.length > 1)
			events.sort(sortByTime);

		checkEventNote();
		unspawnNotes.sort(sortByShit);
		generatedMusic = true;

		var multiplier:Float = GameplayOption.options.get('scroll_speed');
		curSongSpeed *= multiplier;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var playerTWO:Int = player;
			
			if (FunkySettings.middleScroll)
			{
				if (player == 1)
					playerTWO = (leftSide ? 0 : 1);
				else
					playerTWO = (leftSide ? 1 : 0);
			}

			var babyArrow:BabyArrow = new BabyArrow(FunkySettings.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, playerTWO);

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);

				if (FunkySettings.middleScroll && leftSide)
				{
					babyArrow.x += 310;

					if (i > 1)
						babyArrow.x += FlxG.width / 2 + 25;
				}
			}
			else
			{
				if (FunkySettings.middleScroll && !leftSide)
				{
					babyArrow.x += 310;

					if (i > 1)
						babyArrow.x += FlxG.width / 2 + 25;
				}
				cpuStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
			}
			vocals.pause();

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if (phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end
		vocals.pause();

		super.onFocusLost();
	}

	function strumConfirm(isDad:Bool, note:Note):Void
	{
		var babyArrow:BabyArrow = null;

		if (isDad)
			babyArrow = (leftSide ? playerStrums : cpuStrums).members[note.noteData % 4];
		else
			babyArrow = (!leftSide ? playerStrums : cpuStrums).members[note.noteData % 4];

		babyArrow.playAnim('confirm', true);
		
		if (isDad)
			babyArrow.hold = !!!note.mustPress;
		else
			babyArrow.hold = cpuControlled;

		if (babyArrow.hold)
		{
			babyArrow.holdTimer = .018;
		}
	}

	function strumPress(isDad:Bool, id:Int):Void
	{
		var babyArrow:BabyArrow = null;

		if (isDad)
			babyArrow = (leftSide ? playerStrums : cpuStrums).members[id];
		else
			babyArrow = (!leftSide ? playerStrums : cpuStrums).members[id];

		babyArrow.holdTimer = 0;
		babyArrow.playAnim('pressed');
		babyArrow.hold = false;
	}

	function strumIdle(isDad:Bool, id:Int):Void
	{
		var babyArrow:BabyArrow = null;

		if (isDad)
			babyArrow = (leftSide ? playerStrums : cpuStrums).members[id];
		else
			babyArrow = (!leftSide ? playerStrums : cpuStrums).members[id];

		if (babyArrow.animation.curAnim.name == "confirm")
		{
			babyArrow.holdTimer = .02;
			babyArrow.hold = true;
		}
		else
		{
			babyArrow.holdTimer = 0;
			babyArrow.hold = false;
			babyArrow.playAnim('static');
		}
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (cpuControlled || practiceMode)
			usedPractice = true;

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'schoolEvil':
				if (!FunkySettings.lowGraphics && bgGhouls.animation.curAnim.finished)
				{
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
			case 'limo':
				if (!FunkySettings.lowGraphics)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130)
								{
									switch (i)
									{
										case 0 | 3:
											if (i == 0)
												FlxG.sound.play(Paths.sound('week4/dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4,
												['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
												['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4,
												['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4,
												0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000)
								limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length)
						{
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong && !endingSong && (leftSide ? dad : boyfriend).animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;

				if (boyfriendIdleTime >= 0.2)
					boyfriendIdled = true;
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		if (cpuControlled)
		{
			botplaySine += 180 * FlxG.elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		botplayTxt.visible = cpuControlled;

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if (ret != FunkinLua.Function_Stop)
			{
				paused = true;
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				persistentUpdate = false;
				persistentDraw = true;

				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.pause();
				}

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.justPressed.SEVEN && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			chartingMode = true;
			MusicBeatState.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var multX:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 7.78), 0, 1));
		var multY:Float = FlxMath.lerp(1, iconP1.scale.y, CoolUtil.boundTo(1 - (elapsed * 7.78), 0, 1));
		iconP1.scale.set(multX, multY);
		iconP1.updateHitbox();

		var multX:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 7.78), 0, 1));
		var multY:Float = FlxMath.lerp(1, iconP2.scale.y, CoolUtil.boundTo(1 - (elapsed * 7.78), 0, 1));
		iconP2.scale.set(multX, multY);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = (leftSide ? -593 : 0)
			+ healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, (leftSide ? -100 : 100), 100, 0) * 0.01) - iconOffset);
		iconP2.x = (leftSide ? -593 : 0)
			+ healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, (leftSide ? -100 : 100), 100, 0) * 0.01))
			- (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		var playerIcon:HealthIcon = (leftSide ? iconP2 : iconP1);
		var opponentIcon:HealthIcon = (!leftSide ? iconP2 : iconP1);

		if (!playerIcon.animated)
		{
			if (healthBar.percent < 20)
				playerIcon.animation.curAnim.curFrame = 1;
			else
				playerIcon.animation.curAnim.curFrame = 0;
		}
		else
		{
			if (healthBar.percent < 20)
				playerIcon.animation.play('dead');
			else
				playerIcon.animation.play('idle');
		}

		if (!opponentIcon.animated)
		{
			if (healthBar.percent > 80)
				opponentIcon.animation.curAnim.curFrame = 1;
			else
				opponentIcon.animation.curAnim.curFrame = 0;
		}
		else
		{
			if (healthBar.percent > 80)
				opponentIcon.animation.play('dead');
			else
				opponentIcon.animation.play('idle');
		}

		if (FlxG.keys.justPressed.EIGHT && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			
			if (!paused)
			{
				if (updateTime)
				{
					var curTime:Float = FlxG.sound.music.time;

					if (curTime < 0)
						curTime = 0;

					songPercent = (curTime / songLength);

					var secondsTotal:Float = (songLength - curTime) / 1000;
					var remainingTime:String = CoolUtil.coolTimeFormatter(secondsTotal);
					var totalTime:String = '%${Math.ffloor(songPercent * 100)}';

					var timeLeft:Float = songLength - curTime;
					if (FunkySettings.timeStyle == 'Time Left')
						totalTime = '%${Math.ffloor(timeLeft / songLength * 100)}';

					if (FunkySettings.timeStyle == 'Time Elapsed')
						remainingTime = CoolUtil.coolTimeFormatter(curTime / 1000);

					if (timeTxt.text != '$remainingTime ($totalTime)')
						timeTxt.text = '$remainingTime ($totalTime)';
					timeTxt.screenCenter(X);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			// trace("RESET = True");
		}

		doDeathCheck();

		if (generatedMusic && unspawnNotes[0] != null)
		{
			var time:Float = 1500;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
				
				(dunceNote.isSustainNote ? sustainNotes : notes).add(dunceNote);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(handleNotes);
			sustainNotes.forEachAlive(handleNotes);
			(!leftSide ? cpuStrums : playerStrums).forEach(function(strum:BabyArrow)
			{
				if (FunkySettings.middleScroll)
					strum.alpha = 0.4;

				strum.visible = !FunkySettings.hideOpponent;
			});
		}

		if (!inCutscene)
		{
			if (!cpuControlled)
			{
				gamepadInput(); // calls gamepad inputs if possible
				keyShit();
			}
			else if ((leftSide ? dad : boyfriend).holdTimer > Conductor.stepCrochet * 0.001 * (leftSide ? dad : boyfriend).singDuration
				&& (leftSide ? dad : boyfriend).animation.curAnim.name.startsWith('sing')
					&& !(leftSide ? dad : boyfriend).animation.curAnim.name.endsWith('miss'))
			{
				(leftSide ? dad : boyfriend).dance();
			}
		}

		checkEventNote();

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	var center:Float;

	public var isDead:Bool = false;

	function eventPushed(eventNote:EventNote)
	{
		try switch (eventNote.event)
		{
			case 'Change Character':
				addCharacterToList(eventNote.val2, eventNote.val1);
		} catch (e) {}

		callOnLuas("eventPushed", [eventNote.event, eventNote.val1, eventNote.val2, eventNote.val3], false);
		callOnScripts("eventPushed", [eventNote]);
	}

	function checkEventNote()
	{
		while (events.length > 0)
		{
			var leStrumTime:Float = events[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			var value1:String = '';
			if (events[0].val1 != null)
				value1 = events[0].val1;

			var value2:String = '';
			if (events[0].val2 != null)
				value2 = events[0].val2;

			var value3:String = '';
			if (events[0].val3 != null)
				value3 = events[0].val3;

			eventNoteHit(events[0].event, value1, value2, value3);
			events.shift();
		}
	}

	function doDeathCheck():Bool
	{
		if (health <= 0 && !practiceMode && !isDead && !cpuControlled)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				var character:Character = leftSide ? dad : boyfriend;
				openSubState(new GameOverSubstate(character.getScreenPosition().x, character.getScreenPosition().y, camFollowPos.x, camFollowPos.y, instance));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}

		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function getControl(key:String):Bool
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	function eventNoteEarlyTrigger(eventNote:EventNote):Int
	{
		var stop:Int = callOnLuas('eventEarlyTrigger', [eventNote.event]);
		if (stop != 0)
			return stop;

		switch (eventNote.event)
		{
			case 'Kill Henchmen':
				return 280;
		}

		return 0;
	}

	public function eventNoteHit(eventName:String, val1:String, val2:String, ?val3:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = Std.parseInt(val1);
				var time:Float = Std.parseFloat(val2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.heyTimer = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.heyTimer = time;
					}

					if (curStage == 'mall')
					{
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}

				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(val1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if (/*FunkySettings.camZooms && */ FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(val1);
					var hudZoom:Float = Std.parseFloat(val2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && !FunkySettings.lowGraphics)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				var char:Character = returnCharacterFromString(val2);
				char.playAnim(val1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(val1);
				var val2:Float = Std.parseFloat(val2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(val1) || !Math.isNaN(val2))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = returnCharacterFromString(val2);
				char.idleSuffix = val2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [val1, val2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:String = val1;

				switch (charType.toLowerCase())
				{
					case 'bf' | 'boyfriend':
						if (boyfriend.curCharacter != val2)
						{
							if (!boyfriendMap.exists(val2))
							{
								addCharacterToList(val2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(val2);
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 'gf' | 'girlfriend':
						if (gf.curCharacter != val2)
						{
							if (!gfMap.exists(val2))
							{
								addCharacterToList(val2, charType);
							}

							var isGfVisible:Bool = gf.visible;
							gf.visible = false;
							gf = gfMap.get(val2);
							gf.visible = isGfVisible;
						}

					case 'dad' | 'opponent' | 'cpu' | _:
						if (dad.curCharacter != val2)
						{
							if (!dadMap.exists(val2))
							{
								addCharacterToList(val2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(val2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf)
								{
									gf.visible = true;
								}
							}
							else
							{
								gf.visible = false;
							}
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}
				}

				refillHealthbar();

			case 'Change Scroll Speed':
				var newSpeed:Null<Float> = Std.parseFloat(val1);
				var tweenSpeed:Null<Float> = Std.parseFloat(val2);
				var ease = FunkinLua.getFlxEaseByString(val3);

				if (newSpeed == null || Math.isNaN(newSpeed))
					newSpeed = SONG.speed;
				if (tweenSpeed == null || Math.isNaN(tweenSpeed))
					tweenSpeed = 1;

				firstTimeSettingSpeed = false;
				FlxTween.tween(instance, {curSongSpeed: newSpeed}, tweenSpeed, {ease: ease});

			case 'BG Freaks Expression':
				if (bgGirls != null)
					bgGirls.swapDanceType();
		}

		callOnLuas('onEvent', [eventName, val1, val2, val3]);
	}

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] != null && camFollow.x != dad.getMidpoint().x + 150 && !SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}

		if (SONG.notes[id] != null && SONG.notes[id].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	public function moveCamera(isDad:Bool)
	{
		var songName:String = Paths.formatToSongPath(SONG.song);
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];

			if (songName == 'tutorial')
			{
				tweenCamIn();
			}
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (songName == 'tutorial')
			{
				FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
			}
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		CocoaTools.destroyMusic(FlxG.sound.music);
		vocals.volume = 0;
		vocals.stop();
		finishCallback();
	}

	var transitioning = false;

	function endSong():Void
	{
		for (i in [notes, sustainNotes])
		{
			for (l in i)
			{
				l.kill();
				l.destroy();
				i.remove(l, true);
			}
			i.kill();
		}

		timeBarBG.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement([
				'week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss', 'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad', 'ur_good', 'hype',
				'two_keys', 'toastie', 'debugger', 'ten_million',
			]);
			var customAchieves:String = checkForAchievement(achievementWeeks);

			if (achieve != null || customAchieves != null)
			{
				startAchievement(customAchieves != null ? customAchieves : achieve);
				return;
			}
		}
		#end

		callOnLuas('onEndSong', []);
		if (SONG.validScore && !chartingMode && !usedPractice)
		{
			#if !switch
			var percent:Float = accuracy;
			if (Math.isNaN(percent))
				percent = 0;

			Highscore.totalScore += songScore;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}

		if (chartingMode)
		{
			MusicBeatState.switchState(new ChartingState());
			return;
		}
		else if (isStoryMode)
		{
			campaignScore += songScore;
			campaignMisses += misses;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				campaignMisses = 0;
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				cancelFadeTween();
				MusicBeatState.switchState(new StoryMenuState(true));

				// if ()
				StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

				if (SONG.validScore && !usedPractice)
				{
					Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
				}

				CocoaSave.save.data.weekCompleted = StoryMenuState.weekCompleted;
				CocoaSave.save.flush();
				usedPractice = false;
				changedDifficulty = false;
				cpuControlled = false;
			}
			else
			{
				var difficulty:String = ' ' + CoolUtil.difficultyStuff[storyDifficulty];

				trace('LOADING NEXT SONG');
				trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

				var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");

				if (winterHorrorlandNext)
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('week5/Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				prevCamFollow = camFollow;
				prevCamFollowPos = camFollowPos;

				SONG = Song.loadFromJson(storyPlaylist[0], storyDifficulty);
				FlxG.sound.music.stop();

				if (winterHorrorlandNext)
				{
					new FlxTimer().start(1.5, function(tmr:FlxTimer)
					{
						cancelFadeTween();
						MusicBeatState.switchState(new PlayState());
					});
				}
				else
				{
					cancelFadeTween();
					MusicBeatState.switchState(new PlayState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			cancelFadeTween();
			MusicBeatState.switchState(new FreeplayState(true));
			usedPractice = false;
			changedDifficulty = false;
			cpuControlled = false;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
		}
	}
	#end

	function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
	}

	function popUpScore(note:Note):Void
	{
		if (combo == 0)
		{
			sickNumberGroup.forEach(function(spr:FlxSprite)
			{
				FlxTween.tween(spr, {alpha: 0}, .09, {onComplete: function(tween)
				{
					spr.kill();
					sickNumberGroup.remove(spr, true);
					spr.destroy();
				}});
			});

			sickGroup.forEach(function(spr:FlxSprite)
			{
				FlxTween.tween(spr, {alpha: 0}, .09, {onComplete: function(tween)
				{
					spr.kill();
					sickGroup.remove(spr, true);
					spr.destroy();
				}});
			});
		}

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		var wife:Float = NerfedEtterna.calculate(noteDiff, Conductor.safeZoneOffset / 130);
		var coolText:FlxObject = new FlxObject();
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = new Conductor().judge(noteDiff);

		switch (daRating)
		{
			case 'shit':
				score = 50;
				health -= 0.06;
				shits++;
			case 'bad':
				score = 100;
				bads++;
			case 'good':
				score = 200;
				goods++;
			case 'sick':
				sicks++;
				splashNote(note);
		}

		if (FlxG.random.bool(1) && NerfedEtterna.nerf(wife) <= 0.25)
			trace('YOU SUCK!');

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			totalNotesMissed++;
			totalNotesHit += NerfedEtterna.nerf(wife);
		}

		calculateRating(note.isSustainNote && !cpuControlled);

		var judgementPath:String = 'judgements/${daRating}';
		var numPath:String = "numbers/num";

		if (isPixelStage)
		{
			judgementPath += '-pixel';
		}

		rating.loadGraphic(Paths.image(judgementPath));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 600;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.x += FunkySettings.comboOffsets[0];
		rating.y -= FunkySettings.comboOffsets[1];

		var comboimage:String = 'judgements/combo';

		if (isPixelStage)
			comboimage += '-pixel';

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.loadGraphic(Paths.image(comboimage));
		comboSpr.screenCenter();
		comboSpr.x = rating.x;
		comboSpr.y = rating.y + 75;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x -= FlxG.random.int(0, 10);

		if (!isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = !FunkySettings.noAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = !FunkySettings.noAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		sickGroup.add(rating);
		if (combo > 9)
			sickGroup.add(comboSpr);

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		if (combo >= 100)
			seperatedScore.push(Math.floor(combo / 100) % 10);
		if (combo >= 10)
			seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('$numPath${Std.int(i)}${isPixelStage ? '-pixel' : ''}'));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * (daLoop + 2.6)) - 90;
			numScore.y += 100;
			if (combo < 10)
				numScore.y = rating.y + 85;

			if (!isPixelStage)
			{
				numScore.antialiasing = !FunkySettings.noAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !FunkySettings.hideHud;

			//if (combo >= 10 || combo == 0)
			sickNumberGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					sickNumberGroup.remove(numScore, true);
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				sickGroup.remove(rating, true);
				sickGroup.remove(comboSpr, true);
				coolText.destroy();
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	function getKey(key:FlxKey):Null<Int>
	{
		if (key != NONE)
			for (i in 0...keysArray.length)
				for (j in 0...keysArray[i].length)
					if (key == keysArray[i][j])
						return i;

		return -1;
	}

	// epic rewritten inputs
	function inputSystem(event:KeyboardEvent)
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKey(eventKey);

		if (!inCutscene && !paused && startedCountdown
			&& key >= 0
			&& FlxG.keys.enabled
			&& !keysPressed[key]
			&& (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			if (generatedMusic)
			{
				var hitNotes:Array<Note> = [];
				var dataNotes:Array<Note> = [];
				var stackedNotes:Array<Note> = [];

				notes.forEachAlive(function(note:Note)
				{
					if (note.mustPress && note.canBeHit && !note.wasGoodHit)
						hitNotes.push(note);
				});

				hitNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				for (note in hitNotes)
					if (!note.isSustainNote && note.noteData == key)
						dataNotes.push(note);

				if (dataNotes.length > 0 && !cpuControlled)
				{
					var coolNote:Note = null;

					for (hitNote in dataNotes)
					{
						coolNote = hitNote;
						break;
					}

					if (dataNotes.length > 1)
					{
						for (i in 0...dataNotes.length)
						{
							if (i == 0)
								continue;

							var stackedNote:Note = dataNotes[i];

							if (!stackedNote.isSustainNote
								&& ((stackedNote.strumTime - coolNote.strumTime) < 2)
								&& stackedNote.noteData == key)
							{
								#if debug
								FlxG.log.warn('The notes are stacked up! Destroying note!');
								#end
								stackedNotes.push(stackedNote);
								break;
							}
						}
					}

					goodNoteHit(coolNote);
				}
				else
				{
					if (!FunkySettings.ghostTapping)
						noteMissKey(key);

					strumPress(false, key);
				}

				keysPressed[key] = true;
				keysAchievement[key] = true;

				for (note in stackedNotes)
				{
					if (note != null)
					{
						note.visible = false;
						note.active = false;
						note.kill();
						(note.isSustainNote ? sustainNotes : notes).remove(note, true);
						note.destroy();
					}
				}

				setOnLuas('key', key);
				callOnLuas('onKeyPress', []);
			}
		}
	}

	function inputRelease(event:KeyboardEvent)
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKey(eventKey);

		if (!perfectMode && startedCountdown && !inCutscene && key >= 0 && FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			keysPressed[key] = false;
			strumIdle(false, key);
			setOnLuas('key', key);
			callOnLuas('onKeyRelease', []);
		}
	}

	function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		var char:Character = (leftSide ? dad : boyfriend);

		// FlxG.watch.addQuick('asdfa', upP);
		if (generatedMusic)
		{
			var group = sustainNotes;
			group.forEachAlive(function(daNote:Note)
			{
				if (controlHoldArray[daNote.noteData]
					&& daNote.isSustainNote
					&& daNote.canBeHit
					&& daNote.mustPress
					&& (daNote.prevNote.wasGoodHit || !daNote.wasGoodHit))
				{
					goodNoteHit(daNote);
				}
			});

			#if ACHIEVEMENTS_ALLOWED
			var achieve:String = checkForAchievement(['oversinging']);
			if (achieve != null)
			{
				startAchievement(achieve);
			}
			#end

			if (char.holdTimer > Conductor.stepCrochet * 0.001 * char.singDuration
				&& char.animation.curAnim.name.startsWith('sing')
				&& !char.animation.curAnim.name.endsWith('miss')
				&& !controlHoldArray.contains(true))
			{
				char.dance();
			}
		}

		var up = controls.NOTE_UP_P;
		var right = controls.NOTE_RIGHT_P;
		var down = controls.NOTE_DOWN_P;
		var left = controls.NOTE_LEFT_P;
		var controlArray:Array<Bool> = [left, down, up, right];

		/*(leftSide ? cpuStrums : playerStrums).forEach(function(strum:BabyArrow)
		{
			strum.ID %= 4;

			if (strum.animation.curAnim.name == "confirm")
			{
				if (strum.animation.curAnim.finished
					&& !controlHoldArray[strum.ID]
					&& !controlArray[strum.ID])
				{
					strum.playAnim("static");
				}
			}
			else
				strum.playAnim("static");
		});*/
	}

	function gamepadInput()
	{
		/*
			straight up nabbed from Forever Engine Underscore (haha self promotion moment)
			won't do a lua call here because this happens along with the `keyShit()` function so it isn't needed
			-gabi(BeastlyGhost)
		*/

		if (controls.gamepadsAdded.length > 0)
		{
			var gamepad:FlxGamepad = FlxG.gamepads.getByID(controls.gamepadsAdded[0]);
			var directions:Array<Control> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];
			for (i in 0...directions.length)
			{
				var bind:Array<Int> = controls.getInputsFor(directions[i], Gamepad(gamepad.id));
				var gamepadEventPress = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]);
				var gamepadEventRelease = new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]);
				if (gamepad.anyJustPressed(bind))
					inputSystem(gamepadEventPress);
				if (gamepad.anyJustReleased(bind))
					inputRelease(gamepadEventRelease);
			}
		}
	}

	function updateScore(miss:Bool)
	{
		var text:String = 'Score: $songScore | Misses: $misses [$ratingFC] | Accuracy: ${CoolUtil.coolTruncater(accuracy * 100, FunkySettings.decimals)}% - $ratingName';
		if (scoreTxt.text != text)
			scoreTxt.text = text;

		if (!miss && FunkySettings.scoreTween)
		{
			if (scoreTxtTween != null)
				scoreTxtTween.cancel();

			scoreTxt.scale.x = 1.12;
			scoreTxt.scale.y = 1.12;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) scoreTxtTween = null
			});
		}

		callOnLuas('onUpdateScore', [miss]);
	}

	function handleNotes(daNote:Note):Void
	{
		var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

		var strumY:Float = 0;
		var strumX:Float = 0;

		var strum:BabyArrow = (!leftSide ? cpuStrums : playerStrums).members[daNote.noteData % 4];
		if (daNote.mustPress)
			strum = (leftSide ? cpuStrums : playerStrums).members[daNote.noteData % 4];

		strumY = strum.y;
		strumX = strum.x;
		
		strumX += daNote.offsetX;

		if (daNote.isSustainNote)
			strumX -= 4.5;
		
		// trace(strumX);

		if (daNote.copyX)
			daNote.x = strumX;
		if (daNote.copyAlpha)
			daNote.alpha = daNote.multAlpha;
		if (daNote.copyVisible)
			daNote.visible = strum.visible;
		if (daNote.copyAngle)
			daNote.angle = strum.angle;

		center = strumY + Note.swagWidth / 2;

		if (!daNote.mustPress && daNote.wasGoodHit && !daNote.ignoreNote)
			cpuNoteHit(daNote);

		if (FunkySettings.downScroll)
		{
			daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * curSongSpeed);

			if (daNote.isSustainNote)
			{
				// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
				if (daNote.animation.curAnim.name.endsWith('end'))
				{
					daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * FlxMath.roundDecimal(curSongSpeed, 2) + (46 * (FlxMath.roundDecimal(curSongSpeed, 2) - 1));
					daNote.y -= 46 * (1 - (fakeCrochet / 600)) * FlxMath.roundDecimal(curSongSpeed, 2);
					if (isPixelStage)
					{
						daNote.y += 8;
					}
					else
					{
						daNote.y -= 19;
					}
				}

				daNote.y += (Note.swagWidth / 2) - (60.5 * (FlxMath.roundDecimal(curSongSpeed, 2) - 1));
				daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (FlxMath.roundDecimal(curSongSpeed, 2) - 1);
			}
		}
		else
		{
			daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * curSongSpeed);
		}

		var control:Array<Array<Bool>> = [
			[controls.NOTE_LEFT, controls.NOTE_LEFT_P],
			[controls.NOTE_DOWN, controls.NOTE_DOWN_P],
			[controls.NOTE_UP, controls.NOTE_UP_P],
			[controls.NOTE_RIGHT, controls.NOTE_RIGHT_P],
		];

		if (daNote.isSustainNote)
		{
			if (((control[daNote.noteData % 4].contains(true) || !daNote.mustPress)
				|| daNote.wasGoodHit
				|| cpuControlled
				|| (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
			{
				if (FunkySettings.downScroll)
				{
					if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = (daNote.frameHeight  - swagRect.height) + if (daNote.animation.curAnim.name.endsWith('end')) (Conductor.stepCrochet / 26) else 0;
						
						daNote.clipRect = swagRect;
					}
				}
				else
				{
					if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / (daNote.scale.y ) + if (daNote.animation.curAnim.name.endsWith('end')) -(Conductor.stepCrochet / 26) else 0;
						swagRect.height -= swagRect.y;
						
						daNote.clipRect = swagRect;
					}
				}
			}
		}

		if (cpuControlled
			&& daNote.strumTime - FlxG.random.int(5, 40) <= Conductor.songPosition 
			&& daNote.mustPress
			&& !daNote.isSustainNote
			&& !daNote.ignoreNote)
			goodNoteHit(daNote);
		else if (cpuControlled && daNote.canBeHit && daNote.isSustainNote && daNote.mustPress && daNote.isSustainNote && !daNote.ignoreNote)
			goodNoteHit(daNote);
		var doKill:Bool = Conductor.songPosition > daNote.strumTime + noteKill;

		if (doKill)
		{
			if (daNote.mustPress)
			{
				if (daNote.tooLate || !daNote.wasGoodHit)
				{
					if (!endingSong)
						noteMiss(daNote);
				}
			}
		}
	}

	function heyNoteHit(note:Note):Void
	{
		var character:Character = (leftSide ? boyfriend : dad);

		if (note.mustPress)
			character = (leftSide ? dad : boyfriend);

		if (note.noteType != 'Hey!')
			return;

		if (character.animation.exists('hey'))
			character.playAnim('hey', true);

		character.specialAnim = false;
		character.heyTimer = 0.6;

		if (SONG.needsVoices)
			vocals.volume = 1;

		strumConfirm(!note.mustPress, note);

		var group:FlxTypedGroup<Note> = (note.isSustainNote ? sustainNotes : notes);

		if (!note.isSustainNote)
		{
			note.kill();
			group.remove(note, true);
			note.destroy();
		}

		callOnLuas('heyNoteHit', [group.members.indexOf(note), note.noteData % 4], false);
		callOnScripts('heyNoteHit', [note]);
	}

	function cpuNoteHit(daNote:Note):Void
	{
		if (SONG.song != 'Tutorial')
			camZooming = true;

		if (daNote.ignoreNote)
		{
			return;
		}

		switch (daNote.noteType)
		{
			case 'Hey!':
				heyNoteHit(daNote);
				return;
		}

		daNote.ignoreNote = true;

		var character:Character = (!leftSide ? dad : boyfriend);

		if (daNote.noteType == 'GF Note')
			character = gf;

		var altAnim:String = "";
		character.heyTimer = 0;

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.noteType == 'Alt Animation')
			{
				altAnim = '-alt';
			}
		}

		if (daNote.noteType != 'No Animation')
		{
			character.playAnim('${missAnims[daNote.noteData % 4]}$altAnim', true);
			character.specialAnim = altAnim == '-alt';
			character.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.18;
		if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end'))
		{
			time += 0.18;
		}

		strumConfirm(true, daNote);

		var group:FlxTypedGroup<Note> = (daNote.isSustainNote ? sustainNotes : notes);

		callOnLuas('opponentNoteHit', [
			group.members.indexOf(daNote),
			Math.abs(daNote.noteData),
			daNote.noteType,
			daNote.isSustainNote
		], false);
		callOnScripts('opponentNoteHit', [daNote]);

		if (!daNote.isSustainNote)
		{
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	var oldAnim:String;
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			var character:Character = (leftSide ? dad : boyfriend);
			if (note.noteType == 'GF Note')
				character = gf;

			if (note.ignoreNote && cpuControlled)
				return;

			switch (note.noteType)
			{
				case 'Hurt Note': // Hurt note
					if (!character.stunned)
					{
						health -= 0.3;
						misses++;
						totalNotesMissed++;

						if (!endingSong)
						{
							calculateRating(true);

							if (character.animation.exists('hurt'))
							{
								character.playAnim('hurt', true);
								character.specialAnim = true;
							}

							splashNote(note);
							strumConfirm(false, note);
							note.kill();
							notes.remove(note, true);
							note.destroy();
						}
					}

					return;

				case 'Hey!':
					heyNoteHit(note);
					return;
			}

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
				if (combo > 9999)
					combo = 9999;
			}

			var daAlt = '';
			if (note.altAnim)
				daAlt = '-alt';

			if (!note.noAnimation)
			{
				if (daAlt == '')
				{
					if (character.animation.exists('${missAnims[note.noteData % 4]}2'))
					{
						var random:Bool = FlxG.random.bool();
						if (random && !note.isSustainNote)
						{
							oldAnim = '${missAnims[note.noteData % 4]}2';
							character.playAnim('${missAnims[note.noteData % 4]}2', true);
						}
						else
						{
							if (!note.isSustainNote)
							{
								character.playAnim('${missAnims[note.noteData % 4]}', true);
								oldAnim = '${missAnims[note.noteData % 4]}';
							}
							else
							{
								if (!oldAnim.contains('${missAnims[note.noteData % 4]}'))
								{
									oldAnim = '${missAnims[note.noteData % 4]}';
									//oldAnim += random ? '2' : '';
								}
								character.playAnim(oldAnim, true);
							}
						}
					}
					else
						character.playAnim('${missAnims[note.noteData % 4]}', true);
				}
				else
				{
					character.playAnim('${missAnims[note.noteData % 4]}$daAlt', true);
					character.specialAnim = true;
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}

				strumConfirm(false, note);
			}
			else
				strumConfirm(false, note);

			health += note.hitHealth * gainMultiplier;

			note.wasGoodHit = true;
			vocals.volume = 1;
			character.holdTimer = 0;

			var group:FlxTypedGroup<Note> = (note.isSustainNote ? sustainNotes : notes);

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [group.members.indexOf(note), leData, leType, isSus], false);
			callOnScripts('goodNoteHit', [note]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function noteMiss(note:Note):Void
	{
		var altAnimMiss:String = '';
		var char:Character = boyfriend;

		if (leftSide)
			char = dad;

		if (note.ignoreNote)
			return;

		var group:FlxTypedGroup<Note> = (note.isSustainNote ? sustainNotes : notes);

		switch (note.noteType)
		{
			case 'Must Press Note':
				(leftSide ? dad : boyfriend).playAnim('hurt', true);
		}

		note.kill();
		group.remove(note, true);
		note.destroy();

		if (!char.stunned)
		{
			if (instakillEnabled)
				health = 0;

			health -= note.missHealth * lossMultiplier;

			if (combo > 9 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}

			combo = 0;

			vocals.volume = 0;

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			songScore -= 10;

			misses++;
			totalNotesMissed++;

			calculateRating(true);

			if (note.noteType == 'Alt Animation')
				altAnimMiss = '-alt-';
			else if (note.noteType == 'Hey!')
				altAnimMiss = '-hey-';

			var anim:String = missAnims[note.noteData] + altAnimMiss + 'miss';

			if (char.animation.exists(anim))
				char.playAnim(anim, true);
			else
			{
				if (altAnimMiss != '')
					altAnimMiss = '';

				anim = missAnims[note.noteData] + altAnimMiss + 'miss';

				if (char.animation.exists(anim))
					char.playAnim(anim, true);
			}
		}

		callOnLuas('noteMiss', [group.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote], false);
		callOnScripts('noteMiss', [note]);
	}

	function noteMissKey(direction:Null<Int>)
	{
		var char:Character = boyfriend;

		if (leftSide)
			char = dad;

		if (!char.stunned)
		{
			health -= 0.06 * lossMultiplier;

			if (instakillEnabled)
				health = 0;

			if (combo > 9 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}

			combo = 0;

			vocals.volume = 0;

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			songScore -= 10;

			misses++;
			totalNotesMissed++;

			calculateRating(true);

			if (char.animation.exists(missAnims[direction] + 'miss'))
				char.playAnim(missAnims[direction] + 'miss', true);
		}

		callOnLuas('noteMissPress', [direction]);
	}

	function splashNote(note:Note)
	{
		if (!note.isSustainNote)
		{
			var daNoteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			var y:FlxTypedGroup<BabyArrow> = (leftSide ? cpuStrums : playerStrums);
			if (!note.mustPress)
				y = (!leftSide ? cpuStrums : playerStrums);
			daNoteSplash.babyArrow = y.members[note.noteData % 4];
			//trace(daNoteSplash.meta.animations.get("hurtie").offsets);
			daNoteSplash.spawnSplashNote(note);
			grpNoteSplashes.add(daNoteSplash);

			callOnLuas('onSplashNote', [], false);
			callOnScripts('onSplashNote', [note]);
			setOnLuas('splashX', daNoteSplash.x);
			setOnLuas('splashY', daNoteSplash.y);
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		// trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('week4/carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
			gf.specialAnim = true;
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.danced = false; // Sets head to the correct position once the animation ends
		gf.playAnim('hairFall');
		gf.specialAnim = true;
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));

		if (!FunkySettings.lowGraphics)
			halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}
		if (gf.animOffsets.exists('scared'))
		{
			gf.playAnim('scared', true);
		}

		FlxG.camera.zoom += 0.03;
		camHUD.zoom += 0.03;

		if (!camZooming)
		{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
			FlxTween.tween(camHUD, {zoom: 1}, 0.5);
		}

		halloweenWhite.alpha = 0.4;
		FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
		FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
	}

	function killHenchmen():Void
	{
		if (!FunkySettings.lowGraphics && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				CocoaSave.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				else
				{
					CocoaSave.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, inputSystem);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, inputRelease);

		CocoaTools.destroyMusic(vocals);
		CocoaTools.destroyMusic(FlxG.sound.music);

		super.destroy();
	}

	public function cancelFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove)
		{
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		switch (curStage)
		{
			case 'warzone':
				if (Paths.formatToSongPath(SONG.song) == 'stress')
				{
					for (i in 0...Pico.right.length)
					{
						if (curStep == Pico.right[i] && gf != null)
							gf.playAnim('shoot' + FlxG.random.int(1, 2), true);
					}

					for (i in 0...Pico.left.length)
					{
						if (curStep == Pico.left[i] && gf != null)
							gf.playAnim('shoot' + FlxG.random.int(3, 4), true);
					}

					for (i in 0...Tankmen.left.length)
					{
						if (curStep == Tankmen.left[i] && FlxG.random.bool(25))
						{
							var tankmanRunner:Tankmen = new Tankmen();
							tankmanRunner.resetShit(FlxG.random.int(630, 730) * -1, 255, true, 1, 1.5);
							tankmanRun.add(tankmanRunner);
						}
					}

					for (i in 0...Tankmen.right.length)
					{
						if (curStep == Tankmen.right[i] && FlxG.random.bool(25))
						{
							var tankmanRunner:Tankmen = new Tankmen();
							tankmanRunner.resetShit(FlxG.random.int(1500, 1700) * 1, 275, false, 1, 1.5);
							tankmanRun.add(tankmanRunner);
						}
					}
				}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				// FlxG.log.add('CHANGED BPM!');
				@:privateAccess
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.04;
		}

		notes.members.sort(sortByShit);
		sustainNotes.members.sort(sortByShit);

		var beat:Float = Conductor.bpm / 100;
		if (beat >= 1.85)
			beat = Math.round(beat);
		else
		{
			beat = Std.int(beat);
			if (beat < 1)
				beat = 1;
		}

		if (curBeat % beat == 0)
		{
			iconP1.scale.set(1.32, 1.32);
			iconP2.scale.set(1.32, 1.32);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		if (curBeat % gfSpeed == 0 && !gf.stunned)
		{
			gf.dance();
		}

		var opponent:Character = (leftSide ? boyfriend : dad);
		var boyfriend:Character = (!leftSide ? boyfriend : dad);

		if (curBeat % 2 == 0)
		{
			if (!opponent.danceIdle
				&& !opponent.curCharacter.startsWith('gf')
				&& !opponent.specialAnim
				&& !opponent.animation.curAnim.name.startsWith('sing'))
				opponent.dance();

			if (!boyfriend.specialAnim
				&& !boyfriend.curCharacter.startsWith('gf')
				&& !boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.danceIdle)
				boyfriend.dance();
		}

		if (opponent.danceIdle
			&& !opponent.animation.curAnim.name.startsWith('sing')
			&& !opponent.specialAnim)
			opponent.dance();

		if (boyfriend.danceIdle
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.specialAnim)
			boyfriend.dance();

		switch (curStage)
		{
			case 'school':
				if (!FunkySettings.lowGraphics)
				{
					bgGirls.dance();
				}

			case 'mall':
				if (!FunkySettings.lowGraphics)
				{
					upperBoppers.dance(true);
				}

				if (heyTimer <= 0)
					bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if (!FunkySettings.lowGraphics)
				{
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}

			case 'warzone':
				if (curBeat % 2 == 0)
				{
					tankSprites.forEach(function(spr)
					{
						spr.dance();
					});
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(6) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	public function addBehindGF(Object:FlxBasic)
	{
		insert(members.indexOf(gfGroup), Object);
	}

	public function addBehindBF(Object:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), Object);
	}

	public function addBehindDad(Object:FlxBasic)
	{
		insert(members.indexOf(dadGroup), Object);
	}

	public function callOnScripts(event:String, args:Array<Dynamic>):Void
	{
		#if !SCRIPT_ALLOWED
		return;
		#end

		return for (i in scriptArray)
			i.call(event, args);
	}

	public function setOnScripts(key:String, value:Dynamic):Void
	{
		#if !SCRIPT_ALLOWED
		return;
		#end
		
		return for (i in scriptArray)
			i.set(key, value);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ?callOnScript:Bool = true):Int
	{
		if (callOnScript)
			callOnScripts(event, args);

		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			//var callVal:Dynamic = luaArray[i].hscript.call(event, args);
			if (ret != FunkinLua.Function_Continue)
			{
				returnVal = ret;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		setOnScripts(variable, arg);

		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		return null;
	}

	public function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}

			i++;
			len = copiedArray.length;
		}

		return copiedArray;
	}

	public var ratingFC:String = 'N/A';
	public var ratingName:String = '?';
	public function calculateRating(?miss:Bool = false)
	{
		if (callOnLuas('onCalculateRating', []) == FunkinLua.Function_Stop)
			return;

		if (cpuControlled)
			return;

		accuracy = Math.min(1, Math.max(0, totalNotesHit / totalNotesMissed));

		if (accuracy > 1)
			accuracy = 1;
		else if (Math.isNaN(accuracy))
			accuracy = 0;
		else if (accuracy < 0)
			accuracy = 0;

		if (totalNotesMissed == 0)
			ratingName = '?';
		else
			ratingName = ratingMap.get(Math.floor(accuracy * 100));

		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
		setOnLuas('accuracy', accuracy);

		if (sicks > 0)
			ratingFC = 'SFC';
		if (goods > 0)
			ratingFC = 'GFC';
		if (bads > 0 || shits > 0)
			ratingFC = 'FC';
		if (misses > 0 && misses < 10)
			ratingFC = 'SDCB';
		else if (misses > 9)
			ratingFC = 'Clear';

		updateScore(miss);
	}

	public function returnCharacterFromString(char:String)
	{
		return switch (char.toLowerCase())
		{
			case 'bf' | 'boyfriend': boyfriend;
			case 'gf' | 'girlfriend': gf;
			case 'dad' | 'opponent' | 'cpu' | _: dad;
		}
	}

	function checkForAchievement(idArray:Array<String>):String
	{
		#if ACHIEVEMENTS_ALLOWED
		if (chartingMode || leftSide)
			return null;

		for (i in idArray)
		{
			if (!Achievements.isUnlocked(i))
			{
				if (!Achievements.exists(i))
					return null;
				
				var shouldUnlock:Bool = false;

				if (i.contains(WeekData.getWeekFileName())
					&& i.endsWith('nomiss'))
				{
					if (isStoryMode
						&& misses < 1
						&& campaignMisses < 1
						&& misses + campaignMisses < 1
						&& CoolUtil.difficultyString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1
						&& !changedDifficulty
						&& !usedPractice)
						shouldUnlock = true;
				}

				switch (i)
				{
					case 'ur_bad':
						if (accuracy < .2 && !usedPractice)
							shouldUnlock = true;

					case 'ur_good':
						if (misses < 1 && accuracy >= 1 && !usedPractice)
							shouldUnlock = true;
					
					case 'ten_million':
						if (Highscore.totalScore >= 10000000 && !usedPractice)
							shouldUnlock = true;

					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100)
							shouldUnlock = true;

					case 'oversinging':
						if (boyfriend.holdTimer >= 10 && !usedPractice)
							shouldUnlock = true;

					case 'hype':
						if (!boyfriendIdled && !usedPractice)
							shouldUnlock = true;

					case 'two_keys':
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;

							for (j in 0...keysAchievement.length)
								if (keysAchievement[j])
									howManyPresses++;

							shouldUnlock = howManyPresses <= 2;
						}
					case 'toastie':
						if (FunkySettings.lowGraphics && FunkySettings.noAntialiasing)
							shouldUnlock = true;

					case 'debugger':
						if (Paths.formatToSongPath(SONG.song).toLowerCase() == 'test' && !usedPractice)
							shouldUnlock = true;
				}

				if (shouldUnlock)
				{
					var stat:AchievementStats = Achievements.createStat(CoolUtil.coolSongFormatter(SONG.song), Date.now(), storyDifficulty, CoolUtil.coolTruncater(accuracy * 100, 2),
						misses);

					Achievements.unlockAchievement(i, stat);
					return i;
				}
			}
		}

		return null;
		#else
		return null;
		#end
	}

	var curLight:Int = 0;
	var curLightEvent:Int = 0;

	public var tankX = 400;
	public var tankAngle:Float = FlxG.random.int(-90, 45);
	public var tankSpeed:Float = FlxG.random.float(5, 7);

	function moveTank()
	{
		tankAngle += FlxG.elapsed * tankSpeed;
		tankRolling.angle = tankAngle - 90 + 15;
		tankRolling.x = tankX + 1500 * FlxMath.fastCos(FlxAngle.asRadians(tankAngle + 180));
		tankRolling.y = 1300 + 1100 * FlxMath.fastSin(FlxAngle.asRadians(tankAngle + 180));
	}

	function set_curSongSpeed(value:Float):Float
	{
		var offset:Float = value / curSongSpeed;

		if (!firstTimeSettingSpeed || generatedMusic)
		{
			for (note in unspawnNotes)
				if (note.isSustainNote)
					note.resize(offset);
			for (note in sustainNotes)
				note.resize(offset);
		}

		noteKill = 350 / value;
		return curSongSpeed = value;
	}

	static function set_applicationName(value:String):String
	{
		return applicationName = value;
	}
}