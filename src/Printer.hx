import haxe.rtti.CType;
import sys.FileSystem;
import tools.haxedoc.HtmlPrinter;

class Printer extends HtmlPrinter
{

	public function new(haxelib:String)
	{
		super("", ".html", "index");
		haxelibPath = haxelib;
	}

	public function setTemplate(template:String)
	{
		// try local and then haxelib for template file
		var paths = [Sys.getCwd() + template, haxelibPath + "template.xml"];
		for (path in paths)
		{
			if (FileSystem.exists(path))
			{
				var content = sys.io.File.getContent(path);
				HtmlPrinter.template = Xml.parse(content);
				break;
			}
		}
	}

	public function run(file:String, contents:String)
	{
		var documents = contents + "Resources/Documents/";
		createDirectory(documents);

		var parser = loadFile(file);
		parser.sort();

		SearchIndex.generate(parser.root, contents, this);

		save(TPackage("root", "root", parser.root), documents + "index.html");
		for (e in parser.root)
		{
			generateEntry(e, documents);
		}
	}

	private inline function createDirectory(dir:String)
	{
		try FileSystem.createDirectory(dir) catch (e:Dynamic) { }
	}

	private inline function save(x, file)
	{
		var f = sys.io.File.write(file, true);
		output = f.writeString;
		process(x);
		f.close();
	}

	private function generateEntry(e, path)
	{
		switch (e)
		{
			case TPackage(name, full, entries):
				if (filtered(full, true))
					return;
				var old = baseUrl;
				baseUrl = "../" + baseUrl;
				path += name + "/";
				createDirectory(path);
				for (e in entries)
					generateEntry(e, path);
				baseUrl = old;
			default:
				var inf = TypeApi.typeInfos(e);
				if (filtered(inf.path, false))
					return;
				var pack = inf.path.split(".");
				var name = pack.pop();
				save(e, path + name + ".html");
		}
	}

	private function loadFile(file, ?platform, ?remap)
	{
		var parser = new haxe.rtti.XmlParser();
		var data = sys.io.File.getContent(Sys.getCwd() + file);
		var x = Xml.parse(data).firstElement();
		if (remap != null)
			transformPackage(x, remap, platform);
		parser.process(x, platform);
		return parser;
	}

	private function transformPackage(x:Xml, remap, platform)
	{
		switch (x.nodeType)
		{
			case Xml.Element:
				var p = x.get("path");
				if (p != null && p.substr(0,6) == remap + ".")
					x.set("path", platform + "." + p.substr(6));
				for (x in x.elements())
					transformPackage(x, remap, platform);
			default:
		}
	}

	/**
	 * Overriding to add id value to <dt>
	 */
	override function processClassField(platforms : Platforms,f : ClassField,stat) {
		if( !f.isPublic || f.isOverride )
			return;
		var oldParams = typeParams;
		if( f.params != null )
			typeParams = typeParams.concat(prefix(f.params,f.name));
		print('<dt id="${f.name}">');
		if( stat ) keyword("static");
		var isMethod = false;
		var isInline = (f.get == RInline && f.set == RNo);
		switch( f.type ) {
		case CFunction(args,ret):
			if( (f.get == RNormal && (f.set == RMethod || f.set == RDynamic)) || isInline ) {
				isMethod = true;
				if( f.set == RDynamic )
					keyword("dynamic");
				if( isInline )
					keyword("inline");
				keyword("function");
				print(f.name);
				if( f.params != null )
					print("&lt;"+f.params.join(", ")+"&gt;");
				print("(");
				display(args,function(a) {
					if( a.opt )
						print("?");
					if( a.name != null && a.name != "" ) {
						print(a.name);
						print(" : ");
					}
					processType(a.t);
				},", ");
				print(") : ");
				processType(ret);
			}
		default:
		}
		if( !isMethod ) {
			if( isInline )
				keyword("inline");
			keyword("var");
			print(f.name);
			if( !isInline && (f.get != RNormal || f.set != RNormal) )
				print("("+rightsStr(f,true,f.get)+","+rightsStr(f,false,f.set)+")");
			print(" : ");
			processType(f.type);
		}
		if( f.platforms.length != platforms.length && f.platforms.length > 0 ) {
			print('<div class="platforms">Available in ');
			display(f.platforms,output,", ");
			print('</div>');
		}
		print('</dt>');
		print('<dd>');
		processDoc(f.doc);
		print('</dd>');
		if( f.params != null )
			typeParams = oldParams;
	}

	private var haxelibPath:String;

}
