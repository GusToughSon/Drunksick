module bpbugfix;

import commondata;

void bpBugFix()
{
	foreach(ref item;*backPack)
		//if(!(globalObjects[item.ID].flags & ObjectFlags.Visible) && !(playerData.IsDragging && playerData.DraggedItemID==item.ID))
		if((item.ID in globalObjects) && !(globalObjects[item.ID].flags & ObjectFlags.Visible) && playerData.DraggedItemID!=item.ID && playerData.HeldItemID!=item.ID)
		{
			Stdout.format("BPBugFix: Unhiding {}", objectData[globalObjects[item.ID].objType].nameStr).newline;
			globalObjects[item.ID].flags |= ObjectFlags.Visible;
		}
}