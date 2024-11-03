module logging;

import tango.io.Stdout;
import tango.io.Console;
import tango.io.model.IConduit;
import tango.io.FileConduit;
import tango.time.WallClock;
import tango.text.Util;
import utils;
import gametime;

class Logger : OutputStream
{
	static private OutputStream next;
	static private FileConduit file;
	static private char[] buf;
	
	this(OutputStream next)
	{
		this.next = next;

		with(FilePath(myPath ~ "logs"))
			if(!exists)
				createFolder();
		auto date = WallClock.toDate;
		FileConduit.Style style = {FileConduit.Access.Write, FileConduit.Open.Append, FileConduit.Share.ReadWrite, FileConduit.Cache.Stream};
		file = new FileConduit(formatter(myPath~"logs\\{}-{:d2}-{:d2}.log", date.year, date.month, date.day), style);
		file.write("-----------------------------------------------------------------------------------------------------------------------------\r\n");
	}

	uint write(void[] src)
	{
		uint result = next.write(src);
		buf ~= cast(char[])src;
		while(buf.containsPattern("\r\n"))
		{
			int e = buf.locatePattern("\r\n")+2;
			auto date = WallClock.toDate;
			file.write(formatter("[{:d2}:{:d2}:{:d2}.{:d3}] {{{}} {}", date.hour, date.min, date.sec, date.ms, getTimeString(), buf[0..e]));
			buf = buf[e..$];
		}
		return result;
	}

	OutputStream copy(InputStream src)
	{
		throw new Exception("Not implemented");
	}

	OutputStream flush()
	{
		file.flush();
		return next.flush();
	}

	IConduit conduit()
	{
		return next.conduit;
	}
	
	void close()
	{
		//try file.close(); catch {}
		//try next.close(); catch {}
	}
}

import tango.io.Print;
import tango.text.convert.Layout;

private Layout!(char) layout;
private Logger logger;

static this()
{
	layout = new Layout!(char);
	logger = new Logger(Cout.stream);
	Stdout = new Print!(char) (layout, logger);
}

//static ~this()
//{
	//Stdout.close();
	//logger.file.close();
//}
