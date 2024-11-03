module autotarget;

import commondata;
import timing;

bool autoTarget()
{
	if(mouse.useCursor) return false;

	int minDistance = int.max;
	CameraObject* closestMob = null;
		
	foreach(ref mob;&camera.mobIterator)
		with(mob)
			if(ID != playerData.MyID)  // don't target self
				if(mob.guildTag is null || playerData.guildTag is null || mob.guildTag != playerData.guildTag)  // don't target co-guildians
				{
					auto glb = globalObjects[ID];
			
					if(glb.attackable)
						if(distance < minDistance /*|| (distance == minDistance && maxHealth>0 && (closestMob.maxHealth==0 || health<closestMob.health))*/)
						{
							closestMob = &mob;
							minDistance = distance;
						}
				}

	if(closestMob is null)
		return false;

	bool breakLoop = true; // don't continue to next action

	if(selectionPresent)
	{
		int cx=battleCursorX, cy=battleCursorY;
		//Stdout.format("Current coords: {},{}   Best coords: {},{}", cx, cy, closestMob.x, closestMob.y).newline;
		if(mobMap[cx][cy] is null)
			Stdout("mobMap[cx][cy] is null").newline;
		else
		if(mobMap[cx][cy].ID != camera.Target)
			Stdout("mobMap[cx][cy].ID != camera.Target").newline;
		else
		if(camera.Target != playerData.Target)
			Stdout("camera.Target != playerData.Target").newline;
		else
		if(cx==closestMob.X && cy==closestMob.Y)
		{
			if(mobMap[cx][cy].MaxHealth==0)
			{
				Stdout("(reselecting) ");
				breakLoop = false;
			}
			else
			if(rand(250)==0)
			{
				Stdout("(periodic auto-reselect) ");
				closestMob = mobMap[cx][cy];
			}
			else
			if(closestMob.ID == camera.Target)
				closestMob = null;
			else
				Stdout("closestMob.ID != camera.Target").newline;
		}
		else
		if(calcDistance(cx, cy) <= minDistance)
			closestMob = null;
	}
		
	if(closestMob is null)
		return false;

	//if(minDistance > 5)
	//	return false;   // don't target mobs too far away
	
	auto glb = globalObjects[closestMob.ID];

	Stdout.format("AutoTarget: Targeting {} at {}x{}", objectData[glb.objType].nameStr, closestMob.X, closestMob.Y).newline;
	//clickMap(closestMob.x, closestMob.y);
	playerData.SetTarget(closestMob.ID);
	//wait(200+rand(100));
	return breakLoop;
}
