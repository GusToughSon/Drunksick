module programs.barrelpaint;

import dranscript;
import dfl.all;
import tango.sys.win32.UserGdi;
import pathfinder; // isSolid
import programs.pfhelper;
import mainui; // disable autograbber

class BarrelPaint : Program
{
	bool[] image;
	int width, height;	

	override void execute()
	{
		if(image is null)
			throw new Exception("No image set! Press [...] and select a black & white image.\nDraw the pattern white-on-black, one pixel being one container pixel (and will cost one item).");

		foreach(ref container;&playerData.containerIterator)
		{
			if(container.ID != playerData.BackpackID)
			{
				Stdout("Painting in container ")(container.ID).newline;
				for(int y=0;y<height;y++)
					for(int x=0;x<width;x++)
						if(image[y*width+x])
						{
							amountOverride = 1;
							beginDragInvItem(ObjectType.Gold, false);
							//beginDragInvItem(ObjectType.GreaterHealingPotion, false);
							int old = container.itemCount;
							clientServices.SendDropOnItemAt(container.ID, x, y);
							while(amountOverride)
								wait();  // wait for drop to happen
							while(container.itemCount == old)
								wait();  // wait for item to appear
						}
				return;
			}
		}
		throw new Exception("No container other than your backpack is open.");
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
			Stdout("[BarrelPaint] Image loaded: ").newline;
			int cost;
			for(int y=0;y<height;y++)
			{
				for(int x=0;x<width;x++)
				{
					bool v = GetPixel(dc, x, y) != 0;
					image[y*width+x] = v;
					Stdout(v?"X":".");
					if(v) cost++;
					//Stdout.format("{:X8} ", GetPixel(dc, x, y));
				}
				Stdout.newline;
			}
			Stdout("[BarrelPaint] Total cost: ")(cost).newline;
			DeleteDC(dc);
			bmp.dispose();
			delete pic;

			if(cost>200)
			{
				image = null;
				throw new Exception(formatter("Your image has too many pixels - {}, {} more than the maximum of 200 white pixels.\nThe game only draws up to 200 objects inside a container.\nPlease erase some pixels and try again", cost, cost-200));
			}
		}
	}
}

static this()
{
	dranscript.programs ~= new BarrelPaint;
}
