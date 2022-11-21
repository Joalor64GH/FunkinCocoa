package options;

import flixel.addons.ui.FlxUIText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class UISubstate extends BaseOptionsSubstate
{
    var splashOption:Option;
    var splashText:FlxUIText;
    var noteData:Int;

    public function new()
    {
        title = 'Visuals and UI';

        var option:Option = new Option('Splash Opacity:', // option name
            ["This option sets the opacity for the firework effect.\n0 means effect will be unvisible."], 'splashOpacity', 'float'); // variable name FunkySettings.hx
        option.scrollSpeed = 1.2;
        option.minValue = .0;
        option.maxValue = 1;
        option.changeValue = .1;
        addOption(option);

        var option:Option = new Option('Strum Opacity:',
            ["This options sets the opacities of strum notes.\nOpacity will be applied to both player and opponent."], "strumOpacity", 'float'
        );
        option.scrollSpeed = 1;
        option.minValue = .4;
        option.maxValue = 1;
        option.changeValue = .05;
        option.decimals = 2;
        addOption(option);
        
        var option:Option = new Option('Show FPS Counter', [ // option name
            "A little FPS and memory counter will be shown on the top left.",
            // desc when this option is enabled
            "FPS and memory counter will stay hidden."
            // desc when this option is disabled
        ], 'showFPS');
        option.onChange = setFPSVisibility;
        addOption(option);

        var option:Option = new Option('Score Text Tween', [
            'Score text will tween when you hit a note.',
            'Score text will stay static when you hit a note.'
        ], 'scoreTween');
        addOption(option);

        var option:Option = new Option('Show Time Bar', [
            'The bar showing your preferred time style will be shown.',
            'The bar showing your preferred time style won\'t be shown.'
        ], 'timeLeft');
            addOption(option);

        var option:Option = new Option('Screen-sized Time Bar', [
            "Your time bar will be at bottom\nand screen-sized.",
            "Your time bar will not screen sized\nand will be at top or bottom based on your choice.",
        ], 'longTimeBar');
        addOption(option);

        var option:Option = new Option('Time Bar Style:', // option name
            ["Bar will show how much time left or elapsed\nbased on your decision."],
            // single description
            'timeStyle', // variable name in FunkySettings.hx
            'string', // string
            ['Time Left', 'Time Elapsed'] // available options
        );
        addOption(option);

        var option:Option = new Option('Hide HUD', [
            "HUD will be hidden (doesn't include the time bar).",
            'HUD will be shown (doesn\'t include the time bar).'
        ], 'hideHud');
        addOption(option);

        var option:Option = new Option('Sustain Notes Style:', [
            'Sustain notes will be put behind the strums.', // Stepmania
            'Sustain notes will be put in front of the strums.', // Classic (Funkin)
            'Sustain notes will be attached to notes. Opacity is not reduced.',
        ], 'sustainStyle', 'string', ['Stepmania', 'Funkin', 'Cocoa',], true);
        addOption(option);

        var option:Option = new Option('Hide Opponent Strums', [
            'Opponent\'s strums will be hidden.',
            'Opponent\'s strums will be shown.',
        ], 'hideOpponent');
        addOption(option);

        var option:Option = new Option("Default Splash:", [
            "Select your firework effect that will be used\nwhen a custom one isn't found in a song."
        ], 'splashSkin', 'string', ['Splash 1', 'Splash 2']);
        option.specialOption = true;
        splashOption = option;
        var options:Array<String> = [];
        for (i in option.options)
        {
            options.push(convertSplashes(i, true));
        }
        option.curOption = options.indexOf(FunkySettings.splashSkin);
        addOption(option);

        super();

        splashText = new FlxUIText(FlxG.width - 30, FlxG.height - 30);
        splashText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        splashText.visible = false;
        splashText.borderSize = 1.25;
        splashText.scrollFactor.set();
        splashText.x = FlxG.width - splashText.width - 300;
        splashText.y = FlxG.height - splashText.height - 10;
        splashText.text = "Press ENTER to preview.\nPress SHIFT to change animation.";
        add(splashText);
    }
    
    function convertSplashes(splash:String, ?otherWay:Bool = false):String
    {
        return if (otherWay) switch (splash)
        {
            case 'Splash 1': 'AllnoteSplashes';
            case 'Splash 2': 'noteSplashes' ;
            default: 'AllnoteSplashes';
        } else switch (splash)
        {
            case 'AllnoteSplashes': 'Splash 1';
            case 'noteSplashes': 'Splash 2';
            default: 'Custom';
        }
    }    

    function setFPSVisibility():Void
    {
        Main.FPS.visible = FunkySettings.showFPS;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        splashText.visible = curOption == splashOption;

        if (FlxG.keys.justPressed.SHIFT)
            noteData++;

        if (curOption == splashOption)
        {
            curOption.text = convertSplashes(FunkySettings.splashSkin);
            FunkySettings.splashSkin = convertSplashes(curOption.options[curOption.curOption], true);
            FunkySettings.save();

            var alphabet:Alphabet = grpOptions.members[curSelected];
            if (FlxG.keys.justPressed.ENTER)
            {
                var splash = new NoteSplash();
                add(splash);
                splash.scrollFactor.set();
                splash.setPosition(alphabet.x + 100, alphabet.y);
                splash.alpha = .999;
                if (splash.meta != null && splash.meta.menuOffsets != null)
                {
                    try splash.offset.set(splash.meta.menuOffsets[noteData % 4][0], splash.meta.menuOffsets[noteData % 4][1])
                    catch(e) {}
                }
                splash.spawnSplashNote(null, noteData, false);
            }
        }
    }
}