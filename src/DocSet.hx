import sys.io.File;
import sys.FileSystem;

class DocSet
{
	public static function main()
	{
		var doc = new DocSet(),
			arguments = Sys.args(),
			docName:String = null,
			xmlFile:String = "haxedoc.xml",
			template:String = "template.xml",
			iconFile:String = null;

		haxelibPath = Sys.getCwd(); // get original path
		if (arguments.length > 0)
		{
			var path = arguments.pop();
			if (FileSystem.exists(path) && FileSystem.isDirectory(path))
			{
				Sys.setCwd(path);
			}
		}

		var opt = new OptionArg(arguments);
		opt.set("i", "icon.svg");
		opt.set("f", "filter");
		opt.set("t", "template.xml");
		opt.set("x", "haxedoc.xml");

		try
		{
			if (arguments.length == 0)
			{
				throw "Expected arguments to be passed";
			}

			while (opt.get())
			{
				switch (opt.flag)
				{
					case "x": xmlFile = opt.arg;
					case "t": template = opt.arg;
					case "i": iconFile = opt.arg;
					case "f": doc.html.addFilter(opt.arg);
					 default: docName = opt.flag;
				}
			}

			if (docName == null)
			{
				throw "Must specify the docset name";
			}
		}
		catch (e:String)
		{
			neko.Lib.println(e);
			neko.Lib.println('USAGE: docset $opt ProjectName');
			return;
		}

		doc.generate(docName, xmlFile, template);

		if (iconFile != null)
		{
			File.saveBytes(docName + ".docset/icon.png", Icon.fromSvg(iconFile));
		}
	}

	public function new()
	{
		html = new Printer(haxelibPath);
	}

	public function generate(docName:String, file:String, template:String)
	{
		var docset = docName + ".docset/";
		var contents = docset + "Contents/";

		if (!FileSystem.exists(file))
		{
			neko.Lib.println("Could not find " + file);
			return;
		}

		html.setTemplate(template);
		html.run(file, contents);

		createPlist(docName, contents);
	}

	private function createPlist(docName:String, contents:String)
	{
		var docId = docName.toLowerCase();
		var plist = sys.io.File.write(contents + "Info.plist");
		plist.writeString('<?xml version="1.0" encoding="UTF-8"?>\n');
		plist.writeString('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n');
		plist.writeString('<plist version="1.0">\n');
		plist.writeString('<dict>\n');
		plist.writeString('	<key>CFBundleIdentifier</key>\n');
		plist.writeString('	<string>$docId</string>\n');
		plist.writeString('	<key>CFBundleName</key>\n');
		plist.writeString('	<string>$docName</string>\n');
		plist.writeString('	<key>DocSetPlatformFamily</key>\n');
		plist.writeString('	<string>$docId</string>\n');
		plist.writeString('	<key>dashIndexFilePath</key>\n');
		plist.writeString('	<string>index.html</string>\n');
		plist.writeString('	<key>isDashDocset</key>\n');
		plist.writeString('	<true/>\n');
		plist.writeString('</dict>\n');
		plist.writeString('</plist>\n');
	}

	private var html:Printer;

	private static var haxelibPath:String;
}
