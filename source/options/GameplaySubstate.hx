package options;

class GameplaySubstate extends BaseOptionsSubstate
{
    public function new()
    {
        title = "Gameplay";
        
        var option:Option = new Option('Ghost Tapping', [
            'You won\'t get misses if you press a key\nwhen there are no notes to hit.',
            'You will get misses if you press a key\nwhen there are no notes hit.'
        ], 'ghostTapping');
        addOption(option);

        var option:Option = new Option("Accuracy Decimals:", ["The higher the decimals, the more detailed the accuracy."], "decimals", "int");
        option.decimals = 0;
        option.minValue = 0;
        option.maxValue = 4;
        addOption(option);

        var option:Option = new Option('Downscroll', [
            'Your strumline will be shown at the bottom.',
            'Your strumline will be shown at the top.'
        ], 'downScroll');
        addOption(option);

        var option:Option = new Option('Middlescroll', ['Your strumline will get centered.', 'Your strumline won\'t get centered.'], 'middleScroll');
        addOption(option);

        var option:Option = new Option('Hitsound Volume:', ['Sets your hitsound volume,\nit will be played when you hit a note.'], 'hitSounds', 'float');
        option.scrollSpeed = 1.6;
        option.minValue = 0.0;
        option.maxValue = 1;
        option.changeValue = 0.1;
        option.decimals = 1;
        addOption(option);

        var option:Option = new Option('Responsiveness:', ['This option sets your input\'s responsiveness.'], 'mult', 'float');
        option.scrollSpeed = 2;
        option.minValue = .25;
        option.maxValue = 1.5;
        option.changeValue = .05;
        option.decimals = 2;
        addOption(option);

        super();
    }
}