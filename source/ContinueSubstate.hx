package;

import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class ContinueSubstate extends MusicBeatSubstate
{
    var song:String;
    var diff:Int;
    var list:Array<String>;
    var storyWeek:Int;
    var startFromOverList:Array<String>;

    var yes:Alphabet;
    var no:Alphabet;

    var onYes:Bool;

    public function new(song:String, diff:Int, list:Array<String>, storyWeek:Int, startFromOverList:Array<String>)
    {
        super();

        this.song = song;
        this.diff = diff;
        this.list = list;
        this.storyWeek = storyWeek;
        this.startFromOverList = startFromOverList;

        var bg:FlxSprite = cast new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK).screenCenter();
        bg.alpha = 0;
        add(bg);

        FlxTween.tween(bg, {alpha: 0.6}, 0.6, {ease: FlxEase.expoInOut});

        var text:Alphabet = new Alphabet(0, 180, 'Continue from song:', true);
        text.screenCenter(X);
        add(text);
        
        var text:Alphabet = new Alphabet(0, text.y + 90, '$song?', true);
        text.screenCenter(X);
        add(text);

        yes = new Alphabet(0, text.y + 175, "Yes", true);
        yes.screenCenter(X);
        yes.x -= 300;
        add(yes);

        no = new Alphabet(0, text.y + 175, FlxG.random.bool(.5) ? "You suck!" : "Start Over", true);
        no.screenCenter(X);
        no.x += 300;
        add(no);

        updateOpt();
    }

    var updateTimer:FlxTimer;
    var canUpdate:Bool;
    override function update(elapsed:Float)
    {
        if (!canUpdate)
        {
            if (updateTimer == null)
            {
                updateTimer = new FlxTimer();
                updateTimer.start(0.5, function(tmr:FlxTimer)
                {
                    canUpdate = true;
                    updateTimer.destroy();
                    updateTimer = null;
                });
            }
            return;
        }

        super.update(elapsed);

        if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
        {
            onYes = !onYes;
            updateOpt();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        if (controls.ACCEPT)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            PlayState.isStoryMode = true;
            PlayState.storyPlaylist = onYes ? list : startFromOverList;
            PlayState.storyPlayListOld = startFromOverList.copy();
            PlayState.storyDifficulty = diff;
            PlayState.storyWeek = storyWeek;
            PlayState.SONG = Song.loadFromJson(onYes ? song : startFromOverList[0], diff);
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;

            FlxFlicker.flicker(onYes ? yes : no, .9, .06, true, false, function(flicker:FlxFlicker)
            {
                MusicBeatState.switchState(new PlayState());
            });
        }
        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
        }
    }

    function updateOpt()
    {
        if (onYes)
        {
            yes.scale.set(1.1, 1.1);
            yes.alpha = 1;
            no.scale.set(1, 1);
            no.alpha = 0.6;
        }
        else
        {
            no.scale.set(1.1, 1.1);
            no.alpha = 1;
            yes.scale.set(1, 1);
            yes.alpha = 0.6;
        }
    }
}