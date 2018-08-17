import std.file;
import arsd.dom;
import std.path;
import std.json;
import std.stdio;
import std.array;
import std.string;
import std.algorithm;

private enum Type
{
	Manual,
	ScriptReference
}

void main ()
{
	DirIterator manualDir = dirEntries ("Documentation/Manual", SpanMode.shallow);
	DirIterator scriptDir = dirEntries ("Documentation/ScriptReference", SpanMode.shallow);
	File manualFile = File ("manual.json", "w");
	File scriptFile = File ("script.json", "w");
	string manualLink = "https://docs.unity3d.com/Manual/";
	string scriptLink = "https://docs.unity3d.com/ScriptReference/";

	JSONValue manual = generate (manualDir, manualLink, Type.Manual);
	JSONValue scriptReference = generate (scriptDir, scriptLink, Type.ScriptReference);

	manualFile.writeln (manual.toString);
	scriptFile.writeln (scriptReference.toString);
}

private JSONValue generate (DirIterator dir, string baseLink, Type type)
{
	JSONValue res;
	JSONValue [] entries;
	foreach (DirEntry m; dir)
	{
		string contents = cast (string) read (m.name);
		Document doc = new Document (contents);
		if (doc.title.length <= 14)
			continue;

		const string link = format ("%s%s", baseLink, baseName (m.name));
		string title = "";

		final switch (type)
		{
			case Type.Manual:
				title = stripLeft (doc.title [16..$]);
				break;
			case Type.ScriptReference:
				title = stripLeft (doc.title [23..$]);
				break;
		}

		string fullDescription = "";
		if (type == Type.Manual)
		{
			fullDescription = doc.getElementsByTagName ("p") [0].innerText;
		}
		else if (type == Type.ScriptReference)
		{
			auto h2 = doc.getElementsByTagName ("h2");

			foreach (h; h2)
			{
				if (h.innerText == "Description")
				{
					fullDescription = h.parentNode.childNodes [3].innerText;
					break;
				}
			}
		}

		const long indexOfDot = indexOf (fullDescription, '.') + 1;
		string description = "";
		if (indexOfDot >= 1)
			description = fullDescription [0..indexOfDot];
		else
			description = fullDescription;

		JSONValue json = [ "link": link ];
		json.object ["title"] = JSONValue (title);
		json.object ["description"] = JSONValue (description);

		entries ~= json;
	}

	res = entries;
	return res;
}