module programs.graball;

import dranscript;
import dfl.all;
import mainui;
import pathfinder; // isSolid

class GrabAll : Program
{
	ContextMenu menu;
	MenuItem miDragToFloor;
	
	this()
	{
		menu = new ContextMenu;
		miDragToFloor = new MenuItem;
		miDragToFloor.text = "&Drag to floor";
		miDragToFloor.click ~= &miToggleClick;
		menu.menuItems.add(miDragToFloor);
	}
	
	private void miToggleClick(MenuItem sender, EventArgs ea)
	{
		sender.checked = !sender.checked;
	}

	override void execute()
	{
		int dx, dy; bool found;
		if(miDragToFloor.checked)
		{
			for(int sx=SCREEN_SIZE/2-1;sx<=SCREEN_SIZE/2+1;sx++)
				for(int sy=SCREEN_SIZE/2-1;sy<=SCREEN_SIZE/2+1;sy++)
					if(mobMap[sx][sy] is null && objMap[sx][sy] is null && !isSolid(myMap, myX-SCREEN_SIZE/2+sx, myY-SCREEN_SIZE/2+sy) && !found)
					{
						dx = myX-SCREEN_SIZE/2+sx;
						dy = myY-SCREEN_SIZE/2+sy;
						found = true;
					}
			if(!found)
				throw new Exception("Can't drag to floor because can't find a free tile around player");
		}
		
		foreach(ref container;&playerData.containerIterator)
		{
			if(container.ID != playerData.BackpackID)
			{
				Stdout("Grabbing everything from container ")(container.ID).newline;
				foreach(ref item;container)
				{
					Stdout("Grabbing ")(objectData[globalObjects[item.ID].objType].nameStr).newline;
					clientServices.SendBeginDrag(item.ID, true);
					if(miDragToFloor.checked)
						clientServices.SendDropAt(dx, dy);
					else
						clientServices.SendDropOnItemAt(playerData.BackpackID, -1, -1);
				}
				return;
			}
		}
		throw new Exception("No container other than your backpack is open.");
	}

	override void configure()
	{
		menu.show(mainForm, Cursor.position);
	}
}

static this()
{
	programs ~= new GrabAll;
}
