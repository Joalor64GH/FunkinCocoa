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
        

        var option:Option = new Option('Score Text Tween', [
            'Score text will tween when you hit a note.',
            'Score text will stay static when you hit a note.'
        ], 'scoreTween');
        addOption(option);

        var option:Option = new Option('Show Time Text', [
            'The text showing your preferred time style will be shown.',
            'The text showing your preferred time style won\'t be shown.'
        ], 'timeLeft');
            addOption(option);

        var option:Option = new Option('Time Bar Style:', // option name
            ["Text will show how much time left or elapsed\nbased on your decision."],
            // single description
            'timeStyle', // variable name in FunkySettings.hx
            'string', // string
            ['Time Left', 'Time Elapsed'] // available options
        );
        addOption(option);

        var option:Option = new Option('Hide HUD', [
            "HUD will be hidden (doesn't include the time text).",
            'HUD will be shown (doesn\'t include the time text).'
        ], 'hideHud');
        addOption(option);

        var option:Option = new Option('Hide Opponent Strums', [
            'Opponent\'s strums will be hidden.',
            'Opponent\'s strums will be shown.',
        ], 'hideOpponent');
        addOption(option);

        super();
    }
}