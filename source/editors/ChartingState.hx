package editors;

import openfl.geom.ColorTransform;
import flixel.FlxBasic;
#if desktop
import Discord.DiscordClient;
#end
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.*;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;
import openfl.net.FileReference;
import lime.media.AudioBuffer;
import haxe.io.Bytes;
import flash.geom.Rectangle;
import sys.io.File;
import sys.FileSystem;
import yaml.Yaml;
import yaml.Parser;

using StringTools;

class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = [
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'Must Press Note',
		'GF Note',
		'No Animation',
	];

	var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();

	var  me:FlxUIButton;

	var undos:Array<SwagSong> = [];
	var undoIndex:Int;

	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: 0 = Only Boyfriend, 1 = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for .6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Blammed Lights',
			"Value 1: 0 = Turn off, 1 = Blue, 2 = Green,\n3 = Pink, 4 = Red, 5 = Orange, Anything else = Random."
		],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (BF, GF, Dad)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a speciied suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF, GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change\nValue 2: New character's name\n\nOn Value 1, (BF, Dad, GF)"
		],
		[
			'Change Scroll Speed',
			'Value 1: New scroll speed\nValue 2: Duration of the speed tween\nValue 3: Optional ease name for the tween'
		],
	];

	var strumGroup:FlxTypedSpriteGroup<BabyArrow> = new FlxTypedSpriteGroup();

	var needsValue3:Array<String> = [
		'Change Scroll Speed',
	];

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSection:Int = 0;

	public static var lastSection:Int = 0;
	static var lastSong:String = '';

	var byInput:FlxUIInputText;

	var curEventSelected:Int;

	var bpmTxt:FlxUIText;
	var sectionTxt:FlxUIText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 50;

	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxUIText>;

	var curRenderedEvents:FlxTypedGroup<EventNote> = new FlxTypedGroup();
	var curRenderedTexts:FlxTypedGroup<AbsoluteFlxText> = new FlxTypedGroup();

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var backRenderedSustains:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
	var backRenderedNotes:FlxTypedGroup<Note> = new FlxTypedGroup();

	var gridBG:FlxSprite;
	var gridMult:Int = 2;

	var storyDifficulty:Int = PlayState.storyDifficulty;

	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	/**
	 * WILL BE CURRENT / LAST PLACED EVENT
	 */
	var curSelectedEvent:Array<Dynamic>;

	var tempBpm:Float = 0;

	var vocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;
	var zoomList:Array<Float> = [
		.25,
		.5,
		1,
		2,
		4,
		8,
		12,
		24
	].copy();
	
	var curZoom:Int = 2;
	var zoomTxt:FlxUIText;

	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var blockPressWhileScrolling:Array<FunkinDropDownMenu> = [];
	var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	var clearMem:Bool;
	public function new(?clear:Bool = false)
	{
		super();
		this.clearMem = clear;
	}

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace('', '-', ' '));
		#end

		Paths.clearMemory();
		if (clearMem)
			Paths.clearTrashMemory();

		PlayState.chartingMode = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE * 3, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE, -92.5).loadGraphic(Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.updateHitbox();
		rightIcon.updateHitbox();
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(GRID_SIZE, GRID_SIZE);
		eventIcon.alpha = .5;

		leftIcon.setGraphicSize(65, 65);
		rightIcon.setGraphicSize(65, 65);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxUIText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if (PlayState.SONG != null)
		{
			_song = PlayState.SONG;
		}
		else
		{
			_song = Song.loadFromJson('test', 1);
			PlayState.SONG = _song;
		}

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		#end

		if (curSection >= _song.notes.length)
			curSection = _song.notes.length - 1;

		FlxG.mouse.visible = true;

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);
		loadAudioBuffer();
		reloadGridLayer();
		loadSong();
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		strumLine = new FlxSprite(0, 50).loadGraphic(Paths.image('strumline'));
        strumLine.setGraphicSize(Std.int(GRID_SIZE * 9 + 30), Std.int(strumLine.height));
        strumLine.updateHitbox();
		strumLine.x += GRID_SIZE * 2 + 9.9;
		strumLine.color = FlxColor.fromRGB(220, 220, 220);
		add(strumLine);

		for (i in 0...8)
		{
			var note:BabyArrow = new BabyArrow(GRID_SIZE * (i + 1), strumLine.y, i % 4, 0);
			note.x += GRID_SIZE * 2;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static');
			note.alpha = .6;
			note.scrollFactor.set(1, 1);
			strumGroup.add(note);
		}
		add(strumGroup);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);
		camPos.x -= GRID_SIZE * 2;

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2 + GRID_SIZE / 2;
		UI_box.x += GRID_SIZE * 4 + 50;
		UI_box.y = 305;

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads(true);
		updateWaveform();
		UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(curRenderedEvents);
		add(curRenderedTexts);
		add(nextRenderedSustains);
		add(nextRenderedNotes);
		add(backRenderedNotes);
		add(backRenderedSustains);

		if (lastSong != currentSongName)
		{
			changeSection();
		}
		lastSong = currentSongName;

		zoomTxt = new FlxUIText(10, FlxG.height - 30, 0, "Zoom: 1x", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE);
		add(zoomTxt);

		/*var tipText:FlxUIText = new FlxUIText(zoomTxt.x, zoomTxt.y + 300, 0, "W/S or Mouse Wheel - Change Conductor's strum time
			\nA or Left/D or Right - Switch sections
			\nHold Shift to move 4x faster
			\nHold Control and click on an arrow to select it
			\nZ/X - Control Zoom
			\nQ/E - Decrease/Increase Note Sustain Length
			\nSpace - Stop/Resume song
			\nR - Reset section\n", 16);
		tipText.y += tipText.height / 2;
		// tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);*/

		bpmTxt = new FlxUIText(UI_box.x + 90, 25, 0, "", 25);
		bpmTxt.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE);
		//bpmTxt.scrollFactor.set();
		//bpmTxt.scrollFactor.y = 0;
		add(bpmTxt);

		sectionTxt = new FlxUIText(UI_box.x + 80, .0, 0, "", 25);
		sectionTxt.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE);
		sectionTxt.scrollFactor.set();
		add(sectionTxt);

		UI_box.setPosition(UI_box.x + 20, FlxG.height - 690);
		sectionTxt.setPosition(sectionTxt.x, FlxG.height - sectionTxt.height - 80);

		add(UI_box);
		updateZoom();
		updateGrid();
		super.create();
	}

	var check_mute_inst:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
	var stageDropDown:FunkinDropDownMenu;

	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle); 

		var check_voices:FlxUICheckBox = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			// trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var saveEvent:FlxButton = new FlxButton(saveButton.x, saveButton.y + 30, 'Save Events', function() saveEvent());

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = cast FunkySettings.bind('songs').data._song;
			MusicBeatState.resetState();
		});

		var loadEventBtn:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			loadEvents();
		});

		var clear_events:FlxButton = new FlxButton(200, 310, 'Clear events', function()
		{
			clearEvents();
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(200, clear_events.y + 30, 'Clear notes', function()
		{
			for (sec in 0..._song.notes.length)
			{
				var count:Int = 0;
				while (count < _song.notes[sec].sectionNotes.length)
				{
					var note:Array<Dynamic> = _song.notes[sec].sectionNotes[count];
					if (note != null && note[1] > -1)
					{
						_song.notes[sec].sectionNotes.remove(note);
					}
					else
					{
						count++;
					}
				}
			}
			updateGrid();
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 339, 1);
		@:privateAccess
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, .1, 1, .1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var directories:Array<String> = [Paths.mods('characters/'), Paths.getPath('characters/')];
		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (i in 0...characters.length)
		{
			tempMap.set(characters[i], true);
		}

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && (file.endsWith('.yaml')))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck))
						{
							tempMap.set(charToCheck, true);
							characters.push(charToCheck);
						}
					}
				}
			}
		}

		var player1DropDown:FunkinDropDownMenu = new FunkinDropDownMenu(10, stepperSpeed.y + 45, FunkinDropDownMenu.makeStrIdLabelArray(characters, true),
			function(character:String)
			{
				_song.player1 = characters[Std.parseInt(character)];
				updateHeads(true);
			});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown:FunkinDropDownMenu = new FunkinDropDownMenu(player1DropDown.x, player1DropDown.y + 40,
			FunkinDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
			updateHeads(true);
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown:FunkinDropDownMenu = new FunkinDropDownMenu(player1DropDown.x, gfVersionDropDown.y + 40,
			FunkinDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads(true);
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);
		var directories:Array<String> = [Paths.mods('stages/'), Paths.getPath('stages/')];
		tempMap.clear();
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var i:Int = 0;
		var stageLength:Int = stages.length;
		while (i < stageLength)
		{
			var removeStage:Bool = true;
			for (j in 0...directories.length)
			{
				var file:String = directories[j] + stages[i] + '.json';
				// //trace('Checking file: ' + file);

				if (FileSystem.exists(file))
				{
					removeStage = false;
					tempMap.set(stages[i], true);
					i++;
					break;
				}
			}

			if (removeStage)
			{
				stages.remove(stages[i]);
				stageLength = stages.length;
			}
		}

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);
						if (!tempMap.exists(stageToCheck))
						{
							tempMap.set(stageToCheck, true);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}

		if (stages.length < 1)
			stages.push('stage');

		stageDropDown = new FunkinDropDownMenu(player1DropDown.x + 140, player1DropDown.y, FunkinDropDownMenu.makeStrIdLabelArray(stages, true),
			function(character:String)
			{
				_song.stage = stages[Std.parseInt(character)];
			});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var diffs:Array<String> = CoolUtil.difficultyStuff.copy();
		var diffDropDown = new FunkinDropDownMenu(stageDropDown.x, stageDropDown.y + 40, FunkinDropDownMenu.makeStrIdLabelArray(diffs, true),
			function(diff:String)
			{
				PlayState.storyDifficulty = Std.parseInt(diff);
				PlayState.SONG = Song.loadFromJson(_song.song, PlayState.storyDifficulty);
				MusicBeatState.resetState();
			});
		diffDropDown.selectedLabel = diffs[storyDifficulty];

		var skin = '';

		if (PlayState.SONG != null)
			if (PlayState.SONG.arrowSkin != null)
				skin = PlayState.SONG.arrowSkin;

		noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 80, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		byInput = new FlxUIInputText(noteSkinInputText.x, noteSplashesInputText.y - 70, 150, _song.by, 8);
		blockPressWhileTypingOn.push(byInput);

		var reloadNotesButton:FlxButton = new FlxButton(clear_events.x, clear_events.y - 30, 'Reload Notes', function()
		{
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});

		var tab_group_song:FlxUI = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvent);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(noteSkinInputText);
		tab_group_song.add(noteSplashesInputText);
		tab_group_song.add(byInput);
		tab_group_song.add(new FlxUIText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxUIText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxUIText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxUIText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxUIText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxUIText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_song.add(new FlxUIText(diffDropDown.x, diffDropDown.y - 15, 0, 'Difficulty:'));
		tab_group_song.add(new FlxUIText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_song.add(new FlxUIText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(new FlxUIText(byInput.x, byInput.y - 15, 0, 'Song Author:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(diffDropDown);
		tab_group_song.add(stageDropDown);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(camPos);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;
	var eventsCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section:FlxUI = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSection].mustHitSection;

		check_altAnim = new FlxUICheckBox(130, check_mustHitSection.y + 22, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSection].altAnim;
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, check_altAnim.y, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSection].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if (check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSection].bpm;
		} else {
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			eventsCopied = [];

			sectionToCopy = curSection;
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					eventsCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if (notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (4 * 4 * (curSection - sectionToCopy));
			//trace('Time to add: ' + addToTime);

			for (note in eventsCopied)
			{
				var newStrumTime:Float = note[0] + addToTime;
				if (check_eventsSec.checked)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...note[2].length)
					{
						var eventToPush:Array<Dynamic> = note[2][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}

					_song.events.push([newStrumTime, copiedEventArray.copy()]);
				}
			}

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;

				if (check_notesSec.checked)
				{
					if (note[4] != null) 
						copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
					else 
						copiedNote = [newStrumTime, note[1], note[2], note[3]];
					
					_song.notes[curSection].sectionNotes.push(copiedNote);
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if (check_notesSec.checked)
			{
				_song.notes[curSection].sectionNotes = [];
			}

			if (check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;
		
		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if (value == 0) return;

			var daSec = FlxMath.maxInt(curSection, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (4 * 4 * value);


				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (4 * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();
		
		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSection].sectionNotes)
			{
				var boob = note[1];
				if (boob>3){
					boob -= 4;
				}else{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			_song.notes[curSection].sectionNotes.push(i);

			}

			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSection].sectionNotes)
			{
				var boob = note[1]%4;
				boob = 3 - boob;
				if (note[1] > 3) boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				//duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			//_song.notes[curSection].sectionNotes.push(i);

			}

			updateGrid();
		});

		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}


	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText;
	var noteTypeDropDown:FunkinDropDownMenu;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		var tab_group_note:FlxUI = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 32);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length)
		{
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		#if LUA_ALLOWED
		var directory:String = Paths.mods('custom_notetypes/');
		if (FileSystem.exists(directory))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				if (!FileSystem.isDirectory(path) && (file.endsWith('.lua') || file.endsWith('.hx')))
				{
					var fileToCheck:String = file.substr(0, file.length - 4);
					if (file.endsWith(".hx"))
						fileToCheck = file.substr(0, file.length - 3);
					if (!noteTypeMap.exists(fileToCheck))
					{
						displayNameList.push(fileToCheck);
						noteTypeMap.set(fileToCheck, key);
						noteTypeIntMap.set(key, fileToCheck);
						key++;
					}
				}
			}
		}
		#end

		for (i in 1...displayNameList.length)
		{
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FunkinDropDownMenu(10, 105, FunkinDropDownMenu.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxUIText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxUIText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxUIText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var value3InputText:FlxUIInputText;
	var value3Text:FlxUIText;
	var eventDropDown:FunkinDropDownMenu;
	var descText:FlxUIText;

	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directory:String = Paths.mods('custom_events/');
		if (FileSystem.exists(directory))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt'))
				{
					var fileToCheck:String = file.substr(0, file.length - 4);
					if (!eventPushedMap.exists(fileToCheck))
					{
						eventPushedMap.set(fileToCheck, true);
						eventStuff.push([fileToCheck, File.getContent(path)]);
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxUIText(20, 245, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length)
		{
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxUIText = new FlxUIText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FunkinDropDownMenu(20, 50, FunkinDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String)
		{
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedEvent != null)
			{
				curSelectedEvent[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxUIText = new FlxUIText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxUIText = new FlxUIText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		value3Text = new FlxUIText(20, 170, 0, "Value 3:");
		tab_group_event.add(value3Text);
		value3InputText = new FlxUIInputText(20, 190, 100, "");
		blockPressWhileTypingOn.push(value3InputText);
		
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if (curSelectedEvent != null) //Is event note
			{
				if (curSelectedEvent[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedEvent = null;
				}
				else
				{
					curSelectedEvent[1].remove(curSelectedEvent[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;

				if (curEventSelected < 0) 
					curEventSelected = 0;
				else if (curSelectedEvent != null && curEventSelected >= (eventsGroup = curSelectedEvent[1]).length) 
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if (curSelectedEvent != null && curSelectedEvent[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedEvent[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxUIText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(value3InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	var metronome:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	#if desktop
	var waveformEnabled:FlxUICheckBox;
	var waveformUseInstrumental:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var check_vortex:FlxUICheckBox;

	function addChartingUI()
	{
		var tab_group_chart:FlxUI = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		waveformEnabled = new FlxUICheckBox(10, 90, null, null, "Visible Waveform", 100);
		waveformEnabled.checked = false;
		waveformEnabled.callback = function()
		{
			updateWaveform();
		};

		waveformUseInstrumental = new FlxUICheckBox(waveformEnabled.x + 120, waveformEnabled.y, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = false;
		waveformUseInstrumental.callback = function()
		{
			updateWaveform();
		};
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var check_mute_vocals:FlxUICheckBox = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			if (vocals != null)
			{
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor", 100);
		check_vortex.callback = function()
		{	
			strumGroup.visible = check_vortex.checked;
			FlxG.save.data.chart_vortex = check_vortex.checked;
			FlxG.save.flush();
		};
		check_vortex.callback();
		
		if (FlxG.save.data.chart_vortex == null) 
			FlxG.save.data.chart_vortex = false;

		check_vortex.checked = FlxG.save.data.chart_vortex;

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100);
		playSoundBf.checked = false;
		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100);
		playSoundDad.checked = false;

		metronome = new FlxUICheckBox(15, 15, null, null, "Metronome Enabled", 100);
		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, .1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, .1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';

		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);
		blockPressWhileTypingOnStepper.push(instVolume);
		blockPressWhileTypingOnStepper.push(voicesVolume);

		addtoGroup(metronome, tab_group_chart);
		addtoGroup(new FlxUIText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'), tab_group_chart);
		addtoGroup(new FlxUIText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'), tab_group_chart);
		addtoGroup(new FlxUIText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'), tab_group_chart);
		addtoGroup(new FlxUIText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'), tab_group_chart);
		addtoGroup(metronomeStepper, tab_group_chart);
		addtoGroup(metronomeOffsetStepper, tab_group_chart);
		#if desktop
		addtoGroup(waveformEnabled, tab_group_chart);
		addtoGroup(waveformUseInstrumental, tab_group_chart);
		#end
		addtoGroup(instVolume, tab_group_chart);
		addtoGroup(voicesVolume, tab_group_chart);
		addtoGroup(check_mute_inst, tab_group_chart);
		addtoGroup(check_mute_vocals, tab_group_chart);
		addtoGroup(check_vortex, tab_group_chart);
		addtoGroup(playSoundBf, tab_group_chart);
		addtoGroup(playSoundDad, tab_group_chart);
		UI_box.addGroup(tab_group_chart);
	}

	function addtoGroup(Basic:FlxSprite, group:FlxUI):FlxSprite
	{
		return group.add(Basic);
	}

	function loadEvents():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		var formattedFolder:String = Paths.formatToSongPath(_song.song);
		var eventFile:String = Paths.modsJson('$formattedFolder/events');

		if (!FileSystem.exists(eventFile))
			eventFile = Paths.json('$formattedFolder/events');

		try 
		{
			_song.events = Song.parseEVENTshit(eventFile);
		}
		catch (e)
		{
			_song.events = [];
		}

		updateGrid();
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		var file = Paths.voices(currentSongName);
		vocals = new FlxSound().loadEmbedded(file);
		FlxG.sound.list.add(vocals);
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong()
	{
		FlxG.sound.playMusic(Paths.inst(currentSongName), .6, false);
		if (instVolume != null)
			FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked)
			FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			generateSong();
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if (vocals != null)
			{
				vocals.play();
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSection = 0;
			updateGrid();
			updateSectionUI();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxUIText = new FlxUIText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				_song.bpm = tempBpm;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			else if (wname == 'note_susLength')
			{
				if (curSelectedNote != null && curSelectedNote[1] > -1)
				{
					curSelectedNote[2] = nums.value;
					updateGrid();
				}
				else
				{
					sender.value = 0;
				}
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = nums.value;
				updateGrid();
			}
			else if (wname == 'inst_volume')
			{
				FlxG.sound.music.volume = nums.value;
			}
			else if (wname == 'voices_volume')
			{
				vocals.volume = nums.value;
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == noteSplashesInputText)
			{
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if (sender == strumTimeInputText && curSelectedNote != null)
			{
				var value:Float = Std.parseFloat(strumTimeInputText.text);
				if (Math.isNaN(value))
					value = 0;
				curSelectedNote[0] = value;
				updateGrid();
			}
			else if (sender == value1InputText && curSelectedEvent != null)
			{
				curSelectedEvent[1][curEventSelected][1] = value1InputText.text;
				updateGrid();
			}
			else if (sender == value2InputText && curSelectedEvent != null)
			{
				curSelectedEvent[1][curEventSelected][2] = value2InputText.text;
				updateGrid();
			}
			else if (sender == value3InputText && curSelectedEvent != null)
			{
				curSelectedEvent[1][curEventSelected][3] = value3InputText.text;
				updateGrid();
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += 4 * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	var eventSine:Float;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;
		_song.by = byInput.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		camPos.y = strumLine.y;

		value3InputText.visible = needsValue3.contains(eventDropDown.selectedLabel);
		value3Text.visible = value3InputText.visible;
		value3InputText.active = value3InputText.visible;
		
		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			// trace(curStep);
			// trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			// trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}
		else if (strumLine.y < -10)
		{
			changeSection(curSection - 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							// trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else if (FlxG.mouse.overlaps(curRenderedEvents))
			{
				curRenderedEvents.forEach(function(evt:EventNote)
				{
					if (FlxG.mouse.overlaps(evt))
					{
						if (FlxG.keys.pressed.CONTROL)
							selectEvent(evt);
						else
							deleteEvent(evt);
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x 
					&& FlxG.mouse.x < gridBG.x + gridBG.width 
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					addNote();
				}

				else if (FlxG.mouse.x > gridEvent.x 
					&& FlxG.mouse.x < gridEvent.x + gridEvent.width
					&& FlxG.mouse.y > gridEvent.y
					&& FlxG.mouse.y < gridEvent.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
				{
					FlxG.log.add('added event');
					addEvent();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x 
			&& FlxG.mouse.x < gridBG.x + gridBG.width 
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			dummyArrow.setGraphicSize(50, 50);
			dummyArrow.updateHitbox();
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		else if (FlxG.mouse.x > gridEvent.x 
			&& FlxG.mouse.x < gridEvent.x + gridEvent.width
			&& FlxG.mouse.y > gridEvent.y
			&& FlxG.mouse.y < gridEvent.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE + 2;
			dummyArrow.setGraphicSize(48, 48);
			dummyArrow.updateHitbox();
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}
		for (stepper in blockPressWhileTypingOnStepper)
		{
			@:privateAccess
			var inputText:FlxUIInputText = cast stepper.text_field;

			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}
		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if (vocals != null)
					vocals.stop();

				// if (_song.stage == null) _song.stage = stageDropDown.selectedLabel;
				StageData.loadDirectory(_song);
				MusicBeatState.switchState(new PlayState());
			}

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}

			if (FlxG.keys.justPressed.Z && curZoom > 0) 
			{
				--curZoom;
				updateZoom();
			}

			if (FlxG.keys.justPressed.X && curZoom < zoomList.length-1) 
			{
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (vocals != null)
						vocals.pause();
				}
				else
				{
					if (vocals != null)
					{
						vocals.play();
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
						vocals.play();
					}
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * .4);
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = FlxG.keys.pressed.SHIFT ? 3 : 1;
				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				if (FlxG.keys.pressed.W)
				{
					FlxG.sound.music.time -= daTime;
				}
				else
					FlxG.sound.music.time += daTime;

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
				changeSection(curSection + shiftThing);
			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			{
				if (curSection <= 0)
				{
					changeSection(_song.notes.length - 1);
				}
				else
				{
					changeSection(curSection - shiftThing);
				}
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus)
				{
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		_song.bpm = tempBpm;

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}

		bpmTxt.text = "Time: "
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 1))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 1));

		Conductor.songPosition = FlxG.sound.music.time;
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		camPos.y = strumLine.y;
		strumLine.y -= 9.5;
		var oldWidth:Float = bpmTxt.width;
		if (oldWidth != bpmTxt.width)
			oldWidth = bpmTxt.width;
		bpmTxt.setPosition(strumLine.x - oldWidth - 70, strumLine.y);

		strumGroup.forEach(function(strum:BabyArrow)
		{
			strum.y = strumLine.y;
			if (strum.animation.curAnim.name == 'confirm')
				strum.alpha = 1;
			else
				strum.alpha = .6;
		});
			
		sectionTxt.text = "\nSection: "
			+ curSection
			+ " / "
			+ _song.notes.length
			+ "\n        Beat: "
			+ curBeat
			+ "\n        Step: "
			+ curStep;

		curRenderedEvents.forEachAlive(function(event:EventNote)
		{
			event.alpha = 1;

			if (isSameEvent(event, curSelectedEvent))
			{
				eventSine += 180 * FlxG.elapsed;
				var colorVal:Float = .7 + Math.sin((Math.PI * eventSine) / 180) * .3;
				event.color.lightness = colorVal;
				event.alpha = .98;
			}
		});

		var playedSound:Array<Bool> = [false, false, false, false]; // Prevents earrape GF ahegao sounds
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			note.alpha = 1; // Fixes issues where notes would disappear while a note is selected
			
			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection)
					noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime && curSelectedNote[1] == noteDataToCheck)
				{
					colorSine += 180 * elapsed;
					var colorVal:Float = .7 + Math.sin((Math.PI * colorSine) / 180) * .3;
					note.color.lightness = colorVal;
					note.alpha = .999; // Alpha can't be 100% or the color won't be updated for some reason, guess ill die
				}
			}

			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = .4;

				if (note.strumTime > lastConductorPos
					&& FlxG.sound.music.playing
					&& note.noteData > -1)
				{
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = data;

					if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection) 
						noteDataToCheck += 4;
					
					strumGroup.members[noteDataToCheck].playAnim('confirm', true);
					strumGroup.members[noteDataToCheck].holdTimer = note.sustainLength / 1000 + .15;

					var data:Int = note.noteData % 4;

					if (((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)))
					{
						if (!playedSound[data])
						{
							var soundToPlay:String = 'ChartingTick';
							FlxG.sound.play(Paths.sound(soundToPlay));
							playedSound[data] = true;
						}
					}
				}
			}
		});

		if (metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if (metroStep != lastMetroStep)
			{
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				// //trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function updateZoom()
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1) 
			zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

	function loadAudioBuffer()
	{
		audioBuffers[0] = null;
		if (Paths.exists('songs/' + currentSongName + '/Inst.ogg'))
		{
			audioBuffers[0] = AudioBuffer.fromFile(Paths.inst(currentSongName, true));
			trace('FOUND DA INSTRUMENTAL LETS FUCKING GOOO');
		}

		audioBuffers[1] = null;
		if (Paths.exists('songs/' + currentSongName + '/Voices.ogg'))
		{
			audioBuffers[1] = AudioBuffer.fromFile(Paths.voices(currentSongName, true));
			trace('FOUND DA VOCALS LETS FUCKING GOOO');
		}
	}

	var gridBG2:FlxSprite;
	var gridSecond:FlxSprite;
	var gridEvent:FlxSprite;
	var gridEvent2:FlxSprite;
	function reloadGridLayer(?peanut:Bool = true)
	{
		@:privateAccess
		try for (i in gridLayer.members)
		{
			var FlxGraphic = i.graphic;
			var id:String = null;

			for (key in FlxG.bitmap._cache.keys())
				if (FlxG.bitmap._cache.get(key) == FlxGraphic)
				{
					id = key;
					break;
				}
			
			Assets.cache.removeBitmapData(id);
			FlxG.bitmap._cache.remove(id);
			FlxGraphic.destroy();
		} catch (exception:Dynamic) trace(exception);

		gridLayer.clear();

		var cellColor:FlxColor = FlxColor.fromRGB(135, 135, 135);
		var cellColor2:FlxColor = FlxColor.fromRGB(105, 105, 105);

		if (peanut)
		{
			gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, Std.int(GRID_SIZE * 32 * zoomList[curZoom]), true, cellColor, cellColor2);
			gridBG.x += GRID_SIZE * 3;
		
			gridEvent = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, Std.int(GRID_SIZE * 32 * zoomList[curZoom]), true, cellColor, cellColor2);
			gridEvent.x += GRID_SIZE;
		}

		gridBG.graphic.bitmap.colorTransform(gridBG.graphic.bitmap.rect, new ColorTransform(1, 1, 1, .22));
		gridEvent.graphic.bitmap.colorTransform(gridEvent.graphic.bitmap.rect, new ColorTransform(1, 1, 1, .22));
		
		gridLayer.add(gridBG);
		gridLayer.add(gridSecond);
		gridLayer.add(gridEvent);

		gridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, Std.int(GRID_SIZE * 32 * zoomList[curZoom]), true, cellColor, cellColor2);
		gridBG2.x += GRID_SIZE * 3;
		gridBG2.graphic.bitmap.colorTransform(gridBG.graphic.bitmap.rect, new ColorTransform(1, 1, 1, .26));

		gridLayer.add(gridBG2);
		gridBG2.y -= gridBG.height;

		gridEvent2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, Std.int(GRID_SIZE * 32 * zoomList[curZoom]), true, cellColor, cellColor2);
		gridEvent2.graphic.bitmap.colorTransform(gridBG.graphic.bitmap.rect, new ColorTransform(1, 1, 1, .26));
		gridEvent2.x += GRID_SIZE;
		gridEvent2.y -= gridBG.height;
		gridLayer.add(gridEvent2);
	
		#if desktop
		if (waveformEnabled != null)
		{
			updateWaveform();
		}
		#end

		var gridBlack:FlxSprite = new FlxSprite().makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG2.height), FlxColor.BLACK);
		gridBlack.alpha = .3;
		gridBlack.y -= gridBG2.height;
		gridBlack.x += GRID_SIZE * 3;
		gridLayer.add(gridBlack);

		var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height / 2).makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), FlxColor.BLACK);
		gridBlack.x += GRID_SIZE * 3;
		gridBlack.alpha = .3;
		gridLayer.add(gridBlack);

		var gridBlack:FlxSprite = new FlxSprite().makeGraphic(Std.int(GRID_SIZE), Std.int(gridEvent.height), FlxColor.BLACK);
		gridBlack.x += GRID_SIZE;
		gridBlack.alpha = .3;
		gridBlack.y -= gridEvent.height;
		gridLayer.add(gridBlack);
		
		var gridBlack:FlxSprite = new FlxSprite(0, gridEvent.height / 2).makeGraphic(GRID_SIZE, Std.int(gridEvent.height), FlxColor.BLACK);
		gridBlack.x += GRID_SIZE;
		gridBlack.alpha = .3;
		gridLayer.add(gridBlack);

		var cellColor:FlxColor = FlxColor.fromRGB(135, 135, 135);
		var height:Int = Std.int(gridBG.height + gridBG2.height * 2);
		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(4, Std.int(height), cellColor);
		gridBlackLine.y -= height / 2;
		gridLayer.add(gridBlackLine);
		
		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width).makeGraphic(4, height, cellColor);
		gridBlackLine.y -= height / 2;
		gridLayer.add(gridBlackLine);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x).makeGraphic(4, height, cellColor);
		gridBlackLine.y -= height / 2;
		gridLayer.add(gridBlackLine);

		var gridBlackLine:FlxSprite = new FlxSprite(gridEvent.x + gridEvent.width).makeGraphic(4, height, cellColor);
		gridBlackLine.y -= height / 2;
		gridLayer.add(gridBlackLine);

		var gridBlackLine:FlxSprite = new FlxSprite(gridEvent.x).makeGraphic(4, height, cellColor);
		gridBlackLine.y -= height / 2;
		gridLayer.add(gridBlackLine);

		updateGrid();
	}

	var audioBuffers:Array<AudioBuffer> = [null, null];

	function updateWaveform()
	{
		#if desktop
		waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
		waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);

		var checkForVoices:Int = 1;
		if (waveformUseInstrumental.checked)
			checkForVoices = 0;

		if (!waveformEnabled.checked || audioBuffers[checkForVoices] == null)
		{
			//trace('Epic fail on the waveform lol');
			return;
		}

		var sampleMult:Float = audioBuffers[checkForVoices].sampleRate / 44100;
		var index:Int = Std.int(sectionStartTime() * 44.0875 * sampleMult);
		var drawIndex:Int = 0;

		var steps:Int = _song.notes[curSection].lengthInSteps;
		if (Math.isNaN(steps) || steps < 1)
			steps = 16;
		var samplesPerRow:Int = Std.int(((Conductor.stepCrochet * steps * 1.1 * sampleMult) / 16) / zoomList[curZoom]);
		if (samplesPerRow < 1)
			samplesPerRow = 1;
		var waveBytes:Bytes = audioBuffers[checkForVoices].data.toBytes();

		var min:Float = 0;
		var max:Float = 0;
		while (index < (waveBytes.length - 1))
		{
			var byte:Int = waveBytes.getUInt16(index * 4);

			if (byte > 65535 / 2)
				byte -= 65535;

			var sample:Float = (byte / 65535);

			if (sample > 0)
			{
				if (sample > max)
					max = sample;
			}
			else if (sample < 0)
			{
				if (sample < min)
					min = sample;
			}

			if ((index % samplesPerRow) == 0)
			{
				// //trace("min: " + min + ", max: " + max);

				/*if (drawIndex > gridBG.height)
					{
						drawIndex = 0;
				}*/

				var pixelsMin:Float = Math.abs(min * (GRID_SIZE * 8));
				var pixelsMax:Float = max * (GRID_SIZE * 8);
				waveformSprite.pixels.fillRect(new Rectangle(Std.int((GRID_SIZE * 4) - pixelsMin), drawIndex, pixelsMin + pixelsMax, 1), FlxColor.BLUE);
				drawIndex++;

				min = 0;
				max = 0;

				if (drawIndex > gridBG.height)
					break;
			}

			index++;
		}
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		if (vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		// trace('changing section' + sec);
		if (_song.notes[sec] != null)
		{
			curSection = sec;

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		//stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var healthIconP1:String;
	var healthIconP2:String;

	function updateHeads(?reload:Bool = false):Void
	{
		if (reload) 
		{
			healthIconP1 = loadHealthIconFromCharacterThisIsSuchALongNameAAAAAA(_song.player1);
			healthIconP2 = loadHealthIconFromCharacterThisIsSuchALongNameAAAAAA(_song.player2);
		}

		if (_song.notes[curSection].mustHitSection)
		{
			if (leftIcon.getCharacter() != healthIconP1)
				leftIcon.changeIcon(healthIconP1);
			if (rightIcon.getCharacter() != healthIconP2)
				rightIcon.changeIcon(healthIconP2);
		}
		else
		{
			if (leftIcon.getCharacter() != healthIconP2)
				leftIcon.changeIcon(healthIconP2);
			if (rightIcon.getCharacter() != healthIconP1)
				rightIcon.changeIcon(healthIconP1);
		}
	}

	/**
		This function fucks the optimization so badly.
	**/
	function loadHealthIconFromCharacterThisIsSuchALongNameAAAAAA(char:String):String
	{
		var characterPath:String = 'characters/' + char + '.yaml';
		var path:String = Paths.mods(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getPath(characterPath);
		}

		if (!FileSystem.exists(path))
		{
			path = Paths.getPath('characters/' + Character.DEFAULT_CHARACTER +
				'.yaml'); 
		}

		var json:Character.CharacterFile = cast Yaml.read(path, Parser.options().useObjects());
		return json.healthicon;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[1] > -1)
			{
				stepperSusLength.value = curSelectedNote[2];
				if (curSelectedNote[3] != null)
				{
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if (currentType <= 0)
					{
						noteTypeDropDown.selectedLabel = '';
					}
					else
					{
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			}
			strumTimeInputText.text = curSelectedNote[0];
		}
	}

	final function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		curRenderedEvents.clear();
		curRenderedTexts.clear();

		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		backRenderedNotes.clear();
		backRenderedSustains.clear();

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			// trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						//trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		// CURRENT SECTION
		for (i in _song.notes[curSection].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				for (i in setupSusNote(i, note, Conductor.stepCrochet))
					curRenderedSustains.add(i);
			}

			if (note.y < -150)
				note.y = -150;

			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt == null)
					theType = '?';

				var daText:AbsoluteFlxText = new AbsoluteFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.offsetX = -32;
				daText.offsetY = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.tracker = note;
			}
			note.mustPress = _song.notes[curSection].mustHitSection;

			if (i[1] > 3)
				note.mustPress = !note.mustPress;
		}

		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);

		if (_song.events != null)
			for (i in _song.events)
			{
				if (endThing > i[0] && i[0] >= startThing)
				{
					var event:EventNote = new EventNote(i[1][curEventSelected][0], i[0], i[1][curEventSelected][1], i[1][curEventSelected][2], i[1][curEventSelected][3]);
					event.y = Math.floor(getYfromStrum((event.strumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps),
						false));
					event.setGraphicSize(GRID_SIZE, GRID_SIZE);
					event.updateHitbox();
					event.x += GRID_SIZE;
					curRenderedEvents.add(event);

					var daText:AbsoluteFlxText = new AbsoluteFlxText(0, 0, 300,
						'Event: '
						+ event.event
						+ ' ('
						+ Math.floor(event.strumTime)
						+ ' ms)'
						+ '\nValue 1: '
						+ event.val1
						+ '\nValue 2: '
						+ event.val2, 12);
					daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					daText.offsetX = -330;
					daText.offsetY = 9;
					daText.borderSize = 1.025;
					curRenderedTexts.add(daText);
					daText.tracker = event;
					event.childs = [daText];

					var daText2 = daText;

					if (event.val3 != null && event.val3.length > 0)
					{
						daText.text += '\nValue 3: ${event.val3}';
					}

					else if (i[1].length > 1)
					{
						daText.text = '${i[1].length} Events:\n';
						daText.text += getEventName(i[1]);
					}
					
					var daText:AbsoluteFlxText = new AbsoluteFlxText(0, 0, 50, ">", 12);
					daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					daText.offsetX += 270;
					daText.offsetY = 10;
					daText.borderSize = 1.025;
					daText.tracker = daText2;
					event.childs.push(daText);
					curRenderedTexts.add(daText);
				}
			}

		// NEXT SECTION
		if (curSection < _song.notes.length - 1)
		{
			for (i in _song.notes[curSection + 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = .6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					for (i in setupSusNote(i, note, Conductor.stepCrochet))
					{
						nextRenderedSustains.add(i);
					}
				}
			}
		}

		// PREVIOUS SECTION
		if (curSection > 0)
		{
			for (i in _song.notes[curSection - 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, null);
				//note.y = Math.ffloor(getYfromStrum((note.strumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection - 1].lengthInSteps), false));
				note.alpha = .6;
				backRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					for (i in setupSusNote(i, note, Conductor.stepCrochet))
						backRenderedNotes.add(i);
				}
			}
		}

		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);

		if (_song.events != null && _song.events.length > 1)
			for (i in _song.events)
			{
				if (endThing > i[0] && i[0] >= startThing)
				{
					var event:EventNote = new EventNote(i[1], i[0], i[2], i[3], i[4]);
					event.y = (GRID_SIZE * 16 * zoomList[curZoom])
						+ Math.floor(getYfromStrum((event.strumTime - sectionStartTime(1)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps),
							false));
					event.setGraphicSize(GRID_SIZE, GRID_SIZE);
					event.updateHitbox();
					curRenderedEvents.add(event);
				}
			}
	}

	var selectedEventText:FlxUIText;
	function changeEventSelected(change:Int = 0)
	{
		if (curSelectedEvent != null)
		{
			curEventSelected += change;

			if (curEventSelected < 0) 
				curEventSelected = Std.int(curSelectedEvent[1].length) - 1;
			else if (curEventSelected >= curSelectedEvent[1].length) 
				curEventSelected = 0;

			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedEvent[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}

		return updateEventUI();
	}

	function setupNoteData(i:Array<Dynamic>, ?isNextSection:Bool):Note
	{
		// null isNextSection means previous section
		var daNoteInfo:Int = cast i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, null, true);
		if (daNoteInfo > -1)
		{ // Common note
			if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if (i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(GRID_SIZE * (daNoteInfo + 1));
		note.x += GRID_SIZE * 2;
		if ((isNextSection || isNextSection == null) && _song.notes[curSection].mustHitSection != _song.notes[curSection + (isNextSection == null ? -1 : 1)].mustHitSection)
		{
			if (daNoteInfo > 3)
			{
				note.x -= GRID_SIZE * 4;
			}
			else if (daNoteInfo > -1)
			{
				note.x += GRID_SIZE * 4;
			}
		}

		note.y = (GRID_SIZE * (isNextSection ? 16 : isNextSection == null ? -16 : 0)) * zoomList[curZoom]
			+ Math.floor(getYfromStrum((daStrumTime - sectionStartTime(isNextSection ? 1 : isNextSection == null ? -1 : 0)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps), false));
		return note;
	}

	function setupSusNote(i:Array<Dynamic>, note:Note, stepCrochet:Float):Array<Note>
	{
		var floorSus:Int = Math.floor(note.sustainLength / stepCrochet);
		var oldNote:Note = note;
		var spr:Array<Note> = [];
		if (floorSus < 1)
			floorSus = 1;

		var daNoteInfo:Int = i[1];

		for (i in 0...floorSus + 1)
		{
			var sustainNote:Note = new Note(note.strumTime + (stepCrochet * i) + stepCrochet, note.noteData % 4, oldNote, true);
			sustainNote.setGraphicSize(Std.int(GRID_SIZE / 3), Std.int(GRID_SIZE / 3));
			sustainNote.updateHitbox();
			sustainNote.x = Math.ffloor((daNoteInfo + 1) * GRID_SIZE);
			sustainNote.x += GRID_SIZE * 2;
			sustainNote.y = oldNote.y + GRID_SIZE;
			sustainNote.flipY = false;
			sustainNote.scale.y = 1;
			oldNote = sustainNote;
			spr.push(sustainNote);
		}

		for (i in spr)
		{
			//taken from andromeda
			if (i.animation.curAnim != null && i.animation.curAnim.name.endsWith("end"))
			{
				if (PlayState.isPixelStage)
				{
					i.setGraphicSize(Std.int(GRID_SIZE * .35), Std.int(GRID_SIZE * .35));
					i.updateHitbox();
					i.offset.x = -17.25;
					i.offset.y = (GRID_SIZE * .35) / 2;
				} 
				else
				{
					i.setGraphicSize(Std.int(GRID_SIZE * .35), Std.int((GRID_SIZE) / 2) + 2);
					i.updateHitbox();
					i.offset.x = 1;
					i.offset.y = (GRID_SIZE) / 2 + 16;
				}
			}
			else
			{
				i.setGraphicSize(Std.int(GRID_SIZE * .35), GRID_SIZE + 1);
				i.updateHitbox();
				i.offset.x = 1;
				i.offset.y += 22.5;
				if (PlayState.isPixelStage)
					i.offset.x = -17.25;
			}
		}

		return spr;
	}

	function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection)
			noteDataToCheck += 4;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
			{
				curSelectedNote = i;
				break;
			}
		}

		updateGrid();
		updateNoteUI();
	}

	function isSameEvent(event:EventNote, array:Array<Dynamic>)
	{
		if (array == null)
			return false;

		return array[0] == event.strumTime;
	}

	function selectEvent(event:EventNote):Void
	{
		for (i in _song.events)
			if (isSameEvent(event, i))
			{
				curSelectedEvent = i;
				changeEventSelected();
				updateGrid();
				break;
			}
	}

	function updateEventUI()
	{
		if (curSelectedEvent == null)
			return;

		value1InputText.text = curSelectedEvent[1][curEventSelected][1];
		value2InputText.text = curSelectedEvent[1][curEventSelected][2];
		value3InputText.text = curSelectedEvent[1][curEventSelected][3];
		eventDropDown.selectedLabel = curSelectedEvent[1][curEventSelected][0];
	}

	function deleteEvent(event:EventNote):Void
	{
		for (i in _song.events)
		{
			if (isSameEvent(event, i))
			{
				_song.events.remove(i);
				for (child in event.childs)
				{
					curRenderedTexts.remove(child);
					curSelectedEvent = null;
				}
				updateGrid();
				break;
			}
		}
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection)
			noteDataToCheck += 4;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] == noteDataToCheck)
			{
				if (i == curSelectedNote)
					curSelectedNote = null;
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
				break;
			}
		}

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	function addEvent():Void
	{
		var noteStrum:Float = getStrumTime(dummyArrow.y, false) + sectionStartTime();
		var event:String = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
		var text1:String = value1InputText.text;
		var text2:String = value2InputText.text;
		var text3:String = value3InputText.text;

		_song.events.push([noteStrum, [[event, text1, text2, text3]]]);
		curSelectedEvent = _song.events[_song.events.length - 1];

		changeEventSelected();
		updateGrid();
	}

	function addNote(?add:Int = 0):Void
	{
		var noteStrum:Float = getStrumTime(dummyArrow.y, false) + sectionStartTime();
		var noteData:Int = Math.floor((FlxG.mouse.x + (GRID_SIZE * -3)) / GRID_SIZE) + add;
		var noteSus:Int = 0;
		var daType:Int = currentType;

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteTypeIntMap.get(daType)]);
		}

		// //trace(noteData + ', ' + noteStrum + ', ' + curSection);
		strumTimeInputText.text = curSelectedNote[0];

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + (gridBG.height / gridMult) * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + (gridBG.height / gridMult) * leZoom);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					//trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	var daSpacing:Float = .3;

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), storyDifficulty);
		MusicBeatState.resetState();
	}

	function autosaveSong():Void
	{
		var save = FunkySettings.bind('songs');
		save.data._song = _song;
		save.flush();
	}

	function clearEvents()
	{
		_song.events = [];
		updateGrid();
	}

	function saveLevel()
	{
		var SONG:SwagSong = {
			song: _song.song,
			notes: _song.notes,
			bpm: _song.bpm,
			needsVoices: _song.needsVoices,
			speed: _song.speed,
			player1: _song.player1,
			player2: _song.player2,
			gfVersion: _song.gfVersion,
			stage: _song.stage,
			arrowSkin: _song.arrowSkin,
			splashSkin: _song.splashSkin,
			validScore: true,
			by: _song.by,
			events: []
		};

		var json = {
			"song": SONG
		};

		var data:String = Json.stringify(json, "\t");
		var diff:String = Paths.formatToSongPath(CoolUtil.difficultyStuff[storyDifficulty]);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), diff + ".json");
		}
	}

	function saveEvent()
	{
		var json = {
			"events": _song.events
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), 'events.json');
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	override function add(Basic):FlxBasic
	{
		if (Std.isOfType(Basic, FlxButton))
			cast(Basic, FlxButton).label.font = Paths.font('vcr.ttf');

		return super.add(Basic);
	}
}