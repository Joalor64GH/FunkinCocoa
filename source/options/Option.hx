package options;

using StringTools;

class Option
{
	var child:Alphabet;

	public var text(get, set):String;

	public var onChange:Void->Void; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; // bool, int (or integer), float (or fl), percent, string (or str)

	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	var variable:String; // Variable name from FunkySettings.hx

	public var defaultValue:Dynamic = 'null variable value';

	public var curOption:Int = 0;
	public var options:Array<Dynamic>; // Only used in string and dynamic type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic; // Only used in int/float/percent type
	public var maxValue:Dynamic; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type
	public var changeDescIfString:Bool; // if this is true and option type is string desc will change based on current option

	// Check UISubstate.hx's Sustain Style option for example usage.
	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:Array<String> = [];
	// First desc will be shown when the option is enabled, second is the opposite (second is optional)
	// Put only one desc if the type is not bool or string
	public var name:String = 'Unknown';

	public var specialOption:Bool;

	public function new(name:String, description:Array<String>, variable:String, type:String = 'bool', ?options:Array<Dynamic>,
			?changeDescIfString:Bool = false)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.options = options;
		this.changeDescIfString = changeDescIfString;

		if (defaultValue == 'null variable value')
		{
			if (getValue() != null)
			{
				defaultValue = getValue();
			}
			else
				switch (type)
				{
					case 'bool':
						defaultValue = false;
					case 'int' | 'float':
						defaultValue = 0;
					case 'percent':
						defaultValue = 1;
					case 'string':
						defaultValue = '';

						if (options.length > 0)
							defaultValue = options[0];
					case 'dynamic':
						defaultValue = null;
				}
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case 'string' | 'dynamic':
				var num:Int = options.indexOf(getValue());
				if (num > -1)
					curOption = num;

			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		// nothing lol
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
	{
		return Reflect.getProperty(FunkySettings, variable);
	}

	public function setValue(value:Dynamic)
	{
		if (specialOption)
			return;
		
		Reflect.setProperty(FunkySettings, variable, value);
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	public function setOption(curOption:Int)
	{
		return this.curOption = curOption;
	}

	function get_text()
	{
		if (child != null)
		{
			return child.text;
		}

		return null;
	}

	function set_text(newValue:String = '')
	{
		if (child != null)
		{
			child.changeText(newValue);
		}

		return null;
	}

	function get_type()
	{
		var newValue:String = 'bool';

		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string':
				newValue = type;
			case 'integer':
				newValue = 'int';
			case 'str':
				newValue = 'string';
			case 'fl':
				newValue = 'float';
			case 'dynamic' | 'any':
				newValue = 'dynamic';
		}

		return type = newValue;
	}
}
