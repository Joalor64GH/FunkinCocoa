var newFlxSave:FlxSave = new FlxSave();

if (!newFlxSave.bind('tutorials'))
    throw 'Failed to connect to data.';

if (newFlxSave.data.firstLaunch == null)
{
    newFlxSave.data.firstLaunch = true;
    newFlxSave.flush();
}

function onCreatePost() 
{
    if (PlayState.leftSide)
        game.cpuStrums.forEach(addTexts);
    else
        game.playerStrums.forEach(addTexts);
}

function addTexts(spr)
{
    if (!newFlxSave.data.firstLaunch)
        return;

    var array = FunkySettings.controls.copy();
    var key:String = array[["NOTE_LEFT", "NOTE_DOWN", "NOTE_UP", "NOTE_RIGHT"][spr.ID]][0];
    key = InputFormatter.getKeyName(key);
    
    var text:FlxText = new FlxText(spr.x + 35 + spr.ID * 2, spr.y - 1000);
    text.setFormat(Paths.font("vcr.ttf"), 32, getColorFromRGB(255, 255, 255), null, FlxTextBorderStyle.OUTLINE, getColorFromRGB(0, 0, 0));
    text.borderSize *= 1.25;
    text.borderQuality *= 1.25;
    text.cameras = [game.camHUD];
    text.text = key;
    game.add(text);

    FlxTween.tween(text, {y: spr.y + 130}, 4.1, {ease: FlxEase.expoInOut, onComplete: function(twn:FlxTween)
    {
        new FlxTimer().start(11, function(tmr:FlxTimer)
        {
            FlxTween.tween(text, {y: text.y - FlxG.height}, 3, {ease: FlxEase.expoInOut});
        });
    }});
}