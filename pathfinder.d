module pathfinder;

import dranscript;
import tango.io.File;
import customMM;
import tango.core.Memory;
import tango.time.Clock;
import tango.math.Math;

bool[TILES] solidTiles;
private File f;

static this()
{
	solidTiles[] = false;
	f = new File(myPath ~ "solidtiles.bin");
	if(f.path.exists)
		solidTiles[] = cast(bool[])f.read();
}

bool solidTilesUpdated;

void saveSolidTiles()
{
	f.write(solidTiles);
	solidTilesUpdated = true;
}

bool isSolid(byte map, int x, int y)
{
	bool result = solidTiles[getTile(map, x, y)];
	if(!result)
	{
		x-=myX; y-=myY;
		if(abs(x)<=SCREEN_SIZE/2 && abs(y)<=SCREEN_SIZE/2 && map==myMap)
		{
			auto obj = objMap[x+SCREEN_SIZE/2][y+SCREEN_SIZE/2];
			if(obj)
				if(obj.ID in globalObjects)
				{
					auto glb = globalObjects[obj.ID];
					if(objectData[glb.objType].flags & ObjectDataFlags.Blocking)
						result = true;
				}
		}
	}
	return result;
}

bool isDoor(ObjectType objType)
{
	return objType==ObjectType.Door || objType==ObjectType.WindowedDoor;
}

// ****************************************************************

class PathFinder : Program
{
	struct Node
	{
		Node* prev, next;
		short distance, turns;
		short x, y, fx, fy;
		byte map, fmap;
		byte dir;
		bool linked;

		static int calcCost(short distance, short turns)
		{
			return cast(int)(distance)*10 + turns;
		}
		
		Node* from()
		{
			if(fmap==0 && fx==0 && fy==0)
				return null;
			else
				return nodeMap[fmap][fy][fx];
		}

		void from(Node* node)
		{
			if(node)
			{
				fmap = node.map;
				fx = node.x;
				fy = node.y;
			}
			else
				fx = fy = fmap = 0;
		}

		bool bad()
		{
			return distance>=INFINITE_DISTANCE;
		}

		int getCost()
		{
			return calcCost(distance, turns);
		}

		void link()
		{
			int cost = getCost();
			if(cost>=MAX_COST) return;
			prev = null;
			next = nodes[cost];
			nodes[cost] = this;
			if(next)
				next.prev = this;
			if(cost > furthestNode)
				furthestNode = cost;
		}

		//import tango.text.convert.Integer;
		void unlink()
		{
			int cost = getCost();
			if(cost>=MAX_COST) return;
			if(prev && prev.next is this)
				prev.next = next;
			else
			{
				//assert(nodes[origCost] is this, "unlinking un-properly-registered node: new cost is "~toUtf8(origCost));
				if(nodes[cost] is this)
					nodes[cost] = next;
			}
			if(next && next.prev is this)
				next.prev = prev;
			next = prev = null;
		}

		/+void relink()
		{
			unlink();
			link();
		}+/

		static Node* opCall(byte map, short x, short y, Node* from, byte dir=-1)
		{
			short distance=void, turns=void;
			if(from)
			{
				distance = from.distance+1;
				turns = from.turns;
				if(from.dir != dir && from.dir>=0)
					turns += min(abs(from.dir-dir), abs((from.dir+4)%8 - (dir+4)%8));
					//turns++;
			}
			else
				distance = turns = 0;
			Node* node = nodeMap[map][y][x];
			if(node is null)
			{
				node = new Node;
				node.x = x;
				node.y = y;
				node.map = map;
				nodeMap[map][y][x] = node;
			}
			else
			{
				if(calcCost(distance, turns) < node.getCost)
					node.unlink();  // re-use this node
				else
					return null;
			}

			node.distance = distance;
			node.turns = turns;
			node.from = from;
			node.dir = dir;
			node.link();

			return node;
		}

		static Node* makeNewNode(byte map, short x, short y, short distance, short turns)
		{
			Node* node = new Node;
			node.x = x;
			node.y = y;
			node.map = map;
			nodeMap[map][y][x] = node;
			node.distance = distance;
			node.turns = turns;
			node.dir = -1;
			return node;
		}

		static Node* makeBadNode(byte map, short x, short y)
		{
			return makeNewNode(map, x, y, INFINITE_DISTANCE, 0);
		}

		static Node* makeFinishNode(byte map, short x, short y, int penalty)
		{
			return makeNewNode(map, x, y, 0, penalty);
		}
	}

	static
	{
		const MAX_COST = 10*(short.max-2);
		const MAP_SIZE = 256;
		const CHUNK_WIDTH = 16;
		const MAP_WIDTH = MAP_SIZE * CHUNK_WIDTH;
		const MAP_COUNT = 2;
		const short INFINITE_DISTANCE = short.max-1;
		const STEP_DELAY = 215; // ms
		const MAX_QUEUE = 10;

		Node*[MAP_WIDTH][MAP_WIDTH][] nodeMap;
		bool[MAP_WIDTH][MAP_WIDTH][] solidityMap, tileSolidityMap;
		uint[256][256][2] chunkCache;
		Node*[MAX_COST] nodes;
		int furthestNode;
		bool allocated;

		void reset()
		{
			allocate();

			foreach(ref map;nodeMap)
				foreach(ref row;map)
					row[] = null;
			deallocateNodes();
			furthestNode = -1;
			actionQueue = null;
		}

		void resetQueue()
		{
			nodes[] = null;
			furthestNode = -1;
		}

		void allocate()
		{
			if(allocated) return;
			nodeMap         = cast(typeof(nodeMap        ))malloc(typeof(nodeMap        [0]).sizeof * MAP_COUNT);
			solidityMap     = cast(typeof(solidityMap    ))malloc(typeof(solidityMap    [0]).sizeof * MAP_COUNT);
			tileSolidityMap = cast(typeof(tileSolidityMap))malloc(typeof(tileSolidityMap[0]).sizeof * MAP_COUNT);
			GC.addRange(nodeMap.ptr,                              typeof(nodeMap        [0]).sizeof * MAP_COUNT);
			allocated = true;
		}

		void deallocate()
		{
			if(!allocated) return;
			GC.removeRange(nodeMap.ptr);
			free(nodeMap.ptr);
			free(solidityMap.ptr);
			free(tileSolidityMap.ptr);
			deallocateNodes();
		}

		void deallocateNodes()
		{
			for(int i=0;i<=furthestNode;i++)
			{
				Node* node = nodes[i];
				while(node)
				{
					Node* next = node.next;
					delete node;
					node = next;
				}
			}
			nodes[] = null;
		}

		/// update chunk cache and tile (base) solidity map
		void updateMap()
		{
			for(int map=0;map<MAP_COUNT;map++)
				for(int y=0;y<MAP_SIZE;y++)
					for(int x=0;x<MAP_SIZE;x++)
					{
						uint chunk = getChunk(map, x, y);
						if(solidTilesUpdated || chunk != chunkCache[map][y][x])
						{
							chunkCache[map][y][x] = chunk;
							MapChunkTiles* tiles = getChunkTiles(chunk);
							with(*tiles)
								for(int tx=0;tx<CHUNK_WIDTH;tx++)
									for(int ty=0;ty<CHUNK_WIDTH;ty++)
										tileSolidityMap[map][y*16+ty][x*16+tx] = solidTiles[data[ty][tx]];
						}
					}
			updateSolidityMap();
			solidTilesUpdated = false;
		}

		/// apply objects onto live solidity map
		void updateSolidityMap()
		{
			solidityMap[] = tileSolidityMap;
		
			int bx = myX-SCREEN_SIZE/2, by = myY-SCREEN_SIZE/2;
			uint map = myMap;
			uint me = playerData.MyID;
		
			for(uint sx=0;sx<SCREEN_SIZE;sx++)
				for(uint sy=0;sy<SCREEN_SIZE;sy++)
				{
					// FIXME: blocking objects under non-blocking objects are "invisible"
					auto obj = objMap[sx][sy];
					if(obj)
						if(obj.ID in globalObjects)
						{
							auto glb = globalObjects[obj.ID];
							if(objectData[glb.objType].flags & ObjectDataFlags.Blocking && !isDoor(glb.objType))
								solidityMap[map][by+sy][bx+sx] = true;
						}
				
					auto mob = mobMap[sx][sy];
					if(mob !is null)
						if(mob.ID != me)
							solidityMap[map][by+sy][bx+sx] = true;
				}
		}
	
		void addFinish(byte map, short x, short y, int penalty=0)
		{
			if(nodeMap[map][y][x] is null)
			{
				Node.makeFinishNode(map, x, y, penalty).link();
			}
		}

		struct Vector
		{
			short dx, dy;
		}

		// North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest
		const Vector[8] dirVectors = [
			{ 0, -1},
			{ 1, -1},
			{ 1,  0},			
			{ 1,  1},			
			{ 0,  1},			
			{-1,  1},			
			{-1,  0},			
			{-1, -1},
		];

		const char[][8] dirNames = [
			//"North", "NorthEast", "East", "SouthEast", "South", "SouthWest", "West", "NorthWest"
			"N", "NE", "E", "SE", "S", "SW", "W", "NW"
		];

		const char[8] dirOrder = [0, 2, 4, 6, 1, 3, 5, 7];

		bool tryWalk(byte map, short x, short y, byte dir, out short ox, out short oy)
		{
			ox = x + dirVectors[dir].dx;
			oy = y + dirVectors[dir].dy;
			if((dir&1)==0) // orthogonal
				return !solidityMap[map][oy][ox];
			else  // diagonal
				if(solidityMap[map][y][ox])
					if(solidityMap[map][oy][x])
						return false;
					else
					{
						ox=x;
						return true;
					}
				else
					if(solidityMap[map][oy][x])
					{
						oy=y;
						return true;
					}
					else
						if(solidityMap[map][oy][ox])
							return false;   // non-deterministic case
						else
							return true;    // diagonal is clear
		}

		bool tryWarpWalk(byte map, short x, short y, byte dir, out byte omap, out short ox, out short oy)
		{
			if(tryWalk(map, x, y, dir, ox, oy))
			{
				omap = map;
				// check for warps at map,ox,oy
				return true;
			}
			return false;
		}

		bool doWarpWalk(inout byte map, inout short x, inout short y, byte dir)
		{
			byte omap=map;
			short ox=x, oy=y;
			if(tryWarpWalk(map, x, y, dir, omap, ox, oy))
			{
				map=omap;
				x=ox;
				y=oy;
				return true;
			}
			else
				return false;
		}

		// destination is pointed at by dir
		// assumes destination is free
		byte[] reverseWalk(byte map, short x, short y, byte dir)
		{
			short ox = x + dirVectors[dir].dx;
			short oy = y + dirVectors[dir].dy;
			if((dir&1)==0) // orthogonal
			{
				byte[] result = [dir];
				with(dirVectors[(dir+2)%8])
					if(solidityMap[map][y+dy][x+dx])
						result ~= (dir+1)%8;
				with(dirVectors[(dir+6)%8])
					if(solidityMap[map][y+dy][x+dx])
						result ~= (dir+7)%8;
				return result;
			}
			else // diagonal
				if(solidityMap[map][y][ox] || solidityMap[map][oy][x])
					return null;
				else
					return [dir];
		}

		// initial calculation
		bool calcNodes()
		{
			short mx=myX, my=myY;
			byte mmap=myMap;
			bool reachedPlayer = false;

			int cost = 0;
			while(cost<=furthestNode)
			{
				Node* node = nodes[cost];
				while(node)
				{
					with(*node)
					{
						if(x==mx && y==my && map==mmap)
							reachedPlayer = true;
						//bool logging=(x==302)&&(y==896);
							
						for(byte dirn=0;dirn<8;dirn++)
						{
							byte sdir = dirOrder[7-dirn];
							short ox = x + dirVectors[sdir].dx;
							short oy = y + dirVectors[sdir].dy;
							if(!solidityMap[map][oy][ox])
								foreach(walkDir;reverseWalk(map, ox, oy, (sdir+4)%8))
								{
									Node(map, ox, oy, node, walkDir);
									/+/+//if(Node(map, ox, oy, node, walkDir))
										if((sdir+4)%8!=walkDir)
											Stdout(x)("x")(y)(": ")((sdir+4)%8)(" -> ")(walkDir).newline;+/
									bool hadOldNode = nodeMap[map][oy][ox] !is null;
									Node oldNode; if(hadOldNode) oldNode=*(nodeMap[map][oy][ox]);
									/+if((sdir+4)%8!=walkDir && hadOldNode && oldNode.from && oldNode.from.dir==walkDir)
										Stdout("!!!").newline;+/
									Node* result = Node(map, ox, oy, node, walkDir);
									/+if((sdir+4)%8!=walkDir && hadOldNode && oldNode.distance==distance+1 && oldNode.turns==turns+1 && oldNode.from && walkDir==oldNode.from.dir)
									{
										Stdout(result !is null);
										if(result)
											Stdout(" ")(result.turns);
										Stdout.newline;
									}+/
									if(logging)
									{
										Stdout("My dir is ")(dirNames[dir]).newline;
										Stdout("Looking ")(dirNames[sdir])(" to walk to ")(dirNames[walkDir]).newline;
										//if(hadOldNode)
										//	Stdout("OldNode is from ")(oldNode.fx)("x")(oldNode.fy)(", that node's dir is ")(dirNames[oldNode.from.dir]).newline;
										Stdout("Result: ")(result !is null).newline;
										Stdout("----------------").newline;
									}+/
								}
						}

						// TODO: look for warps TO this node
					}
					node = node.next;
				}
				cost++;
				if(reachedPlayer)
					return true;
			}
			return false; // player position not reached
		}

		/// look at all non-null neighbors;
		/// if we found a better path into a neighbor, initiate (recursively) a forward search on that neighbor too
		/// VP 2007.10.07: rewritten in pseudo-recursiveness
		void doForwardUpdate()
		{
			int cost = 0;
			while(cost<=furthestNode)
			{
				Node* node = nodes[cost];
				while(node)
				{
					with(*node)
						for(int dir=0;dir<8;dir++)
						{
							short ox = x + dirVectors[dir].dx;
							short oy = y + dirVectors[dir].dy;
							if(nodeMap[map][oy][ox])
								foreach(walkDir;reverseWalk(map, ox, oy, (dir+4)%8))
									Node(map, ox, oy, node, walkDir);
						}

						// TODO: look for warps TO this node
					node = node.next;
				}

				cost++;
			}
		}

		Node*[] badNodes;

		/// recursively expand and mark all neighbors dependant on a node as "bad"
		void markBad(Node* node, byte map, short x, short y)
		{
			//try {
			badNodes ~= node;
			node.unlink();
			node.distance = INFINITE_DISTANCE;
			assert(node.bad, "Node marked as bad isn't bad");
			for(int dir=0;dir<8;dir++)
			{
				short ox=x+dirVectors[dir].dx;
				short oy=y+dirVectors[dir].dy;
				Node* neighbor = nodeMap[map][oy][ox];
				if(neighbor)
					if(neighbor.fx==x && neighbor.fy==y && neighbor.fmap==map && !neighbor.bad)
						markBad(neighbor, map, ox, oy);
			}
			//} catch(Object o){Stdout.format("Error {} in markBad(node, {}, {}, {})", o.toUtf8, map, x, y).newline; throw new Exception("[chained]");}
		}

		void markBad(byte map, short x, short y)
		{
			Node* node = nodeMap[map][y][x];
			if(node && node.dir>=0)
				markBad(node, map, x, y);
		}

		bool[SCREEN_SIZE][SCREEN_SIZE] screenSolidity1, screenSolidity2;

		void updateSolidityAndNodes()
		{
			int bx = myX-SCREEN_SIZE/2;
			int by = myY-SCREEN_SIZE/2;
			int map = myMap;
			foreach(int y,ref row;screenSolidity1)
				row[] = solidityMap[map][by+y][bx..bx+SCREEN_SIZE];
			updateSolidityMap();
			foreach(int y,ref row;screenSolidity2)
				row[] = solidityMap[map][by+y][bx..bx+SCREEN_SIZE];
			for(int x=0;x<SCREEN_SIZE;x++)
				for(int y=0;y<SCREEN_SIZE;y++)
					if(screenSolidity1[y][x] != screenSolidity2[y][x])
					{
						if(screenSolidity1[y][x])  // block disappears
						{
							// create "bad" node
							Node* node = Node.makeBadNode(map, bx+x, by+y);
							// initiate forward search from all neighbors
							resetQueue();
							for(int dir=0;dir<8;dir++)
							{
								short ox=bx+x+dirVectors[dir].dx;
								short oy=by+y+dirVectors[dir].dy;
								Node* neighbor = nodeMap[map][oy][ox];
								if(neighbor && !solidityMap[map][oy][ox])
									neighbor.link();
							}
							doForwardUpdate();
							if(node.bad) // no neighbors could enter this node
							{
								node.unlink();
								delete node;
								nodeMap[map][by+y][bx+x] = null;
							}
						}
						else   // block appears
						{
							// for each neighbor that depended on that block, recursively expand and mark all neighbors dependant on that block/path as "bad"
							Node* node = nodeMap[map][by+y][bx+x];
							if(node)
							{
								markBad(node, map, bx+x, by+y);
								nodeMap[map][by+y][bx+x] = null;
								markBad(map, bx+x+1, by+y);
								markBad(map, bx+x-1, by+y);
								markBad(map, bx+x, by+y+1);
								markBad(map, bx+x, by+y-1);
								resetQueue();

								Node*[] badNodeNeighbors;
								foreach(badNode;badNodes)
									for(int dir=0;dir<8;dir++)
									{
										short ox=badNode.x+dirVectors[dir].dx;
										short oy=badNode.y+dirVectors[dir].dy;
										Node* neighbor = nodeMap[map][oy][ox];
										if(neighbor && !neighbor.bad && !solidityMap[map][oy][ox])
											badNodeNeighbors ~= neighbor;
									}
								foreach(neighbor;badNodeNeighbors)
									neighbor.linked = false;
								foreach(neighbor;badNodeNeighbors)
									if(!neighbor.linked)
									{
										neighbor.link();
										neighbor.linked = true;
									}

								doForwardUpdate();
								foreach(badNode;badNodes)  // in case the new block cuts off a "cave" with no other paths to the bad nodes
									if(badNode.bad)
										nodeMap[badNode.map][badNode.y][badNode.x] = null;
								badNodes = null;
							}
						}
					} 
			//debug 
		}

		byte[] actionQueue;

		import tango.text.Util;
		char[] queueToStr()
		{
			char[][] queueStrings;
			foreach(dir;actionQueue)
				queueStrings ~= dirNames[dir];
			return "[" ~ queueStrings.join(", ") ~ "]";
		}
	}

	override void execute()
	{
		Time startTime = Clock.now;
		int steps = 0;

		updateMap();

		//if(nodes[0] is null)
		debug Stdout("Starting furthestNode is ")(furthestNode).newline;
		if(furthestNode<0)
		{
			if(allocated && nodeMap[myMap][myY][myX])
			{
				Stdout("Resuming last trajectory").newline;
				actionQueue = null;
				goto resume;
			}
			else
				throw new Exception("No destination is set!");
		}
		
		if(!calcNodes())
			throw new Exception("Can't trace initial path to player");

		int stepPenalty()
		{
			if(playerData.Weight>playerData.MaxWeight*11/10)
				return 4;
			else
			if(playerData.Weight>playerData.MaxWeight)
				return 2;
			else
				return 1;
		}

		void stepDelay()
		{
			steps++;
			while(Clock.now < startTime + steps * TimeSpan.millis(STEP_DELAY))
				wait();
		}

	resume:
		scope(exit) furthestNode = -1;
		
		short tx, ty;
		int stallTimer=0; // this timer measures the time we wait for the action queue to be accomplished when we don't have any commands to be issued - that is, after all the commands to reach destination have been sent. In case some commands from the final queue get lost, a timeout will trigger and re-send the commands (by clearing the expected action queue).
		while(true)
		{
			updateSolidityAndNodes();

			short x=myX, y=myY; byte map=myMap;
			  	tx=x,  ty=y ; byte tmap=map ;
			foreach(dir;actionQueue)
				doWarpWalk(tmap, tx, ty, dir);
			debug Stdout.format("Current: {}x{}  Queue: {}  Projected: {}x{}  ", x, y, queueToStr(), tx, ty);
			
			Node* node = nodeMap[tmap][ty][tx];
			if(!node)
				throw new Exception("In unreachable node");
			debug Stdout.format("Distance: {}", node.distance).newline;
			
			if(node.dir>=0)  // walk this way
			{
				stallTimer = 0;
				short dx, dy; byte dmap;
				if(!tryWarpWalk(map, tx, ty, node.dir, dmap, dx, dy))
					throw new Exception("Path is blocked...");
				
				// open door, if any
				int sx=dx-myX+SCREEN_SIZE/2;
				int sy=dy-myY+SCREEN_SIZE/2;
				if(map==dmap) // no cross-map door opening
					if(sx>=0 && sx<SCREEN_SIZE && sy>=0 && sy<SCREEN_SIZE)
						if(objMap[sx][sy])
							if(objMap[sx][sy].ID in globalObjects)
								if(isDoor(globalObjects[objMap[sx][sy].ID].objType))
								{
									Stdout("[PathFinder] Opening door").newline;
									playerData.UseObject(objMap[sx][sy].ID);
									stepDelay();
								}
				
				Stdout("[PathFinder] Walking "~dirNames[node.dir]).newline;
				actionQueue ~= [node.dir];
				for(int i=0;i<stepPenalty();i++)
				{
					clientServices.SendWalk(cast(WalkDirection)(node.dir+1));
					stepDelay();
				}
			}
			else
				if(actionQueue.length==0)
					break;  // done!
				else
				{
					stallTimer++;
					if(stallTimer>10)
					{
						Stdout("[PathFinder] Stalled at end of path, unstalling").newline;
						actionQueue = null;
						continue;  // start walking the correct direction again
					}
					stepDelay(); // wait 
				}

			short nx=myX, ny=myY;
			byte nmap=myMap;
			int origQueueLength = actionQueue.length;
			while(nx!=x || ny!=y || nmap!=map)
			{
				if(actionQueue.length==0)
				{
					Stdout("[PathFinder] Got off track!").newline;
					// wait for movement to stop
					for(int i=0;i<origQueueLength;i++)
						stepDelay();
					Stdout("[PathFinder] Done waiting").newline;
					break;
				}
				else
				{
					doWarpWalk(map, x, y, actionQueue[0]);
					actionQueue = actionQueue[1..$];
					stallTimer = 0;
				}
			}
			while(actionQueue.length)    // remove actions that have no effect
			{
				if(tryWarpWalk(map, x, y, actionQueue[0], nmap, nx, ny))  // walk successful
					break;
				actionQueue = actionQueue[1..$];   // walk failed - remove from queue
			}
			
			//Stdout.format("Action Queue length is {}", actionQueue.length).newline;
		}

		// wait for movement to stop
		//for(int i=0;i<actionQueue.length+1;i++)
		//	stepDelay();
		while(myX!=tx || myY!=ty)
			wait();
		
	}
}

PathFinder pathFinder;

static this()
{
	programs ~= pathFinder = new PathFinder;
}
