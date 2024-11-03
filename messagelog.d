module messagelog;

import commondata;
import tango.text.Util;

char[] makeEnum(char[] name, char[][] members)
{
	char[] s = "enum " ~ name ~ "{";
	foreach(member;members)
		s ~= member ~ ",";
	s~="}";
	s~="const char[]["~ name ~".max+1] " ~ name ~ "Names = [";
	foreach(member;members)
		s ~= \" ~ member ~ "\",";
	s ~= "];";
	return s;
}

mixin(makeEnum("MessageType", [
	"None",
	"Chat",
	"MyChat",
	"WhisperChat",
	"MyWhisperChat",
	"GuildChat",
	"MyGuildChat",
	"NPCChat",
	"Death",
	"ContainerFull",
	"ReUseReady",
	"ReUseFailClient",
	"ReUseFailServer",
	"CookStart",
	"CookSuccess",
	"CookFailure",
	"EatDone",
	"EatFull",
	"HealDone",
	"DigPrompt",
	"DigStart",
	"DigDone",
	"DigShovelBroken",       // @fdThe Shovel has broken.
	"PlantStart",
	"PlantSuccess",
	"PlantFailure",
	"HarvestReady",
	"LevelUp",
	"SkillLevelUp",
	"MixFlourSelectCup",     // @f1Select an empty measuring cup.
	"MixFlourAddedToCup",    // @f1You put flour into the measuring cup.
	"MixFlourSelectBowl",    // @f1What would you like to pour this on?
	"MixFlourAddedToBowl",   // @f1You add the flour to the bowl.
	"MixWaterSelect",        // @f1What would you like to pour water on?
	"MixWaterAddedToCup",    // @f1You pour the water into the cup.
	"MixWaterAddedToBowl",   // @f1You add the water to the bowl.
	"MixWaterSelectBucket",  // @f1What would you like to pour water in?
	"MixWaterAddedToBucket", // @f1You pour the water into the bucket.
	"MixSpoonSelectBowl",    // @f1What would you like to mix?
	"Adding",                // @f1Adding.....
	"Mixing",                // @f1Mixing.....
	"MixSuccess",            // @f1You have made the item.
	"MixSuccess2",           // @f1You have mixed the dough.
	"MixFailure",            // @fdYou are not skilled enough. You destroy the mixture.
	"OutOfFlour",            // @fdYou have used all of your flour.
	"EggSearchStart",        // @f1You search for any eggs.
	"EggSearchSuccess",      // @f1An egg was found.
	"EggSearchFailure",      // @fdNo eggs were found.
	"HarvestCropStart",      // @f1You swing the Scythe to cut the crop.
	"HarvestCropSuccess",    // @f1The crop is harvested.
	"HarvestCropFailure",    // @fdYou damage the crop.
	"GatherResourceFailure", // @fdYou find no useful material.
	"ChopLumberPrompt",      // @f1Where would you like to chop?
	"ChopLumberStart",       // @45You begin to chop...
	"ChopLumberSuccess",     // @f1You have chopped some lumber.
	"ChopLumberDepleted",    // @fdThere is nothing to chop here.
	"SawLumberPrompt",       // @f1Select the object you would like to saw.
	"SawLumberStart",        // @45You begin to saw the lumber...
	"SawLumberSuccess",      // @f1You have crafted the lumber into planks.
	"SawLumberFailure",      // @fdYou destroyed some lumber.
	"CarpenterPrompt",       // @f1Select the planks you'd like to use.
	"CarpenterStart",        // @f1You begin to craft a
	"CarpenterSuccess",      // @fdYou lose some material.
	"CarpenterFailure",      // @f1You have created a
	"FishPrompt",            // Where would you like to fish?
	"FishStart",             // @45You begin to fish.
	"FishSuccess",           // @f1You catch a fish.
	"FishFailure",           // @fdNothing seems to be biting.
	"FishDepleted",          // @fdThis location no longer seems suitable for fishing.
	"FishLineBroke",         // @fdYour line breaks.
	"Working",               // @f1Working........
	"MakeFishingPoleDone",   // @f1You tie the string to the Fishing Pole.
	"MinePrompt",            // @f1Where would you like to mine?
	"MineStart",             // @45You begin to mine...
	"MineSuccess",           // @f1You have mined 
	"MineDepleted",          // @fdThere is nothing to mine here.
	"SmeltPrompt",           // @f1Select the forge where you wish to smelt your ore.
	"SmeltForgeCooling",     // The forge is cooling off
	"SmeltForgeCooled",      // @45The forge must have a fire.
	"SmeltStart",            // @45You begin to smelt the ore...
	"SmeltFailure",          // @fdYou have destroyed some ore.
	"SmeltSuccess",          // @f1You have smelted ingot(s)!
	"SmithPrompt",           // @f1Select the item you with to use the hammer on.
	"SmithStart",            // @F1You begin to forge a
	"SmithSuccess",          // @FDYou have lost some ingots.
	"SmithFailure",          // @F1You have forged a
	"Poisoned",              // @F1You have been poisoned@18!
	"Diseased",              // @FAYou have been diseased@18!
	"PoisonCured",           // @F1You have been cured of your poison!
	"DiseaseCured",          // @F1You have been cured of your disease!
	"CurePtnFailure",        // You do not have an illness.
	"GreaterCurePtnFailure", // @45You do not have any sickness.
	"QuestStatus",           // @45You have killed
	"ObjInspection",         // You see 
	"CombatTextToggle",      // Combat Text is 
	"Screenshot",            // @F1Screenshot: 
	"LevelExpCheck",         // Level 
	"Event",                 // game event messages (contests etc.)
	"System",                // all other messages without a colour
	"Unknown"
]));

/+ transform regexp:
from: 
	"(\w*)",\s*// ([^\n]*)
to:
	if\(msg.startsWith\("$2"\)\)\n		return MessageType.$1;
 +/

alias void delegate(MessageType) MessageHandler;
MessageHandler[] messageHandlers;

import codetools;

Hook installMessageHook()
{
	return Hook(cast(void*)Offsets.MessageLogCapture, 6, &hkMessageLogCapture);
}

private char[] lineBuffer;

void hkMessageLogCapture(Context* context)
{
	char[] msg = readStringZ(cast(char*)Offsets.ScreenLog__Log_TempBuffer);
	while(msg.contains('\n'))
	{
		lineBuffer ~= msg[0..msg.locate('\n')];
		auto type = decodeMessage(lineBuffer);
		Stdout("Log [")(MessageTypeNames[type])("]: ")(lineBuffer).newline;
		if(type != MessageType.None)
			foreach(handler;messageHandlers)
				handler(type);
		lineBuffer = null;
		msg = msg[msg.locate('\n')+1..$];
	}
	lineBuffer ~= msg;
}

bool startsWith(char[] s, char[] sub)
{
	return s.length>=sub.length && s[0..sub.length]==sub;
}

MessageType decodeMessage(char[] msg)
{
	if(msg.length==0)
		return MessageType.None;
	
	if(msg.startsWith("@F1You awaken at a Spawn Gate..."))
		return MessageType.Death;
	
	if(msg.startsWith("@F1--ReUse is ready."))
		return MessageType.ReUseReady;
	if(msg.startsWith("@43You must wait before using another item."))
		return MessageType.ReUseFailClient;
	if(msg.startsWith("You must wait before using another item."))
		return MessageType.ReUseFailServer;
	
	if(msg.startsWith("@FDContainer is Full"))
		return MessageType.ContainerFull;

	if(msg.startsWith("@f1You begin to cook the "))
		return MessageType.CookStart;
	if(msg.startsWith("@f1You cooked "))
		return MessageType.CookSuccess;
	if(msg.startsWith("@fdYou ruined "))
		return MessageType.CookFailure;
	if(msg.startsWith("@fdYou have destoryed all of your "))  // sic
		return MessageType.CookFailure;

	if(msg.startsWith("@F1The food has been eaten."))
		return MessageType.EatDone;
	if(msg.startsWith("@45The food is not needed."))
		return MessageType.EatFull;

	if(msg.startsWith("You have been healed "))
		return MessageType.HealDone;
		
	if(msg.startsWith("@f1Where would you like to dig?"))
		return MessageType.DigPrompt;
	if(msg.startsWith("@f1You begin to dig."))
		return MessageType.DigStart;
	if(msg.startsWith("@f1You have dug a hole."))
		return MessageType.DigDone;
	if(msg.startsWith("@fdThe Shovel has broken."))
		return MessageType.DigShovelBroken;

	if(msg.startsWith("@f1You attempt to plant a seed."))
		return MessageType.PlantStart;
	if(msg.startsWith("@f1A seed has been planted."))
		return MessageType.PlantSuccess;
	if(msg.startsWith("@fdYou cannot seem to get the seed planted."))
		return MessageType.PlantFailure;

	if(msg.startsWith("@45One of your crops is ready to harvest."))
		return MessageType.HarvestReady;

	if(msg.startsWith("@f1Select an empty measuring cup."))
		return MessageType.MixFlourSelectCup;
	if(msg.startsWith("@f1You put flour into the measuring cup."))
		return MessageType.MixFlourAddedToCup;
	if(msg.startsWith("@f1What would you like to pour this on?"))
		return MessageType.MixFlourSelectBowl;
	if(msg.startsWith("@f1You add the flour to the bowl."))
		return MessageType.MixFlourAddedToBowl;
	if(msg.startsWith("@f1What would you like to pour water on?"))
		return MessageType.MixWaterSelect;
	if(msg.startsWith("@f1You pour the water into the cup."))
		return MessageType.MixWaterAddedToCup;
	if(msg.startsWith("@f1You add the water to the bowl."))
		return MessageType.MixWaterAddedToBowl;
	if(msg.startsWith("@f1What would you like to pour water in?"))
		return MessageType.MixWaterSelectBucket;
	if(msg.startsWith("@f1You pour the water into the bucket."))
		return MessageType.MixWaterAddedToBucket;
	if(msg.startsWith("@f1What would you like to mix?"))
		return MessageType.MixSpoonSelectBowl;
	if(msg.startsWith("@f1Adding....."))
		return MessageType.Adding;
	if(msg.startsWith("@f1Mixing....."))
		return MessageType.Mixing;
	if(msg.startsWith("@f1You have made the item."))
		return MessageType.MixSuccess;
	if(msg.startsWith("@f1You have mixed the dough."))
		return MessageType.MixSuccess2;
	if(msg.startsWith("@fdYou are not skilled enough. You destroy the mixture."))
		return MessageType.MixFailure;
	if(msg.startsWith("@fdYou have used all of your flour."))
		return MessageType.OutOfFlour;

	if(msg.startsWith("@f1You search for any eggs."))
		return MessageType.EggSearchStart;
	if(msg.startsWith("@f1An egg was found."))
		return MessageType.EggSearchSuccess;
	if(msg.startsWith("@fdNo eggs were found."))
		return MessageType.EggSearchFailure;

	if(msg.startsWith("@f1You swing the Scythe to cut the crop."))
		return MessageType.HarvestCropStart;
	if(msg.startsWith("@f1The crop is harvested."))
		return MessageType.HarvestCropSuccess;
	if(msg.startsWith("@fdYou damage the crop."))
		return MessageType.HarvestCropFailure;

	if(msg.startsWith("@fdYou find no useful material."))
		return MessageType.GatherResourceFailure;

	if(msg.startsWith("@f1Where would you like to chop?"))
		return MessageType.ChopLumberPrompt;
	if(msg.startsWith("@45You begin to chop..."))
		return MessageType.ChopLumberStart;
	if(msg.startsWith("@f1You have chopped some lumber."))
		return MessageType.ChopLumberSuccess;
	if(msg.startsWith("@fdThere is nothing to chop here."))
		return MessageType.ChopLumberDepleted;

	if(msg.startsWith("@f1Select the object you would like to saw."))
		return MessageType.SawLumberPrompt;
	if(msg.startsWith("@45You begin to saw the lumber..."))
		return MessageType.SawLumberStart;
	if(msg.startsWith("@f1You have crafted the lumber into planks."))
		return MessageType.SawLumberSuccess;
	if(msg.startsWith("@fdYou destroyed some lumber."))
		return MessageType.SawLumberFailure;

	if(msg.startsWith("@f1Select the planks you'd like to use."))
		return MessageType.CarpenterPrompt;
	if(msg.startsWith("@f1You begin to craft a"))
		return MessageType.CarpenterStart;
	if(msg.startsWith("@fdYou lose some material."))
		return MessageType.CarpenterSuccess;
	if(msg.startsWith("@f1You have created a"))
		return MessageType.CarpenterFailure;

	if(msg.startsWith("Where would you like to fish?"))
		return MessageType.FishPrompt;
	if(msg.startsWith("@45You begin to fish."))
		return MessageType.FishStart;
	if(msg.startsWith("@f1You catch a fish."))
		return MessageType.FishSuccess;
	if(msg.startsWith("@fdNothing seems to be biting."))
		return MessageType.FishFailure;
	if(msg.startsWith("@fdThis location no longer seems suitable for fishing."))
		return MessageType.FishDepleted;
	if(msg.startsWith("@fdYour line breaks."))
		return MessageType.FishLineBroke;
	if(msg.startsWith("@f1Working........"))
		return MessageType.Working;
	if(msg.startsWith("@f1You tie the string to the Fishing Pole."))
		return MessageType.MakeFishingPoleDone;

	if(msg.startsWith("@f1Where would you like to mine?"))
		return MessageType.MinePrompt;
	if(msg.startsWith("@45You begin to mine..."))
		return MessageType.MineStart;
	if(msg.startsWith("@f1You have mined "))
		return MessageType.MineSuccess;
	if(msg.startsWith("@fdThere is nothing to mine here."))
		return MessageType.MineDepleted;

	if(msg.startsWith("@f1Select the forge where you wish to smelt your ore."))
		return MessageType.SmeltPrompt;
	if(msg.startsWith("The forge is cooling off"))
		return MessageType.SmeltForgeCooling;
	if(msg.startsWith("@45The forge must have a fire."))
		return MessageType.SmeltForgeCooled;
	if(msg.startsWith("@45You begin to smelt the ore..."))
		return MessageType.SmeltStart;
	if(msg.startsWith("@fdYou have destroyed some ore."))
		return MessageType.SmeltFailure;
	if(msg.startsWith("@f1You have smelted ingot(s)!"))
		return MessageType.SmeltSuccess;

	if(msg.startsWith("@f1Select the item you with to use the hammer on."))
		return MessageType.SmithPrompt;
	if(msg.startsWith("@F1You begin to forge a"))
		return MessageType.SmithStart;
	if(msg.startsWith("@FDYou have lost some ingots."))
		return MessageType.SmithSuccess;
	if(msg.startsWith("@F1You have forged a"))
		return MessageType.SmithFailure;

	if(msg.startsWith("@F1You have been poisoned@18!"))
		return MessageType.Poisoned;
	if(msg.startsWith("@FAYou have been diseased@18!"))
		return MessageType.Diseased;
	if(msg.startsWith("@F1You have been cured!"))
		return MessageType.PoisonCured;
	if(msg.startsWith("@F1You have been cured of your poison!"))
		return MessageType.PoisonCured;
	if(msg.startsWith("@F1You have been cured of your disease!"))
		return MessageType.DiseaseCured;
	if(msg.startsWith("You do not have an illness."))
		return MessageType.CurePtnFailure;
	if(msg.startsWith("@45You do not have any sickness."))
		return MessageType.GreaterCurePtnFailure;

	if(msg.startsWith("@45You have "))
		return MessageType.QuestStatus;
	if(msg.startsWith("You see "))
		return MessageType.ObjInspection;
	if(msg.startsWith("Combat Text is "))
		return MessageType.CombatTextToggle;
	if(msg.startsWith("@F1Screenshot: "))
		return MessageType.Screenshot;
	if(msg.startsWith("Level "))
		return MessageType.LevelExpCheck;

	if(msg.startsWith("@E4"))               // @E4<name>@18: @18
		return MessageType.Chat;
	if(msg.startsWith("@E1"))               // @E1<name>: @18
		return MessageType.MyChat;
	if(msg.startsWith("@A8"))               // @A8<name>@18: @A3
		return MessageType.WhisperChat;
	if(msg.startsWith("@A5"))               // @A5<name>: @A1
		return MessageType.MyWhisperChat;
	if(msg.startsWith("@8A"))               // @8A<name>@18: @85
		return MessageType.GuildChat;
	if(msg.startsWith("@88"))               // @88<name>: @83
		return MessageType.MyGuildChat;
	
	if(msg.startsWith("@E3"))
		return MessageType.NPCChat;
	if(msg.startsWith("@67"))
		return MessageType.Event;
	if(msg.startsWith("@89"))
		return MessageType.Event;

	if(msg.startsWith("YOU ARE NOW LEVEL "))
		return MessageType.LevelUp;
	if(msg.containsPattern(" is now level "))
		return MessageType.SkillLevelUp;
	//if(msg.startsWith("@F1"))
	//	return MessageType.Misc;
	if(!msg.startsWith("@"))
		return MessageType.System;

	return MessageType.Unknown;
}
