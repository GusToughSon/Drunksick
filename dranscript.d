module dranscript;

// common actions used in scripts...

public import commondata;
public import messagelog;

// ****************************************************************

import tango.core.Thread;
import tango.math.Math;
import tango.text.Util;
import tango.text.convert.Integer;
static import timing;

bool waitingForUseCursor;                      /// for AutoEater
uint amountOverride = 0;                       /// used to override amount selection dialog
ObjectType tradeSkillItem = ObjectType.None;   /// used to override trade skill item selection box

/// Base Program class
abstract class Program
{
public:
	final // public services
	{
		this()
		{
			messageFilter = 
			[
				MessageType.HarvestReady, 
				MessageType.Event, 
				MessageType.ReUseReady, 
				MessageType.LevelUp, 
				MessageType.SkillLevelUp, 
				
				MessageType.QuestStatus,
				MessageType.ObjInspection, 
				MessageType.CombatTextToggle, 
				MessageType.Screenshot,
				MessageType.LevelExpCheck,
				
				MessageType.EatFull, 
				MessageType.EatDone, 

				MessageType.MyChat, 
				MessageType.MyWhisperChat, 
				MessageType.GuildChat, 
				MessageType.MyGuildChat
			];
			messageHandlers ~= &messageHandler;
			thread = new Thread(&launcher);
		}

		void start()
		{
			if(running) throw new Exception("Already running!");
			_running = false;
			_result = null;
			child = parent = null;
			done = false;
			runFlag = true;
			clearMessageQueue();
			initialize();
			thread.start();
			volatile while(runFlag)
				Sleep(1); // wait through first step
		}

		void stop()
		{
			done = true;
			if(child)
				child.stop();
		}

		void stopAndWait()
		{
			stop();
			while(_running)
				Sleep(1);
		}

		bool running()
		{
			return _running;
		}

		bool stopping()
		{
			return _running && done;
		}

		Object result()
		{
			return _result;
		}

		void step()
		{
			assert(_running, "Not running!");
			assert(!runFlag, "Still executing!");
			runFlag = true;
			volatile while(runFlag)
				Sleep(1);
		}
	}

	char[] name()
	{
		char[] s=this.classinfo.name;
		foreach_reverse(i,c;s)
			if(c=='.')
				return s[i+1..$];
		return s;
	}

	void configure()
	{
		throw new Exception("This program doesn't have any options you can configure.");
	}

	override char[] toString()
	{
		return name;
	}

protected:	
	bool done;
	abstract void execute();
	void initialize(){}  /// allow initialization in the main thread - not available to called programs
	MessageType[] messageFilter;

	final // script services
	{
		/// "call" another program instance
		Object call(void delegate() dg)
		{
			Program program = cast(Program)dg.ptr;
			if(program is null) throw new Exception("Invalid delegate parameter to call()");
			
			child = program; program.parent = this;
			child.runFlag = true;
			child.done = false;
			child._result = null;
			try
				child.execute();
			catch(Object e)
			{
				Stdout("Error ")(e.toString)(" in child program ")(child.name).newline;
				throw new Exception("[chained] "~e.toString);
			}
			clearMessageQueue();
			child = program.parent = null; 
			return program.result;
		}

		Object call(Program program)
		{
			return call(&program.execute);
		}	

		/// wait one "tick" (synchronized with the game thread)
		void wait()
		{
			if(parent)
				return parent.wait();
			assert(runFlag, "Wasn't running!");
			runFlag = false;                
			volatile while(!runFlag && !done)
				Sleep(1);

			if(done) throw new Exception("Program terminated by user");
		}

		/// wait for any message, return its type
		MessageType waitForMessage(int timeout = int.max)
		{
			while(messageQueue.length==0)
			{
				if(timeout--==0) return MessageType.None;
				wait();
			}
			
			auto type = messageQueue[0];
			messageQueue = messageQueue[1..$];
			//debug Stdout(">> Dispatched message " ~ MessageTypeNames[type]).newline;
			return type;
		}

		/// wait for this message, fail on any other
		void waitForMessage(MessageType message, int timeout = int.max)
		{
			debug Stdout("Waiting for " ~ MessageTypeNames[message]).newline;
			auto msg = waitForMessage(timeout);
			if(msg != message)
				throw new Exception("Got " ~ MessageTypeNames[msg] ~ " while waiting for " ~ MessageTypeNames[message]);
		}

		/// wait for one any of these messages, fail on any other
		MessageType waitForMessage(MessageType[] messages, int timeout = int.max)
		{
			debug Stdout("Waiting for " ~ messageTypeNames(messages).join(" or ")).newline;
			auto msg = waitForMessage(timeout);
			foreach(message;messages)
				if(msg == message)
					return msg;
			
			throw new Exception("Got " ~ MessageTypeNames[msg] ~ " while waiting for " ~ messageTypeNames(messages).join(" or "));
		}

		/// wait for count _messages from the messages array, in any order (defaults to all messages), fail on any other
		void waitForMessages(MessageType[] messages, int count=0)
		{
			auto got = new bool[messages.length];

			char[] leftStr()
			{
				MessageType [] leftMsgs;
				foreach(i,message;messages)
					if(!got[i])
						leftMsgs~=message;
				return messageTypeNames(leftMsgs).join(" and ");
			}

			int left = count==0?messages.length:count;
			debug Stdout("Waiting for " ~ .toString(left) ~ " of " ~ messageTypeNames(messages).join(", ")).newline;
		
		nextMessage:
			while(left>0)
			{
				auto msg = waitForMessage();
				foreach(i,message;messages)
					if(message==msg)
						if(got[i])
							throw new Exception("Got excessive " ~ MessageTypeNames[msg] ~ " while waiting for " ~ leftStr);
						else
						{
							got[i]=true;
							left--;
							continue nextMessage;
						}
				throw new Exception("Got " ~ MessageTypeNames[msg] ~ " while waiting for " ~ leftStr);
			}
		}

		/// reset messages received up to this point
		void clearMessageQueue()
		{
			messageQueue = null;
		}
		
		/// wait for the "use item on..." mouse cursor
		void waitForUseCursor()
		{
			waitingForUseCursor = true;
			debug Stdout("Waiting for use cursor").newline;
			while(!mouse.useCursor)
				wait();
			waitingForUseCursor = false;
		}
		
		/// wait for any message OR the use cursor
		MessageType waitForMessageOrUseCursor()
		{
			debug Stdout("Waiting for message or use cursor").newline;
			while(messageQueue.length==0 && !mouse.useCursor)
				wait();
			if(messageQueue.length>0)
				return messageQueue[0];
			else
				return MessageType.None;
		}

		/+/// wait until an object of a certain type appears in the vicinity
		void waitForNearbyObject(ObjectType type)+/

		/// walk in a direction (takes VK_ constants)
		void walk(WalkDirection direction)
		{
			int ox=myX, oy=myY;
			do
			{
				clientServices.SendWalk(direction);
				for(int c=0;c<100*timing.speed;c++)
				{
					wait();
					if(myX!=ox || myY!=oy) return;
				}
				Stdout("Warning: walk timed out").newline;
			} while(true);
		}

		void walkSouth() { walk(WalkDirection.South); }
		void walkNorth() { walk(WalkDirection.North); }
		void walkWest()  { walk(WalkDirection.West); }
		void walkEast()  { walk(WalkDirection.East); }
	}

private:
	bool _running;
	bool runFlag;  // run this step?
	Object _result;
	Program child, parent;
	private Thread thread;
	private MessageType[] messageQueue;

	final 
	{
		void messageHandler(MessageType type)
		{
			if(!_running)
				return;
			foreach(filtered;messageFilter)
				if(filtered==type)
					return;
			messageQueue ~= [type];
		}

		void launcher()
		{
			_running = true;
			try
				execute();
			catch(Object e)
			{
				Stdout("Exception in program " ~ name ~ ": " ~ e.toString).newline;
				_result = e;
			}
			done = true;
			_running = false;
			runFlag = false;
		}

		char[][] messageTypeNames(MessageType[] messages)
		{	
			char[][] strs;
			foreach(message;messages)
				strs~=MessageTypeNames[message];
			return strs;
		}
	}
}

Program[] programs;

// ****************************************************************

/// selects specified object
void selectObject(uint ID)
{
	clientServices.SendSelectItem(ID);
	playerData.WaitingForItemSelection = playerData.TargetingLocked = false;
	mouse.useCursor1 = mouse.useCursor2 = false;
}

/// selects specified tile (global coords)
void selectTile(uint x, uint y)
{
	clientServices.SendSelectTile(x, y);
	playerData.WaitingForItemSelection = playerData.TargetingLocked = false;
	mouse.useCursor1 = mouse.useCursor2 = false;
}

/// returns "true" if there is an item of type objType in the PC's inventory
bool haveItem(ObjectType objType)
{
	foreach(item;*backPack)
		if(globalObjects[item.ID].objType == objType)
			return true;
	return false;
}

/// selects an item from the list that's present in the PC's inventory
bool pickOwnedItem(ObjectType[] objTypes, out ObjectType found)
{
	foreach(objType;objTypes)
		if(haveItem(objType))
		{
			found = objType;
			return true;
		}
	return false;
}

/// selects an item of the specified type from the user's inventory
void selectInvItem(ObjectType objType)
{
	//assert(playerData.WaitingForItemSelection, "selectInvItem with no cursor");
	foreach(item;*backPack)
		if(globalObjects[item.ID].objType == objType)
			return selectObject(item.ID);
	throw new Exception("clickInvItem: No such item: " ~ objectData[objType].nameStr);
}

/// uses (double-clicks on) an item of the specified type from the user's inventory
void useInvItem(ObjectType objType)
{
	foreach(item;*backPack)
		if(globalObjects[item.ID].objType == objType)
			return playerData.UseObject(item.ID);
	throw new Exception("useInvItem: No such item: " ~ objectData[objType].nameStr);
}

/// uses (double-clicks on) an item of one of the specified types from the user's inventory
void useInvItem(ObjectType[] objTypes)
{
	foreach(item;*backPack)
		foreach(objType;objTypes)
			if(globalObjects[item.ID].objType == objType)
				return playerData.UseObject(item.ID);
	throw new Exception("useInvItem: No such items");
}

/// 
void beginDragInvItem(ObjectType objType, bool dragAll)
{
	foreach(item;*backPack)
		if(globalObjects[item.ID].objType == objType)
			return clientServices.SendBeginDrag(item.ID, dragAll);
	throw new Exception("beginDragInvItem: No such item: " ~ objectData[objType].nameStr);
}

/+/// send the "re-use" action
void reuse()
{
	pressChar('u');
}+/

/// click on the PC on the main map
void selectSelf()
{
	//assert(playerData.WaitingForItemSelection, "selectInvItem with no cursor");
	selectObject(playerData.MyID);
}

/// checks if an object of the specified type is in the player's direct vicinity
bool isObjectNearby(ObjectType objType)
{
	foreach(obj;*objectList)
		if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<2 && abs(obj.y-myY)<2 && obj.objType==objType)
			return true;
	return false;
}

/// checks if an object of one of the specified types is in the player's direct vicinity
bool isObjectNearby(ObjectType[] objTypes)
{
	foreach(obj;*objectList)
		foreach(objType;objTypes)
			if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<2 && abs(obj.y-myY)<2 && obj.objType==objType)
				return true;
	return false;
}

/// clicks an object of the specified type from the player's direct vicinity
void selectNearbyObject(ObjectType objType)
{
	foreach(obj;*objectList)
		if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<2 && abs(obj.y-myY)<2 && obj.objType==objType)
			return selectObject(obj.ID);
	throw new Exception("clickNearbyObject: can't find object: " ~ objectData[objType].nameStr);
}

/// clicks an object of the specified type from the player's direct vicinity
void selectNearbyObject(ObjectType[] objTypes)
{
	foreach(obj;*objectList)
		if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<2 && abs(obj.y-myY)<2)
			foreach(objType;objTypes)
				if(obj.objType==objType)
					return selectObject(obj.ID);
	throw new Exception("clickNearbyObject: can't find object");
}

/// double-clicks an object of the specified type from the player's direct vicinity
void useNearbyObject(ObjectType objType)
{
	foreach(obj;*objectList)
		if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<2 && abs(obj.y-myY)<2 && obj.objType==objType)
			return playerData.UseObject(obj.ID);
	throw new Exception("clickNearbyObject: can't find object: " ~ objectData[objType].nameStr);
}

/// double-clicks an object/NPC of the specified type from the player's vicinity (1-2 squares away)
void useNearbyNPC(ObjectType objType)
{
	foreach(obj;*objectList)
		if(obj.flags&ObjectFlags.OnMap && abs(obj.x-myX)<3 && abs(obj.y-myY)<3 && obj.objType==objType)
			return playerData.UseObject(obj.ID);
	throw new Exception("clickNearbyObject: can't find object: " ~ objectData[objType].nameStr);
}

// ****************************************************************
