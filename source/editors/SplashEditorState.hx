package editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIColorSwatchSelecter;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

using StringTools;

/**
 To do: Color + Notetype support
 */
class SplashEditorState extends MusicBeatState
{
    var strums:FlxTypedSpriteGroup<BabyArrow> = new FlxTypedSpriteGroup();
    var splashes:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup();
    var meta = NoteSplash.createMeta();
    var tipText:FlxUIText;
    var errorText:FlxUIText;
    var curText:FlxUIText;

    static var defaultSkin:String = NoteSplash.DEFAULT_SKIN;

    var splash:NoteSplash;

    var UI:FlxUITabMenu;
    var properUI:FlxUITabMenu;
    var noteData:Int;

    var curType:String;

    var currentNoteType:FlxUIInputText;
    override function create()
    {
        FlxG.sound.volumeUpKeys = [FlxKey.PLUS];
        FlxG.sound.volumeDownKeys = [FlxKey.MINUS];
        FlxG.sound.muteKeys = [];

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF505050;
		add(bg);      

        var tabs:Array<{name:String, label:String}> = [
            {name: "Animation", label: "Animation"},
        ];

        UI = new FlxUITabMenu(null, tabs, true);
        UI.y += 20;
        UI.x = FlxG.width - UI.width - 110;
        UI.resize(290, 240);

        tabs = [{name: "Properities", label: "Properities"}];

        properUI = new FlxUITabMenu(null, tabs, true);
        properUI.resize(280, 210);
        properUI.y += 20;
        properUI.x = UI.x - properUI.width - 5;
        add(properUI);

        add(UI);

        var text:FlxUIText = new FlxUIText();
        text.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
        text.borderSize = 2;
        text.borderQuality = 4;
        text.text = 'If you want an animation to play on all strums,\nset the note data to -1. ';
        text.text += 'Only available with\nanimations with a note type.';
        text.screenCenter(X);
        text.y += 70;
        text.x -= 300;
        add(text);

        for (i in 0...4)
        {
            var babyArrow:BabyArrow = new BabyArrow(-273, 50, i % 4, 1);
            babyArrow.postAddedToGroup();
            babyArrow.screenCenter(Y);
            babyArrow.ID = i % 4;
            //babyArrow.scale.scale(1.1, 1.1);
            strums.add(babyArrow);
        }
        
        add(strums);
        add(splashes);

        splash = new NoteSplash(defaultSkin);
        splash.alpha = .0;
        splashes.add(splash);

        if (splash.meta != null)
            meta = splash.meta;

        addAnimTab();
        addProperitiesTab();

        tipText = new FlxUIText();
        tipText.setFormat(Paths.font('vcr.ttf'), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        tipText.borderSize = 3.6;
        tipText.borderQuality = 7.9;
        tipText.text = "Click on strums to do splash effect on them.\n\n";
        tipText.text += "Press arrow keys to set offsets for current animation.\nHold SHIFT to change 10x faster.";
        tipText.screenCenter();
        tipText.y += 210;
        tipText.antialiasing = true;
        add(tipText);

        errorText = new FlxUIText();
        errorText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.RED);
        errorText.text = "ERROR!";
        errorText.y = 240;
        errorText.x = UI.x - 100;
        errorText.alpha = .0;
        add(errorText);

        curText = new FlxUIText();
        curText.setFormat(Paths.font('vcr.ttf'), 24, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        tipText.borderSize = 3.9;
        tipText.borderQuality = 4.9;
        curText.text = 'Current Animation: $curAnim';
        curText.y = FlxG.height - curText.height;
        add(curText);

        currentNoteType = new FlxUIInputText(0, 0, 200, "", 16);
        currentNoteType.setPosition(FlxG.width - currentNoteType.width - 20, FlxG.height - currentNoteType.height - 10);
        add(currentNoteType);
        blockInputWhileTyping.push(currentNoteType);

        var text:FlxUIText = new FlxUIText();
        text.setFormat(Paths.font('vcr.ttf'), 20);
        text.text = 'Note Type:';
        text.setPosition(currentNoteType.x - 130, currentNoteType.y + 2);
        add(text);

        super.create();
    }

    var animDropDown:FunkinDropDownMenu;
    var blockInputWhileTyping:Array<FlxUIInputText> = [];
    var blockInputWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
    var curAnim:String;
    var addButton:FlxUIButton;
    var curAnimText = null;
    var numericStepperData:FlxUINumericStepper;
    function addAnimTab()
    {
        var ui:FlxUI = new FlxUI(null, UI);
        ui.name = "Animation";

        ui.add(new FlxUIText(20, 20, 0, "Animation Name:", 8));
        var name_input:FlxUIInputText = new FlxUIInputText(20, 37.5, 100, "", 8);
        name_input.name = "name_input";
        curAnimText = name_input;
        ui.add(name_input);
        blockInputWhileTyping.push(name_input);

        ui.add(new FlxUIText(name_input.x, name_input.y + 30, 0, "Animation Prefix:", 8));
        var prefix_input:FlxUIInputText = new FlxUIInputText(20, name_input.y + 47.5, 100, "", 8);
        ui.add(prefix_input);
        blockInputWhileTyping.push(prefix_input);

        ui.add(new FlxUIText(150, name_input.y + 30, 0, "Note Type (OPTIONAL):"));
        var note_type:FlxUIInputText = new FlxUIInputText(150, name_input.y + 30 + 17.5, 100, "", 8);
        ui.add(note_type);
        blockInputWhileTyping.push(note_type);

        ui.add(new FlxUIText(150, 20, 0, "Note Data:"));
        numericStepperData = new FlxUINumericStepper(150, 37.5, 1, .0, .0, 3, 0);
        noteImageInputText = note_type;
        ui.add(numericStepperData);

        ui.add(new FlxUIText(150, 110, 0, "Indices (Advanced):"));
        var indices_input:FlxUIInputText = new FlxUIInputText(150, 127.5, 100, "", 8);
        ui.add(indices_input);
        blockInputWhileTyping.push(indices_input);

        ui.add(new FlxUIText(20, 110, 0, "FPS:"));
        var fps:FlxUINumericStepper = new FlxUINumericStepper(20, 127.5, 1, 24, 0, 60);
        ui.add(fps);
        blockInputWhileTypingOnStepper.push(fps);

        animDropDown = new FunkinDropDownMenu(-155, 57, FunkinDropDownMenu.makeStrIdLabelArray([""]), function(name:String)
        {
            if (meta != null && name.length > 0)
            {
                var i = meta.animations.get(name);
                if (i != null)
                {
                    name_input.text = name;
                    prefix_input.text = i.prefix;
                    note_type.text = i.noteType.noteType;      
                    if (i.noteType.noteType != null && i.noteType.noteType.length > 0)
                        numericStepperData.min = -1;
                    else
                        numericStepperData.min = 0;     
                    numericStepperData.value =  i.noteType.noteData;
                    curAnim = name;
                    fps.value = i.fps;
                    if (i.indices != null && i.indices.length > 0)
                    {
                        indices_input.text = i.indices.toString().substring(1, i.indices.toString().length - 2);
                    }
                    playStrumAnim(curAnim, i.noteType.noteData);
                }
            }
        });

        function setAnimDropDown()
        {
            var anims:Array<String> = [];
            if (meta != null && meta.animations != null)
            {
                for (i in meta.animations.keys())
                {
                    anims.push(i);
                }
            }
            if (anims.length < 1)
            {
                anims.push("");
            }
            if (curAnim == null && anims[0].length > 0)
                curAnim = anims[0];

            animDropDown.setData(FunkinDropDownMenu.makeStrIdLabelArray(anims));
            animDropDown.selectedLabel = curAnim;
        }

        setAnimDropDown();

        addButton = new FlxUIButton(20, 180, "Add/Update", function()
        {       
            var indices:Array<Int> = [];
            if (indices_input.text.split(',').length > 1)
            {
                for (i in indices_input.text.split(','))
                {
                    var index:Null<Int> = Std.parseInt(i);
                    if (!Math.isNaN(index) && index != null)
                    {
                        indices.push(index);
                    }
                }
            }

            meta = NoteSplash.addAnimationToMeta([scaleXNumericStepper.value, scaleYNumericStepper.value], meta, name_input.text, prefix_input.text, cast fps.value, [0, 0,], indices, note_type.text, cast numericStepperData.value);
            curAnim = name_input.text;
            playStrumAnim(curAnim, cast numericStepperData.value);
            setAnimDropDown();

            if (errorText.alpha == 1)
            {
                meta.animations.remove(curAnim);
                curAnim = null;
                setAnimDropDown();
            }
            //if (animDropDown.list)
        }); 
        ui.add(addButton);

        var removeButton:FlxUIButton = new FlxUIButton(180, 180, "Remove", function()
        {
            if (meta != null)
            {
                if (meta.animations.exists(curAnim))
                { 
                    meta.animations.remove(curAnim);

                    curAnim = null;
                    name_input.text = "";
                    prefix_input.text = "";
                    note_type.text = "";   
                    indices_input.text = "";
                    fps.value = 24;        
                    numericStepperData.value = 0;
                    setAnimDropDown();
                }
            }
        });
        ui.add(removeButton);

        ui.add(animDropDown);
        UI.addGroup(ui);
        UI.scrollFactor.set();

        reloadImage = function()
        {
            splashes.clear();

            var image = Paths.image(defaultSkin);
            if (image == null)
            {
                errorText.alpha = 1;
                FlxTween.cancelTweensOf(errorText);
                FlxTween.tween(errorText, {alpha: 0}, {startDelay: .9});
                
                return;
            }

            splash = new NoteSplash(defaultSkin);
            if (splash.meta != null)
                meta = splash.meta;
            else
                meta = null;

            curAnim = null;
            name_input.text = "";
            prefix_input.text = "";
            note_type.text = "";         
            indices_input.text = "";  
            numericStepperData.value = 0;
            fps.value = 24;
            setAnimDropDown();
        }
    }

    var noteImageInputText:FlxUIInputText;
    var imageInputText:FlxUIInputText;
    var scaleXNumericStepper:FlxUINumericStepper;
    var scaleYNumericStepper:FlxUINumericStepper;
    function addProperitiesTab()
    {
        var ui:FlxUI = new FlxUI(null, properUI);
        ui.name = "Properities";

        ui.add(new FlxUIText(20, 10, 0, "Image:"));
        imageInputText = new FlxUIInputText(60, 10, 120, defaultSkin, 8);
        ui.add(imageInputText);
        blockInputWhileTyping.push(imageInputText);

        var reloadButton:FlxUIButton = new FlxUIButton(185, 6.8, "Reload Image", function()
        {
            reloadImage();
        });
        ui.add(reloadButton);

        ui.add(new FlxUIText(20, 40, "Scale X / Y:"));
        scaleXNumericStepper = new FlxUINumericStepper(20, 57.5, .025, 1, 0, 2, 3, new FlxUIInputText(0, 0, 35));
        ui.add(scaleXNumericStepper);
        blockInputWhileTypingOnStepper.push(scaleXNumericStepper);

        scaleYNumericStepper = new FlxUINumericStepper(20, 75, .025, 1, 0, 2, 3, new FlxUIInputText(0, 0, 35));
        ui.add(scaleYNumericStepper);
        blockInputWhileTypingOnStepper.push(scaleYNumericStepper);

        ui.add(new FlxUIText(130, 40, "Animations:"));

        var saveButton:FlxUIButton = new FlxUIButton(30, 150, "Save", function()
        {
            saveSplash();
        });
        ui.add(saveButton);

        if (meta != null && meta.scale != null)
        {
            scaleXNumericStepper.value = meta.scale[0];
            scaleYNumericStepper.value = meta.scale[1];
        }

        var getsAffectedByShader:FlxUICheckBox = new FlxUICheckBox(20, 110.5, null, null, "Gets Affected By Shader");
        function check()
        {
            if (meta != null)
            {
                meta.affectedByShader = getsAffectedByShader.checked;
            }
        }
        getsAffectedByShader.callback = check;
        getsAffectedByShader.checked = meta != null && cast(meta.affectedByShader, Null<Bool>) != null ? meta.affectedByShader : false;
        ui.add(getsAffectedByShader);
        
        properUI.addGroup(ui);
        properUI.scrollFactor.set();
    }

    var _file:FileReference;
    function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
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
		FlxG.log.error("Problem saving file");
	}

    function saveSplash()
    {
        var meta = {
            scale: meta.scale,
            animations: meta.animations,
            affectedByShader: meta.affectedByShader
        };

        var data:String = Json.stringify(meta, "\t");
        if (data.length > 0)
        {
            _file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, defaultSkin + ".json");
        }
    }

    dynamic function reloadImage()
    {
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUIInputText.CHANGE_EVENT && sender is FlxUIInputText)
        {
            var inputText:FlxUIInputText = cast sender;
            switch inputText.name
            {       
            }
        }
    }

    override function update(elapsed:Float)
    { 
        super.update(elapsed);

        curText.text = 'Current Animation: ${curAnim == null || curAnim.length < 1  ? "NONE" : curAnim}';
        if (meta != null && !curText.text.contains('NONE'))
        {
            var offsets:Array<Int> = try meta.animations.get(curAnim).offsets catch (e) [0, 0];
            curText.text += ' ($offsets)'.coolReplace(',', ', ');
        }

        if (meta != null)
        {
            var currentAnim:String = curAnimText.text;
            if (meta.animations.exists(currentAnim) && meta.animations.get(currentAnim) != null)
            {
                addButton.label.text = 'Update';
            }
            else
            {
                addButton.label.text = 'Add';
            }

            meta.scale[0] = scaleXNumericStepper.value;
            meta.scale[1] = scaleYNumericStepper.value;

            numericStepperData.min = noteImageInputText.text != null && noteImageInputText.text.length > 0 ? -1 : 0;
            curType = noteImageInputText.text;
        }

        defaultSkin = imageInputText.text;
        
        var blockInput:Bool = false;
        for (i in blockInputWhileTyping)
        {
            if (i.hasFocus)
            {
                blockInput = true;
                break;
            }
        }
        for (i in blockInputWhileTypingOnStepper)
        {
            @:privateAccess var text_field:FlxUIInputText = cast i.text_field;
            if (text_field.hasFocus)
            {
                blockInput = true;
                break;
            }
        }

        if (meta != null && meta.animations != null && meta.animations.exists(curAnim) && curAnim != null && curAnim.length > 0)
        {
            function splash()
            {
                if (meta.animations.get(curAnim) != null)
                {
                    playStrumAnim(curAnim, meta.animations.get(curAnim).noteType.noteData);
                    FlxTween.cancelTweensOf(errorText);
                    errorText.alpha = 0;
                }
            }

            var multiplier:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;

            if (FlxG.keys.justPressed.LEFT)
            {
                meta.animations[curAnim].offsets[0] += multiplier;
                splash();
            }
            else if (FlxG.keys.justPressed.RIGHT)
            {
                meta.animations[curAnim].offsets[0] -= multiplier;
                splash();
            }
            else if (FlxG.keys.justPressed.UP)
            {
                meta.animations[curAnim].offsets[1] += multiplier;
                splash();
            }
            else if (FlxG.keys.justPressed.DOWN)
            {
                meta.animations[curAnim].offsets[1] -= multiplier;
                splash();
            }
        }

        if (!blockInput)
        {
            if (controls.BACK)
                MusicBeatState.switchState(new MasterEditorMenu());

            if (FlxG.keys.justPressed.NUMPADPLUS)
            {
                noteData++;
                noteData %= 4;
            }
            else if (FlxG.keys.justPressed.NUMPADMINUS)
            {
                noteData--;
                noteData %= 4;
            }
        }

        if (FlxG.mouse.overlaps(strums))
        {
            strums.forEach(function(strum:BabyArrow)
            {
                if (FlxG.mouse.overlaps(strum))
                {
                    if (!FlxG.mouse.justPressed)
                    {
                        if (strum.animation.curAnim.name != 'pressed' && strum.animation.curAnim.name != 'confirm')
                            strum.playAnim('pressed');
                    }
                    else
                    {
                        strum.playAnim('confirm', true);
                        strum.holdTimer = Math.POSITIVE_INFINITY;

                        var key:String = null;
                        for (i in meta.animations)
                        {
                            if (i.noteType.noteType == currentNoteType.text
                                && (strum.ID == i.noteType.noteData % 4 || i.noteType.noteData < 0))
                                key = i.name;
                        }

                        var splash:NoteSplash = splashes.recycle(NoteSplash);
                        splash.meta = meta;
                        splash.babyArrow = strum;
                        splash.spawnSplashNote(null, strum.ID % 4, null, currentNoteType.text != null && currentNoteType.text.length > 0, key);
                        splashes.add(splash);
                    }
                }
                else
                {
                    strum.playAnim('static');
                }
            });
        }
        else
        {
            for (strum in strums)
                strum.playAnim('static');
        }
    }

    override function destroy()
    {
        super.destroy();

        var FlxG = FlxG.sound;

        FlxG.music.volume = 1;
        FlxG.muteKeys = [FlxKey.ZERO];
	    FlxG.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	    FlxG.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
    }

    function playStrumAnim(?name:String, noteData:Int)
    {
        var splash:NoteSplash = splashes.recycle(NoteSplash);
        splash.meta = meta;
        if (noteData < 0)
            noteData = 0;

        if (name != null && splash.animation.getByName(name) != null && noteData > -1)
        {
            splash.babyArrow = strums.members[noteData % 4];
            splash.spawnSplashNote(null, noteData % 4, name);
            splashes.add(splash);
        }
        else
        {
            splashes.remove(splash);
            errorText.alpha = 1;
            
            FlxTween.cancelTweensOf(errorText);
            FlxTween.tween(errorText, {alpha: 0}, {startDelay: .9});
        }
    }
}