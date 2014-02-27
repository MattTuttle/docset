using StringTools;

class OptionArg
{

	public var flag(default, null):String;
	public var arg(default, null):String;

	public function new(?args:Array<String>)
	{
		_argMap = new Map<String, String>();
		if (args == null)
		{
			_args = Sys.args();
		}
		else
		{
			_args = args;
		}
	}

	public function set(flag:String, ?helpText:String)
	{
		_argMap.set(flag, helpText);
	}

	public function get():Bool
	{
		if (_args.length == 0) return false;

		flag = _args.shift();
		arg = null;

		if (flag.startsWith("-"))
		{
			flag = flag.replace("-", "");
			if (_argMap.exists(flag) && _argMap.get(flag) != null)
			{
				if (_args.length > 0)
				{
					arg = _args.shift();
				}
				else
				{
					throw "Expected argument for flag " + flag;
				}
			}
		}
		return true;
	}

	public function toString():String
	{
		var values = new Array<String>();
		for (key in _argMap.keys())
		{
			var value = _argMap.get(key);
			values.push('[-$key $value]');
		}
		return values.join(" ");
	}

	private var _args:Array<String>;
	private var _argMap:Map<String, String>;
}