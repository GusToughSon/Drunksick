module mapsync;

import commondata;

//const URL = "http://localhost/dransik/mapsync.php";
const URL = "http://thecybershadow.net/dransik/mapsync.php5";

private:
uint checksum(ushort[] data)
{
	uint sum = 0;
	foreach(i,el;data)
	{
		sum ^= ((cast(uint)el) * i);
	}
	return sum;
}

import tango.net.http.HttpGet;
import tango.net.http.HttpPost;
import tango.core.Thread;
import tango.text.convert.Integer;
import tango.time.TimeSpan;

uint[8] lastCheckSum;
ushort[256][256][8] data;

void doMapUpdate()
{
	static bool updateInProgress;
	if(updateInProgress) return;
	updateInProgress = true;
	scope(exit) updateInProgress = false;
	
	for(int nr=0;nr<8;nr++)
		try
		{
			if(maps.maps[nr].data1 is null) continue;
			assert(maps.maps[nr].width  == 256);
			assert(maps.maps[nr].height == 256);
			for(int y=0;y<256;y++)
				for(int x=0;x<256;x++)
					data[nr][y][x] = getChunk(nr, x, y);
		
			void[] response;
			auto dataArr = cast(ushort[])data[nr];
			uint newChecksum = checksum(dataArr);

			if(newChecksum == lastCheckSum[nr] || lastCheckSum[nr]==0)   // get new info only
			{
				Stdout.format("MapSync: Requesting data on map {}", nr).newline;
				auto page = new HttpGet (URL ~ "?map=" ~ .toString(nr) ~ "&checksum=" ~ .toString(newChecksum));
				page.setTimeout(TimeSpan.seconds(15));
				response = page.read();
			}
			else
			{
				Stdout.format("MapSync: Exchanging data on map {}", nr).newline;
				auto page = new HttpPost(URL ~ "?map=" ~ .toString(nr) ~ "&checksum=" ~ .toString(newChecksum));
				page.setTimeout(TimeSpan.seconds(15));
				response = page.write(dataArr, "application/x-dransik-map");
			}
			lastCheckSum[nr] = newChecksum;
		
			if(response.length==0)
			{
				Stdout.format("MapSync: No new data received").newline;
			}
			else
			if(response.length==dataArr.length*2)
			{
				auto newDataArr = cast(ushort[])response;
				int n = 0;
				for(int i=0;i<dataArr.length;i++)
					if(newDataArr[i] != dataArr[i] && newDataArr[i] != 0)
					{
						if(dataArr[i] != 0) Stdout.format("MapSync: Warning: changing occupied tile at {}x{} from {} to {}", i & 0xFF, i >> 8, dataArr[i], newDataArr[i]).newline;
						setChunk(nr, i & 0xFF, i >> 8, newDataArr[i]);
						n++;
					}
				lastCheckSum[nr] = checksum(newDataArr);
				Stdout.format("MapSync: {} new tiles for map {} received", n, nr).newline;
			}
			else
			{
				Stdout.format("MapSync: Unexpected response: {}", cast(char[]) response).newline;
			}
		}
		catch(Object o)
		{
			Stdout.format("MapSync exception on map {}: {}", nr, o.toString()).newline;
		}
	//Stdout("doMapUpdate done").newline;
}

public void beginMapUpdate()
{
	auto thread = new Thread(&doMapUpdate);
	thread.start();
	Sleep(5);
}
