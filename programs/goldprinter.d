module programs.goldprinter;

import dranscript;
import dfl.all;
import tango.sys.win32.UserGdi;
import pathfinder; // isSolid
import programs.pfhelper;
import mainui; // disable autograbber

class GoldPrinter : Program
{
	bool[] image;
	int width, height;	

	override void initialize()
	{
		if(mainForm.cbAutoGrabber.checked)
		{
			Stdout("[GoldPrinter] Disabling AutoGrabber").newline;
			mainForm.cbAutoGrabber.checked = false;
		}
	}
	
	override void execute()
	{
		
		if(image is null)
			throw new Exception("No image set! Press [...] and select a black & white image.\nDraw the pattern white-on-black, one pixel being one map tile.\nAfter that, stand in the upper-left corner of where you want the image and then click [Start].");
		
		for(int y=0;y<height;y++)
			for(int x=0;x<width;x++)
				if(isSolid(myMap, myX+x, myY+y) && image[y*width+x])
					throw new Exception(formatter("Tile at {}x{} (image pixel {}x{}) is solid, can't draw there!", myX+x, myY+y, x, y));

		auto pixels = image.dup;
		int pixelsTotal, pixelsRemaining;
		int ox=myX, oy=myY;
		
		foreach(pixel;pixels)
			if(pixel)
				pixelsTotal++;
		pixelsRemaining = pixelsTotal;

		int validator(int sx, int sy)
		{
			int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
			int ix=gx-ox, iy=gy-oy;
			if(ix>=0 && ix<width && iy>=0 && iy<height &&
				pixels[iy*width+ix] &&
			    mobMap[sx][sy] is null)
				return 100;
			else
				return 0;
		}

	mainloop:		
		do 
		{
			Stdout.format("[GoldPrinter] Now at {}x{}", myX, myY).newline;
			wait();
			for(int dx=-1;dx<=1;dx++)
				for(int dy=-1;dy<=1;dy++)
					if(dx!=0 || dy!=0)
					{
						int gx=myX+dx, gy=myY+dy;
						int ix=gx-ox, iy=gy-oy;
						if(ix>=0 && ix<width && iy>=0 && iy<height &&
							pixels[iy*width+ix] &&
							mobMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy] is null)
						{
							Stdout.format("[GoldPrinter] Dropping gold at {}x{} ({}/{})", gx, gy, pixelsTotal-pixelsRemaining+1, pixelsTotal).newline;
							pixels[iy*width+ix] = false;
							pixelsRemaining--;
							amountOverride = 1;
							beginDragInvItem(ObjectType.Gold, false);
							clientServices.SendDropAt(gx, gy);
							while(amountOverride)
								wait();  // wait for drop to happen
							while(objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy] is null ||
							      globalObjects[objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy].ID].objType != ObjectType.Gold)
								wait();
						}
					}
		
			if(!pixelsRemaining) break;
			ProximityScreenFinder psf = new ProximityScreenFinder(&validator, myX, myY, 0);
			try
				call(psf);
			catch
			{
				for(int y=0;y<height;y++)
					for(int x=0;x<width;x++)
						if(pixels[y*width+x])
						{
							PathFinder.reset();
							for(int dx=-1;dx<=1;dx++)
								for(int dy=-1;dy<=1;dy++)
									if(dx!=0 || dy!=0)
										if(!isSolid(myMap, ox+x+dx, oy+y+dy))
											PathFinder.addFinish(myMap, ox+x+dx, oy+y+dy);
							PersistentPF ppf = new PersistentPF;
							call(ppf);
							continue mainloop;
						}
			}
		} while(pixelsRemaining);
	}

	override void configure()
	{
		auto of = new OpenFileDialog();
		of.filter = "Supported images (*.bmp, *.gif)|*.bmp;*.gif";
		of.title = "Select a monochrome image for the pattern";
		of.restoreDirectory = true;
		if(of.showDialog()==DialogResult.OK)
		{
			auto pic = new Picture(of.fileName);
			auto g = Graphics.getScreen();
			auto dc = CreateCompatibleDC(g.handle);
			auto bmp = pic.toBitmap(cast(dfl.internal._stdcwindows.HDC)dc);
			SelectObject(dc, bmp.handle);
			g.dispose();
			width = pic.width;
			height = pic.height;
			image.length = width * height;
			Stdout("[GoldPrinter] Image loaded: ").newline;
			int cost;
			for(int y=0;y<height;y++)
			{
				for(int x=0;x<width;x++)
				{
					bool v = GetPixel(dc, x, y) != 0;
					image[y*width+x] = v;
					//Stdout(v?"X":".");
					if(v) cost++;
					//Stdout.format("{:X8} ", GetPixel(dc, x, y));
				}
				Stdout.newline;
			}
			Stdout("[GoldPrinter] Total cost: ")(cost).newline;
			DeleteDC(dc);
			bmp.dispose();
			delete pic;
		}
	}
}

static this()
{
	dranscript.programs ~= new GoldPrinter;
}
