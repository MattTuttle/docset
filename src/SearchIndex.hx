import haxe.rtti.CType;

typedef ClassFieldType = {
	name:String,
	type:String
};

class SearchIndex
{

	public static function generate(root, contents:String)
	{
		db = sys.db.Sqlite.open(contents + "/Resources/docSet.dsidx");
		// drop the table if this database has previously been opened
		db.request("DROP TABLE IF EXISTS searchIndex");
		// create the table
		db.request("CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);");
		// prevent unique keys
		db.request("CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);");

		processPackage("root", root);

		db.close();
	}

	private static function formatPath(path:String)
	{
		if (path.substr(0,7) == "flash8.")
			return "flash."+path.substr(7);
		var pack = path.split(".");
		if (pack.length > 1 && pack[pack.length - 2].charAt(0) == "_")
		{
			pack.splice(-2, 1);
			path = pack.join(".");
		}
		return path;
	}

	private static function processPackage(name, list:Array<TypeTree>)
	{
		for (e in list)
		{
			switch (e)
			{
				case TPackage(name, full, list):
					var isPrivate = name.charAt(0) == "_";
					if (!isPrivate)
					{
						var id = full.split(".").join("_");
						// print('<li><a href="#" class="package" onclick="return toggle(\'$id\')">$name</a><div id="$id" class="package_content">');
					}
					var old = curpackage;
					curpackage = full;
					processPackage(name, list);
					curpackage = old;
				default:
					var i = TypeApi.typeInfos(e);
					if (i.isPrivate || i.path == "@Main")
						continue;

					var p = i.path.split(".");
					var name = p.pop();
					var local = (p.join(".") == curpackage);
					p.push(name);

					name = local ? name : formatPath(i.path);
					var path = p.join("/") + ".html";
					var type = "Class";
					switch (e)
					{
						case TClassdecl(c):
							if (c.isInterface) type = "Interface";
							var data = new Array<ClassFieldType>();
							for (f in c.fields)
							{
								var d = processClassField(f);
								if (d != null) data.push(d);
							}
							for (f in c.statics)
							{
								var d = processClassField(f);
								if (d != null) data.push(d);
							}
							if (data.length > 0)
							{
								var insert:String = null;
								for (d in data)
								{
									var p = path + "#" + d.name;
									var n = name + "." + d.name;
									if (insert == null)
										insert = ' SELECT \'${n}\' AS name, \'${d.type}\' AS type, \'${p}\' AS path';
									else
										insert += ' UNION SELECT \'${n}\', \'${d.type}\', \'${p}\'';
								}
								insert = "INSERT OR IGNORE INTO searchIndex (name, type, path)" + insert;
								db.request(insert);
							}
						case TEnumdecl(en):
							type = "Enum";
						case TTypedecl(t):
							type = "Type";
						case TAbstractdecl(a):
							type = "Type"; // should be Abstract but that's not supported by docset
						default:
					}
					db.request("INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('" + name + "', '" + type + "', '" + path + "');");
			}
		}
	}

	private static function processClassField(f:ClassField):ClassFieldType
	{
		if (!f.isPublic || f.isOverride)
			return null;

		var type = "Variable";
		switch (f.type)
		{
			case CFunction(args,ret):
				type = "Method";
			default:
		}

		return {
			name: f.name,
			type: type
		};
	}

	private static var db:sys.db.Connection;
	private static var curpackage:String;
}