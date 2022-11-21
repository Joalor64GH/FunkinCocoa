package options;

class TypedOptionsSubstate extends BaseOptionsSubstate
{
    var state:FunkinScript;
    public function new(script:String)
    {
        state = cast new FunkinScript().doString(sys.io.File.getContent(script));
        state.set('Option', Option);
        state.set('add', function(b) add(b));
        state.set('addOption', function(option:Option)
        {
            addOption(option);
        });
        state.set('title', title);
        //state.set('rpcTitle', rpcTitle);
        state.call('create', []);
        super(); //place where the super is called matters!!!
        state.call('createPost', []);
    }

    override function update(elapsed:Float) 
    {
        super.update(elapsed);

        state.set('curOption', curOption);
        state.call('update', [elapsed]);
    }
}