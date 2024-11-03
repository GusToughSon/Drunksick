module mainui;

private import dfl.all;

import tango.math.Math;
import tango.text.convert.Integer;
import tango.text.convert.Layout;
import tango.text.Ascii;
import tango.text.Util;
import tango.stdc.stringz;
import tango.time.Clock;
import tango.core.Thread;
import tango.stdc.stdlib : exit;
import win32.windows;
import win32.tlhelp32;
import customGC;

import commondata;
import autotarget;
import autograbber;
import autoheal;
import autoeater;
import messagelog;
import autograbbercfg;
import dranscript;
import mapsync;
import bpbugfix;
import timing;
import pathfinder;
import graphics;
import gametime;
import hotkeys;
//import logging;

import codetools;

extern(Windows) HWND GetConsoleWindow();

class MainUI: dfl.form.Form
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.groupbox.GroupBox groupBoxPatches;
	dfl.button.CheckBox cbFogOfWar;
	dfl.button.CheckBox cbCavernMap;
	dfl.groupbox.GroupBox groupBoxAutomates;
	dfl.button.CheckBox cbAutoTarget;
	dfl.button.CheckBox cbAutoGrabber;
	dfl.button.Button btnAutoGrabberProperties;
	dfl.groupbox.GroupBox groupBoxProgram;
	dfl.button.Button btnProgramProperties;
	dfl.combobox.ComboBox cbProgram;
	dfl.button.Button btnStartStop;
	dfl.button.CheckBox cbAutoHeal;
	dfl.button.CheckBox cbAutoEater;
	dfl.groupbox.GroupBox groupBoxSnooper;
	dfl.listbox.ListBox lbSnooper;
	dfl.button.CheckBox cbMMBHides;
	dfl.groupbox.GroupBox groupBoxSettings;
	dfl.label.Label lbSpeed;
	dfl.progressbar.ProgressBar pbSpeed;
	dfl.button.CheckBox cbSounds;
	dfl.button.CheckBox cbMapSync;
	dfl.button.CheckBox cbLog;
	//~Entice Designer variables end here.
	dfl.timer.Timer mainTimer;
	ContextMenu mSnoop, mAutoGrabberCfg;
	MenuItem miHide, miGrabItemList, miGrabHax;
	
	Layout!(char) formatter;
	
	this()
	{
		formatter = new Layout!(char);
		
		initializeMainUI();
		initializeMainCustomUI();
		
		// Other MainUI initialization code here.
		if(playerData !is null && !playerData.AttackMode) Stdout("Reminder: Don't forget to turn on [A]ttack mode for AutoTarget and AutoGrabber!").newline;
		messageHandlers ~= &messageHandler;

		with(mainTimer=new dfl.timer.Timer)
		{
			interval = 50;
			tick ~= &mainTimerTick;
			start();
		}
	}
	
final:
	private void initializeMainUI()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.3 code begins here.
		//~DFL Form
		formBorderStyle = dfl.all.FormBorderStyle.FIXED_SINGLE;
		maximizeBox = false;
		text = "DrunkSick";
		clientSize = dfl.all.Size(280, 209);
		//~DFL dfl.groupbox.GroupBox=groupBoxPatches
		groupBoxPatches = new dfl.groupbox.GroupBox();
		groupBoxPatches.name = "groupBoxPatches";
		groupBoxPatches.text = "Patches / Hooks";
		groupBoxPatches.bounds = dfl.all.Rect(8, 0, 130, 52);
		groupBoxPatches.parent = this;
		//~DFL dfl.button.CheckBox=cbFogOfWar
		cbFogOfWar = new dfl.button.CheckBox();
		cbFogOfWar.name = "cbFogOfWar";
		cbFogOfWar.text = "OmniVision";
		cbFogOfWar.checkState = dfl.all.CheckState.CHECKED;
		cbFogOfWar.autoCheck = true;
		cbFogOfWar.bounds = dfl.all.Rect(12, 15, 107, 15);
		cbFogOfWar.parent = groupBoxPatches;
		//~DFL dfl.button.CheckBox=cbCavernMap
		cbCavernMap = new dfl.button.CheckBox();
		cbCavernMap.name = "cbCavernMap";
		cbCavernMap.text = "Cavern Auto-map";
		cbCavernMap.autoCheck = false;
		cbCavernMap.bounds = dfl.all.Rect(12, 31, 107, 15);
		cbCavernMap.parent = groupBoxPatches;
		//~DFL dfl.groupbox.GroupBox=groupBoxAutomates
		groupBoxAutomates = new dfl.groupbox.GroupBox();
		groupBoxAutomates.name = "groupBoxAutomates";
		groupBoxAutomates.text = "Automates";
		groupBoxAutomates.bounds = dfl.all.Rect(8, 56, 130, 148);
		groupBoxAutomates.parent = this;
		//~DFL dfl.button.CheckBox=cbAutoTarget
		cbAutoTarget = new dfl.button.CheckBox();
		cbAutoTarget.name = "cbAutoTarget";
		cbAutoTarget.text = "AutoTarget";
		cbAutoTarget.checkState = dfl.all.CheckState.CHECKED;
		cbAutoTarget.bounds = dfl.all.Rect(12, 15, 107, 15);
		cbAutoTarget.parent = groupBoxAutomates;
		//~DFL dfl.button.CheckBox=cbAutoGrabber
		cbAutoGrabber = new dfl.button.CheckBox();
		cbAutoGrabber.name = "cbAutoGrabber";
		cbAutoGrabber.text = "AutoGrabber";
		cbAutoGrabber.bounds = dfl.all.Rect(12, 31, 83, 15);
		cbAutoGrabber.parent = groupBoxAutomates;
		//~DFL dfl.button.Button=btnAutoGrabberProperties
		btnAutoGrabberProperties = new dfl.button.Button();
		btnAutoGrabberProperties.name = "btnAutoGrabberProperties";
		btnAutoGrabberProperties.text = "...";
		btnAutoGrabberProperties.bounds = dfl.all.Rect(100, 31, 19, 15);
		btnAutoGrabberProperties.parent = groupBoxAutomates;
		//~DFL dfl.groupbox.GroupBox=groupBoxProgram
		groupBoxProgram = new dfl.groupbox.GroupBox();
		groupBoxProgram.name = "groupBoxProgram";
		groupBoxProgram.text = "Program";
		groupBoxProgram.bounds = dfl.all.Rect(4, 79, 122, 64);
		groupBoxProgram.parent = groupBoxAutomates;
		//~DFL dfl.button.Button=btnProgramProperties
		btnProgramProperties = new dfl.button.Button();
		btnProgramProperties.name = "btnProgramProperties";
		btnProgramProperties.text = "...";
		btnProgramProperties.bounds = dfl.all.Rect(96, 18, 19, 15);
		btnProgramProperties.parent = groupBoxProgram;
		//~DFL dfl.combobox.ComboBox=cbProgram
		cbProgram = new dfl.combobox.ComboBox();
		cbProgram.name = "cbProgram";
		cbProgram.dropDownStyle = dfl.all.ComboBoxStyle.DROP_DOWN_LIST;
		cbProgram.bounds = dfl.all.Rect(8, 15, 84, 21);
		cbProgram.parent = groupBoxProgram;
		//~DFL dfl.button.Button=btnStartStop
		btnStartStop = new dfl.button.Button();
		btnStartStop.name = "btnStartStop";
		btnStartStop.bounds = dfl.all.Rect(8, 39, 107, 20);
		btnStartStop.parent = groupBoxProgram;
		//~DFL dfl.button.CheckBox=cbAutoHeal
		cbAutoHeal = new dfl.button.CheckBox();
		cbAutoHeal.name = "cbAutoHeal";
		cbAutoHeal.text = "AutoHeal";
		cbAutoHeal.checkState = dfl.all.CheckState.CHECKED;
		cbAutoHeal.bounds = dfl.all.Rect(12, 47, 107, 15);
		cbAutoHeal.parent = groupBoxAutomates;
		//~DFL dfl.button.CheckBox=cbAutoEater
		cbAutoEater = new dfl.button.CheckBox();
		cbAutoEater.name = "cbAutoEater";
		cbAutoEater.text = "AutoEater";
		cbAutoEater.checkState = dfl.all.CheckState.CHECKED;
		cbAutoEater.bounds = dfl.all.Rect(12, 63, 107, 15);
		cbAutoEater.parent = groupBoxAutomates;
		//~DFL dfl.groupbox.GroupBox=groupBoxSnooper
		groupBoxSnooper = new dfl.groupbox.GroupBox();
		groupBoxSnooper.name = "groupBoxSnooper";
		groupBoxSnooper.text = "Snooper";
		groupBoxSnooper.bounds = dfl.all.Rect(144, 0, 128, 120);
		groupBoxSnooper.parent = this;
		//~DFL dfl.listbox.ListBox=lbSnooper
		lbSnooper = new dfl.listbox.ListBox();
		lbSnooper.name = "lbSnooper";
		lbSnooper.horizontalScrollbar = true;
		lbSnooper.bounds = dfl.all.Rect(4, 16, 120, 82);
		lbSnooper.cursor = Cursors.hand;
		lbSnooper.parent = groupBoxSnooper;
		//~DFL dfl.button.CheckBox=cbMMBHides
		cbMMBHides = new dfl.button.CheckBox();
		cbMMBHides.name = "cbMMBHides";
		cbMMBHides.text = "Middle button hides";
		cbMMBHides.bounds = dfl.all.Rect(4, 101, 115, 15);
		cbMMBHides.parent = groupBoxSnooper;
		//~DFL dfl.groupbox.GroupBox=groupBoxSettings
		groupBoxSettings = new dfl.groupbox.GroupBox();
		groupBoxSettings.name = "groupBoxSettings";
		groupBoxSettings.text = "Settings";
		groupBoxSettings.bounds = dfl.all.Rect(144, 120, 128, 84);
		groupBoxSettings.parent = this;
		//~DFL dfl.label.Label=lbSpeed
		lbSpeed = new dfl.label.Label();
		lbSpeed.name = "lbSpeed";
		lbSpeed.text = "Speed: Normal";
		lbSpeed.textAlign = dfl.all.ContentAlignment.TOP_CENTER;
		lbSpeed.bounds = dfl.all.Rect(10, 16, 110, 13);
		lbSpeed.cursor = Cursors.hand;
		lbSpeed.parent = groupBoxSettings;
		//~DFL dfl.progressbar.ProgressBar=pbSpeed
		pbSpeed = new dfl.progressbar.ProgressBar();
		pbSpeed.name = "pbSpeed";
		pbSpeed.bounds = dfl.all.Rect(10, 31, 110, 15);
		pbSpeed.parent = groupBoxSettings;
		//~DFL dfl.button.CheckBox=cbSounds
		cbSounds = new dfl.button.CheckBox();
		cbSounds.name = "cbSounds";
		cbSounds.text = "&Sounds";
		cbSounds.checkState = dfl.all.CheckState.CHECKED;
		cbSounds.bounds = dfl.all.Rect(10, 48, 62, 15);
		cbSounds.cursor = Cursors.hand;
		cbSounds.parent = groupBoxSettings;
		//~DFL dfl.button.CheckBox=cbMapSync
		cbMapSync = new dfl.button.CheckBox();
		cbMapSync.name = "cbMapSync";
		cbMapSync.enabled = false;
		cbMapSync.text = "Online map sync";
		cbMapSync.bounds = dfl.all.Rect(10, 63, 110, 15);
		cbMapSync.parent = groupBoxSettings;
		//~DFL dfl.button.CheckBox=cbLog
		cbLog = new dfl.button.CheckBox();
		cbLog.name = "cbLog";
		cbLog.text = "&Log";
		cbLog.bounds = dfl.all.Rect(74, 48, 46, 15);
		cbLog.cursor = Cursors.hand;
		cbLog.parent = groupBoxSettings;
		//~Entice Designer 0.8.3 code ends here.
	}
	
	void initializeMainCustomUI()
	{
		this.closed ~= &mainFormClosed;
		
		cbFogOfWar.click ~= &refocus;
		cbCavernMap.click ~= &cbCavernMapClick;
		cbAutoTarget.click ~= &refocus;
		cbAutoGrabber.click ~= &refocus;
		cbAutoHeal.click ~= &refocus;
		cbAutoEater.click ~= &refocus;
		cbMapSync.click ~= &refocus;
		btnAutoGrabberProperties.click ~= &btnAutoGrabberPropertiesClick;
		cbLog.click ~= &cbLogClick;
		cbLog.mouseDown ~= &cbLogMouseDown;
		
		pbSpeed.maximum = pbSpeed.width-4;
		pbSpeed.value = pbSpeed.maximum/2;
		pbSpeed.step = 1;
		pbSpeed.mouseDown ~= &pbSpeedMouseDown;
		pbSpeed.mouseMove ~= &pbSpeedMouseDown;
		pbSpeed.cursor = Cursors.hand;
		
		mSnoop = new ContextMenu;
		miHide = new MenuItem;
		miHide.text = "&Hide";
		miHide.click ~= &miHideClick;
		mSnoop.menuItems.add(miHide);
		lbSnooper.contextMenu = mSnoop;
		lbSnooper.click ~= &lbSnooperClick;
		
		mAutoGrabberCfg = new ContextMenu;
		miGrabItemList = new MenuItem;
		miGrabItemList.text = "&Items to grab...";
		miGrabItemList.click ~= &miGrabItemListClick;
		mAutoGrabberCfg.menuItems.add(miGrabItemList);
		miGrabHax = new MenuItem;
		miGrabHax.text = "&Hax mode";
		miGrabHax.click ~= &miToggleClick;
		mAutoGrabberCfg.menuItems.add(miGrabHax);
		
		foreach(program;programs)
			cbProgram.items.add(program);
		btnProgramProperties.click ~= &btnProgramPropertiesClick;
		btnStartStop.click ~= &btnStartStopClick;
	}

	void cbCavernMapClick(Object sender, EventArgs ea)
	{
		if(cbCavernMap.checked)
			unpatch(CavernAutoMap);
		else
			patch(CavernAutoMap);
		cbCavernMap.checked = isPatched(CavernAutoMap);
		focusGame();
	}

	void pbSpeedMouseDown(Object sender, MouseEventArgs ea)
	{
		if(ea.button==MouseButtons.LEFT)
		{
			pbSpeed.value = ea.x-4;
			float pos = (cast(float)(pbSpeed.value)/(pbSpeed.maximum+1));
			speed = tan(pos*(PI/2));
			char[] s;
			
			/**/ if(speed<.1)
				s = "Zzzzz...";
			else if(speed<.25)
				s = "Paranoia";
			else if(speed<.5)
				s = "Slow";
			else if(speed<.75)
				s = "Careful";
			else if(speed<1.1)
				s = "Normal";
			else if(speed<1.75)
				s = "Fast";
			else if(speed<2.50)
				s = "Turbo";
			else if(speed<5.00)
				s = "Ludicrious";
			else if(speed<10)
				s = "Ridiculous";
			else
				s = "Insane";
			lbSpeed.text = "Speed: " ~ s;
			
			mainTimer.interval = cast(int)round(50/speed);
		}
	}
	
	void refocus(Object sender, EventArgs ea)
	{
		focusGame();
	}

	void btnAutoGrabberPropertiesClick(Object sender, EventArgs ea)
	{
		mAutoGrabberCfg.show(this, Cursor.position);
	}
	
	void miToggleClick(MenuItem sender, EventArgs ea)
	{
		sender.checked = !sender.checked;
	}

	void miGrabItemListClick(MenuItem sender, EventArgs ea)
	{
		(new AutoGrabberCfg).showDialog();
	}
	
	void cbLogClick(Object sender, EventArgs ea)
	{
		ShowWindow(GetConsoleWindow(), cbLog.checked?SW_SHOW:SW_HIDE);
		if(!cbLog.checked)
			focusGame();
	}

	void cbLogMouseDown(Object sender, MouseEventArgs ea)
	{
		if(ea.button == MouseButtons.RIGHT)
		{
			CONSOLE_SCREEN_BUFFER_INFO csbiInfo;
			if(GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbiInfo))
			{
				CHAR_INFO[] data = new CHAR_INFO[csbiInfo.dwSize.X*csbiInfo.dwSize.Y];
				SMALL_RECT sm = SMALL_RECT(0, 0, csbiInfo.dwSize.X, csbiInfo.dwSize.Y);
				WriteConsoleOutputA(GetStdHandle(STD_OUTPUT_HANDLE), data.ptr, csbiInfo.dwSize, COORD(0,0), &sm);
				SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), COORD(0,0));
			}
			focusGame();
		}
	}

	void hideObject(int ID)
	{
		globalObjects[ID].flags &= ~ObjectFlags.Visible;
	}
	
	void miHideClick(Object sender, EventArgs ea)
	{
		if(lbSnooper.selectedIndex<0)
			throw new Exception("No item is selected");
		if(lbSnooper.selectedIndex>=lbSnooper.items.count)
			throw new Exception("Invalid selected item");
		assert(snooperCache.length == lbSnooper.items.count);
		hideObject(snooperCache[lbSnooper.selectedIndex].obj.ID);
		updateSnooper(true);
	}
	
	void lbSnooperClick(Object sender, EventArgs ea)
	{
		if(lbSnooper.selectedIndex>=0 && snooperCache[0] !is null)
			mSnoop.show(lbSnooper, Cursor.position);
	}

	void stopPrograms()
	{
		auto cp = currentProgram();
		if(cp !is null && cp.running)
			cp.stop();
	}

	void disableAll()
	{
		cbAutoTarget.checked = false;
		cbAutoGrabber.checked = false;
		//cbAutoHeal.checked = false;
		stopPrograms();
	}

	void messageHandler(MessageType type)
	{
		switch(type)
		{
			case MessageType.None:
				return;
			case MessageType.Death:
				if(playerData.Health!=0)
				{
					// we got here before the handler in checkStatus
					lastPlayerData.Health = 0;
					if(!isGameFocused() || idleTime.minutes > 2)
					{
						Stdout("We died, disabling AutoGrabber/AutoHeal/Programs").newline;
						cbAutoGrabber.checked = false;
						cbAutoHeal.checked = false;
						if(cbSounds.checked) return playSound("Sounds/Death.wav");
					}
				}
				break;
			case MessageType.Chat:
			case MessageType.WhisperChat:
				if(!isGameFocused() || idleTime.minutes > 2)
				{
					Stdout("Chat line detected, disabling automations").newline;
					disableAll();
					if(cbSounds.checked) playSound("Sounds/Message.wav");
				}
				break;
			case MessageType.ContainerFull:
				if(cbAutoGrabber.checked)
				{
					Stdout("Container full, disabling AutoGrabber").newline;
					cbAutoGrabber.checked = false;
					if(cbSounds.checked) playSound("Sounds/ContainerFull.wav");
				}
				break;
			case MessageType.HarvestReady:
				if(!isGameFocused() && cbSounds.checked)
				{
					auto cp = currentProgram();
					if(cp is null || cp.name!="Plant+Harvest" || !cp.running)
					{
						static Time lastUse;
						int timeElapsed = (Clock.now - lastUse).seconds;
						if(timeElapsed>60)
							playSound("Sounds/Harvest.wav");
						else
							playSound("Sounds/Harvest2.wav");
						lastUse = Clock.now;
					}
				}
				break;
			case MessageType.SkillLevelUp:
				if(cbSounds.checked) playSound("Sounds/SkillLevelUp.wav");
				break;
			case MessageType.Unknown:
				if(!isGameFocused() || idleTime.minutes > 2)
				{
					Stdout("Unrecognized log message detected, disabling all automations").newline;
					disableAll();
					if(cbSounds.checked) playSound("Sounds/Unknown.wav");
				}
				break;
			default:
				break;
		}
	}

	PlayerData lastPlayerData;
	
	void checkStatus()
	{
		scope(exit) lastPlayerData = *playerData;
		if(playerData.Health==0 && lastPlayerData.Health!=0)
			if(!isGameFocused())
			{
				Stdout("We died, disabling AutoGrabber/AutoHeal").newline;
				cbAutoGrabber.checked = false;
				cbAutoHeal.checked = false;
				if(cbSounds.checked) return playSound("Sounds/Death.wav");
			}
		if(playerData.MaxHealth>0 && lastPlayerData.Health>playerData.MaxHealth/5 && playerData.Health<=playerData.MaxHealth/5)
			if(!isGameFocused())
				if(cbSounds.checked) return playSound("Sounds/LowHP.wav");
		if(lastPlayerData.Sta>10 && playerData.Sta<=10)
			//if(!isGameFocused())
				if(cbSounds.checked) return playSound("Sounds/LowSta1.wav");
		if(lastPlayerData.Sta>5 && playerData.Sta<=5)
			//if(!isGameFocused())
				if(cbSounds.checked) return playSound("Sounds/LowSta2.wav");
		if(lastPlayerData.Sta>0 && playerData.Sta==0)
			//if(!isGameFocused())
				if(cbSounds.checked) return playSound("Sounds/LowSta3.wav");
		if(lastPlayerData.Level>0 && playerData.Level==lastPlayerData.Level+1)
			if(cbSounds.checked) return playSound("Sounds/LevelUp.wav");
		
		//if(playerData.Health>0 && playerData.Health<lastPlayerData.Health)
		//	if(cbSounds.checked) return playSound("Sounds/HitTest.wav");

		if(playerData.Sta==0 && idleTime.minutes > 5)
		{
			Stdout("Unattended starvation trigger!").newline;
			exit(0xF00D);
		}
	}

	char[] lastSnoopError;
	SnooperItem[] snooperCache;

	void snoopError(char[] msg)
	{
		if(lastSnoopError==msg) return;
		lbSnooper.items.clear;
		lbSnooper.items.add(msg);
		snooperCache = [null];
		groupBoxSnooper.text = "Snooper [error]";
		lastSnoopError = msg;
	}
	
	static class SnooperItem
	{
		GlobalObject obj;
		
		this(GlobalObject o)
		{
			obj = o;
		}
		
		override char[] toString()
		{
			return 
				objectData[obj.objType].nameStr ~ 
				//(obj.flags&ObjectFlags.NPC ? "" : " [NPC]") ~ 
				(obj.flags&ObjectFlags.Visible ? "" : " (hidden)") ~ 
				(obj.MaxHealth ? .formatter(" [{}/{}]", obj.Health, obj.MaxHealth) : "");
		}
		
		override int opEquals(Object s)
		{
			if(s is null)
				return 0;
			else
				return (cast(SnooperItem)s).obj.ID == obj.ID;
		}
	}

	void updateSnooper(bool force=false)
	{
		if(!force && GetKeyState(VK_SCROLL)&1) 
		{
			if(groupBoxSnooper.text[0..7]=="Snooper")
				groupBoxSnooper.text = "LOCKED" ~ groupBoxSnooper.text[7..$];
			return;
		}
		try
		{
			int x, y;
			if(!readMouseScreenCoords(x, y))
				throw new Exception("Mouse not on map");
			int gx=x-SCREEN_SIZE/2+myX, gy=y-SCREEN_SIZE/2+myY;
			lastSnoopError = null;
			char[] caption = formatter("[{},{}] C{:X} #{}", gx, gy, getChunk(myMap, gx/16, gy/16), getTile(myMap, gx, gy));
			if(groupBoxSnooper.text!=caption)
				groupBoxSnooper.text=caption;
					
			SnooperItem[] list;
			foreach(ref obj;*objectList)
				if(obj.flags&ObjectFlags.OnMap && obj.x==gx && obj.y==gy)
					list ~= new SnooperItem(obj);
			if(list!=snooperCache)
			{
				lbSnooper.items.clear;
				foreach(s;list)
					lbSnooper.items.add(s);
				snooperCache = list;
			}
		}
		catch(Object e)
		{
			snoopError(e.toString);
		}
	}

	Program currentProgram()
	{
		if(cbProgram.selectedIndex<0)
			return null;
		else
			return programs[cbProgram.selectedIndex];
	}

	bool programIsRunning()
	{
		if(cbProgram.selectedIndex<0)
			return false;
		else
			return currentProgram.running;
	}

	void selectProgram(Program newProgram)
	{
		foreach(i,program;programs)
			if(program is newProgram)
				return cbProgram.selectedIndex = i;
		throw new Exception("Can't find program");
	}

	void selectProgram(char[] newProgramName)
	{
		foreach(i,program;programs)
			if(program.name==newProgramName)
				return cbProgram.selectedIndex = i;
		throw new Exception("Can't find program");
	}

	void updatePrograms()
	{
		auto cp = currentProgram();
		cbProgram.enabled = cp is null || !cp.running;
		btnProgramProperties.enabled = cp !is null;
		btnStartStop.enabled = cp !is null && (!cp.running || !cp.stopping);
		char[] text;
		if(cp is null)
			text = "Select program";
		else
		if(cp.stopping)
			text = "Stopping...";
		else
		if(cp.running)
			text = "Stop";
		else
			text = "Start";
		if(text!=btnStartStop.text)
			btnStartStop.text = text;
	}
	
	void btnProgramPropertiesClick(Object sender, EventArgs ea)
	{
		try
			currentProgram.configure();
		catch(Object o)
			msgBox(o.toString(), "Program Configuration Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		updatePrograms();
	}
	
	void btnStartStopClick(Object sender, EventArgs ea)
	{
		try
			if(currentProgram.running)
				currentProgram.stop();
			else
			{
				currentProgram.start();
				if(currentProgram.result)
					msgBox(currentProgram.result.toString(), "Program Result", MsgBoxButtons.OK);
			}
		catch(Object o)
			msgBox(o.toString(), "Program Start/Stop Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		updatePrograms();
	}

	void doClickHide()
	{
		static bool wasPressed = false;
		bool pressed = GetKeyState(VK_MBUTTON)<0;
		scope(exit) wasPressed = pressed;
		if(pressed && !wasPressed && isGameFocused)
		{
			int x, y;
			if(!readMouseScreenCoords(x, y)) return;
			if(mobMap[x][y] !is null) return hideObject(mobMap[x][y].ID);
			if(objMap[x][y] !is null) return hideObject(objMap[x][y].ID);
			MessageBeep(0);
		}
	}

	void checkMapUpdate()
	{
		static Time lastUpdate;
		if(!cbMapSync.checked || !cbCavernMap.checked) return;
		if(secondsSince(lastUpdate)<30)
			return;
		lastUpdate = Clock.now;
		try
			beginMapUpdate();
		catch (Object e)
			Stdout("Map Error: "~e.toString).newline;
	}
	
	void mainTimerTick(Timer sender, EventArgs ea)
	{
		static char[] oldError;
		try
		{
			updateDransik();
			
			updatePrograms();
			checkMapUpdate();

			readGameData();
			cbCavernMap.checked = isPatched(CavernAutoMap);
			cbCavernMap.enabled = true;
			cbMapSync.enabled = cbCavernMap.checked;
			updateSnooper();
			if(cbMMBHides.checked)    doClickHide();

			bpBugFix();
			checkStatus();
			if(playerData.Health <= 0) return;

			// --- run actions ---

			if(waiting()) return /*Stdout("Waiting...").newline*/;
			if(cbAutoHeal.checked)    if(autoHeal()) return;
			if(cbAutoEater.checked)   if(autoEater()) return;
			if(playerData.AttackMode)
			{
			if(cbAutoTarget.checked)  if(autoTarget()) return;
			if(cbAutoGrabber.checked) if(autoGrab(miGrabHax.checked)) return;
			}
			if(programIsRunning)      currentProgram.step();
			oldError = null;
		}
		catch (Object e)
		{
			if(e.toString!=oldError)
				Stdout("Error: "~e.toString).newline;
			oldError = e.toString;
			snoopError(e.toString);
			cbCavernMap.checkState = CheckState.INDETERMINATE;
			cbCavernMap.enabled = false;
		}
	}
	
	void mainFormClosed(Object sender, EventArgs ea)
	{
		if(programIsRunning)
			currentProgram.stop();
		//mainForm.dispose();
		Stdout("Main form closed").newline;
		if(cursorShown)
			ShowCursor(false);
		done = true;
	}
}

void updateDransik()
{
	callCode(cast(void*)Offsets.UpdateCodeStart, cast(void*)Offsets.UpdateCodeEnd, cast(int)mainWindow);
}

alias dransik.TextBox TextBox;

TextBox* getTextBox()
{
	auto gump = guiEventDispatcher.FocusedGump;
	if(gump && cast(int)gump.vtbl == Offsets.TextBoxVtable)
		return cast(TextBox*)gump;
	else
		return null;
}

void onKey(ubyte key)
{
	auto textbox = getTextBox;
	try
		switch(key)
		{
			case VK_PAUSE:
				auto cp = mainForm.currentProgram();
				if(cp !is null && cp.running)
					cp.stop();
				else
				{
					mainForm.cbAutoTarget.checked = false;
					mainForm.cbAutoGrabber.checked = false;
					mainForm.cbAutoHeal.checked = false;
				}
				return;
			case 'T':
				if(GetKeyState(VK_MENU)<0)
					mainForm.cbAutoTarget.checked = !mainForm.cbAutoTarget.checked;
				return;
			case 'G':
				if(GetKeyState(VK_MENU)<0)
					mainForm.cbAutoGrabber.checked = !mainForm.cbAutoGrabber.checked;
				return;
			case 'H':
				if(GetKeyState(VK_MENU)<0)
					mainForm.cbAutoHeal.checked = !mainForm.cbAutoHeal.checked;
				return;
			case 'E':
				if(GetKeyState(VK_MENU)<0)
					mainForm.cbAutoEater.checked = !mainForm.cbAutoEater.checked;
				return;
			case 'A':
				if(GetKeyState(VK_MENU)<0)
					startProgram("GrabAll");
				return;
			case VK_RETURN:
				if(GetKeyState(VK_CONTROL)<0 && textbox !is null)
					textbox.append("\x0D\0");
				return;
			case VK_INSERT:
				if(GetKeyState(VK_SHIFT)<0 && textbox !is null)
					textbox.append(cast(char[])Clipboard.getText());
				else
				if(GetKeyState(VK_CONTROL)<0 && textbox !is null)
					Clipboard.setText(cast(ubyte[])textbox.text, true);
				return;
			case 'C':
				if(GetKeyState(VK_CONTROL)<0 && textbox !is null)
					Clipboard.setText(cast(ubyte[])textbox.text, true);
				return;
			case 'V':
				if(GetKeyState(VK_CONTROL)<0 && textbox !is null)
					textbox.append(cast(char[])Clipboard.getText());
				return;
			default:
				return;
		}
	catch(Object o)
		Stdout("onKey Error: ")(o).newline;
}

bool initialized, done;
MainUI mainForm;
bool cursorShown = false;

void manageCursor()
{
	bool show = true;
	POINT pos;
	GetCursorPos(&pos);
	HWND wnd = WindowFromPoint(pos);
	char[16] buf;
	GetClassNameA(wnd, &buf[0], buf.length);
	if(buf[0..7]=="DRANSIK")
		if(DefWindowProcA(wnd, WM_NCHITTEST, 0, pos.x+(pos.y<<16))==HTCLIENT)
			show = false;
	if(cursorShown != show)
		ShowCursor(show);
	cursorShown = show;
}

char[] mixPrintValues(char[] title, char[][] names)
{
	char[] s = `Stdout.format("` ~ title ~ `: `;
	foreach(name;names)
		s ~= name ~ `={} `;
	s ~= `"`;
	foreach(name;names)
		s ~= `, ` ~ name;
	s ~= `).newline;`;
	return s;
}

bool reEnableAttackMode;

void hkMessageLoop(Context* context)
{
	if(!initialized)
	{
		//Thread.registerExternalThread();
		thread_attachThis();
		customGCstart();
		OleInitialize(null);
		keyHandler = &onKey;

		mainForm = new MainUI();
		mainForm.show();
		initialized = true;
	}
	scheduledGarbageCollect();
	updateKeyboard();
	manageCursor();
	// extendTextBox();
	checkAutoMapRightClick();
	processGameTime();
	if(reEnableAttackMode)
	{
		playerData.AttackMode = true;
		reEnableAttackMode = false;
	}
}

/+ DO NOT EVER REENABLE THIS CODE
void extendTextBox()
{
	auto textbox = getTextBox;
	if(textbox)
		textbox.MaxLength = 0x200;
}+/

void startProgram(char[] name)
{
	if(mainForm.programIsRunning)
		mainForm.currentProgram.stopAndWait();
	mainForm.selectProgram(name);
	mainForm.currentProgram.start();
}

void startPathFinder(int x, int y)
{
	if(mainForm.programIsRunning)
		mainForm.currentProgram.stopAndWait();
	mainForm.selectProgram(pathFinder);
	pathFinder.reset();
	pathFinder.addFinish(myMap, x, y);
	pathFinder.start();
}

void hkPlayerDataClick(Context* context)
{
	//Stdout("Click").newline;
	auto event = cast(MouseEvent*) context.stack[1];
	//with(*event)
	//	mixin(mixPrintValues("Click", ["EventType", "X", "Y", "fC", "f10", "Pressed", "DoubleClick", "Shift", "f20", "HelpCursor"]));
	
	// do not attempt to attack peaceful NPCs if TargetProtection is on
	if(event.Pressed && /+event.DoubleClick && +/playerData.TargetProtection && playerData.AttackMode)
	{
		int x = (event.X-8)/16;
		int y = (event.Y-8)/16;
		//Stdout(x)("x")(y).newline;
		if(x>=0 && x<SCREEN_SIZE && y>=0 && y<SCREEN_SIZE)
		{
			readGameData();
			auto mob = mobMap[x][y];
			//Stdout(mob).newline;
			if(mob !is null && mob.ID in globalObjects)
			{
				//Stdout(mob.ID).newline;
				if(!globalObjects[mob.ID].attackable)
				{
					playerData.AttackMode = false;
					reEnableAttackMode = true;
					//mouse.attackCursor = false;
				}
			}
		}
	}
	
	// PathFinder integration
	if(event.Pressed && event.DoubleClick)
	{
		int x = (event.X-8)/16;
		int y = (event.Y-8)/16;
		//Stdout(x)("x")(y).newline;
		if(x>=0 && x<SCREEN_SIZE && y>=0 && y<SCREEN_SIZE)
		{
			readGameData();
			if(mobMap[x][y] is null && objMap[x][y] is null)
				startPathFinder(myX-SCREEN_SIZE/2+x, myY-SCREEN_SIZE/2+y);
		}
	}
}

void checkAutoMapRightClick()
{
	static bool wasPressed = false;
	bool pressed = (GetKeyState(VK_LBUTTON)<0) && (GetKeyState(VK_RBUTTON)<0);
	scope(exit) wasPressed = pressed;
	int x, y;
	if(!pressed && wasPressed && isGameFocused && mouse.x>8+16*SCREEN_SIZE && readMouseGlobalCoords(x, y))
		startPathFinder(x, y);
}

bool inAutoMapDoubleClick;

void hkAutoMapClick(Context* context)
{
	auto event = cast(MouseEvent*) context.stack[1];
	
	// PathFinder integration
	if(event.Pressed && event.DoubleClick)
		inAutoMapDoubleClick = true;
	else
	if(!event.Pressed && inAutoMapDoubleClick)
	{
		inAutoMapDoubleClick = false;
		int x, y;
		if(readMouseGlobalCoords(x,y))
			startPathFinder(x, y);
	}
}

/+void hkProcessMouseEvent(Context* context)
{
	//Stdout.format("Check return: {:X}", context.stack[0]).newline;
	auto event = cast(MouseEvent*) context.stack[1];
	with(*event)
		//Stdout.format("MouseEvent: {} x={} y={} {} {} pressed={} doubleClick={} {} {} {}", f0, x, y, fC, f10, pressed, doubleClick, f1C, f20, f24).newline;
		mixin(mixPrintValues("MouseEvent", ["EventType", "X", "Y", "fC", "f10", "Pressed", "DoubleClick", "Shift", "f20", "HelpCursor"]));
}+/

void testIt()
{
	/*with(*playerData)
		mixin(mixPrintValues("hkProcessDrag", ["MyID", "BackpackID", "f2548", "f254C", "f2550", "f2554", "f2558", "f255C"]));*/

/+	readGameData();
	foreach(ref container;&playerData.containerIterator)
	{
		//Stdout.format("Container addr: {:X8}", &container).newline;
		with(container)
		{
			Stdout.format("Container Type={:X} Next={:X}", type, cast(uint)next).newline;
			if(type != ContainerType.BackPack)
				continue;
			Stdout.format("          ID={} ({})", ID, objectData[globalObjects[ID].objType].nameStr).newline;
		}
		foreach(ref item;container)
			with(item)
				Stdout.format("ID={} ({})", ID, objectData[globalObjects[ID].objType].nameStr).newline;
	}
+/
	/+foreach(gump;&playerData.gump.childrenIterator)
		with(gump)
		{
			Stdout.format("Container Type={:X} Coords={}x{} - {}x{}", type, x1, y1, x2, y2).newline;
		
		}+/
}

void hkProcessDrag(Context* context)
{
	struct Container
	{
		uint f0, f4, f8, fC, f10, f14, f18, f1C, f20, f24, f28, f2C, f30, f34, f38, f3C;
	}	

	testIt();
}

void hkPostProcessScreenTiles(Context* context)
{
	if(mainForm.cbFogOfWar.checked)
	{
		foreach(y,ref row;(*camera.MaskedScreenTiles))
			//row[] = 1;
			foreach(x,ref tile;row)
				if(tile)  // is it normally visible?
				{
					// undim
					(*camera.Lighting)[y][x] = 0x3F;
					(*camera.TileLighting)[y][x] = 0x3F0000;
				}
				else
				{
					// reveal & dim
					tile = (*camera.ScreenTiles)[y][x];
					(*camera.Lighting)[y][x] = 0x17;
				}
		// dim tiles properly
		foreach(y,ref row;(*camera.Lighting))
			foreach(x,ref lighting;row)
				if(lighting<0x3F)  // dimmed
					(*camera.TileLighting)[y  ][x  ] = 
					(*camera.TileLighting)[y  ][x+1] = 
					(*camera.TileLighting)[y+1][x  ] = 
					(*camera.TileLighting)[y+1][x+1] = 0x170000;
		// do borders
		foreach(y,ref row;(*camera.TileLighting))
			row[$-1] = row[$-2];
		foreach(x,ref tile;(*camera.TileLighting)[$-1])
			tile = (*camera.TileLighting)[$-2][x];
	}
}

extern(Windows)
bool consoleHandler(DWORD dwCtrlType)
{
	ShowWindow(GetConsoleWindow(), SW_HIDE);
	return true;
}

bool hideThis(LPPROCESSENTRY32 lppe)
{
	if(lppe is null) return false;
	char[] exe = toLower(readStringZ(lppe.szExeFile.ptr));
	bool skip = 
		exe.containsPattern("drunk") || 
		exe.containsPattern("sick") || 
		exe.containsPattern("ida") || 
		exe.containsPattern("tor") || 
		exe.containsPattern("ollydbg") || 
		exe.containsPattern("far") || 
		exe.containsPattern("dexplore") || 
		exe.containsPattern("artmoney") || 
		exe.containsPattern("procexp") || 
		exe.containsPattern("vmware") || 
		exe.containsPattern("hiew");
	//if(skip)
	//	Stdout("Skipping "~exe~"!").newline;
	return skip;
}

extern(Windows)
BOOL MyProcess32First(win32.winnt.HANDLE hSnapshot, LPPROCESSENTRY32 lppe)
{
	BOOL result = Process32First(hSnapshot, lppe)!=0;
	while(result && hideThis(lppe))
		result = Process32Next(hSnapshot, lppe);
	return result;
}

extern(Windows)
BOOL MyProcess32Next(win32.winnt.HANDLE hSnapshot, LPPROCESSENTRY32 lppe)
{
	BOOL result;
	do
		result = Process32Next(hSnapshot, lppe);
	while(result && hideThis(lppe))
	return result;
}

ubyte[] healthColourScale = [0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xE5, 0xE4, 0xE3, 0xE2, 0xE1, 0xE0, 0xEF, 0xEE, 0xED, 0xEC, 0xEB, 0xEA, 0xE9, 0xE8];
//const maxHP = 3000;

ubyte[] flagTestColours = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x2F, 0x08, 0x18, 0x28, 0x38, 0x48, 0x58, 0x68, 0x78, 0x88, 0x98, 0xA8, 0xB8, 0xC8, 0xD8, 0xE8, 0xF8, 0x00, 0x00, 0x00, 0x00];

void drawSprite(int W, int H)(int x, int y, ubyte[W][H] data)
{
	with(*tileManager)
		for(int px=0;px<W;px++)
			for(int py=0;py<W;py++)
				if(data[py][px]!=0xFE)
					VideoMemory[(y+py)*RowWidth + x+px] = data[py][px];
}

void hkPostRenderPlayerData(Context* context)
{
	if(!playerData.ChatMaximized)
	{
		int bx = myX-SCREEN_SIZE/2, by = myY-SCREEN_SIZE/2;
		uint map = myMap;
		
		uint tileUnderCursor = 0;
		int mousex, mousey;
		if(readMouseScreenCoords(mousex, mousey))
			tileUnderCursor = getTile(map, mousex+bx, mousey+by);

		// exact selection HP + threat estimation
		if(selectionPresent && camera.Target && camera.Target in globalObjects)
		{
			auto glb = globalObjects[camera.Target];
			int sx = (glb.x-myX+SCREEN_SIZE/2);
			int sy = (glb.y-myY+SCREEN_SIZE/2);
			if(glb.MaxHealth && sx>=0 && sx<SCREEN_SIZE && sy>=0 && sy<SCREEN_SIZE)
			{
				char[] str = toString(glb.Health) ~ "/" ~ toString(glb.MaxHealth);
				//uint hpScale = (glb.MaxHealth>maxHP ? 3000 : glb.MaxHealth) * healthColourScale.length / (maxHP+1);
				uint hpScale = glb.MaxHealth*11/playerData.MaxHealth;
				if(hpScale>=healthColourScale.length) hpScale = healthColourScale.length-1;
				camera.DrawName(
					8+16*sx+9-(str.length+2)*4/2, 
					8+16*sy+18, toStringz(str), toStringz(""), healthColourScale[hpScale]);
			}
		}
	
		// draw tile flags
		/+if(GetKeyState(VK_MENU)<0)
		{
			uint mx = myX, my=myY, mmap = myMap;
			for(uint sx=0;sx<SCREEN_SIZE;sx++)
				for(uint sy=0;sy<SCREEN_SIZE;sy++)
				{
					for(uint py=0;py<16;py++)
						for(uint px=0;px<16;px++)
							putPixel(8+sx*16+px, 8+sy*16+py, 0x0F);
					//(*tileManager.VideoMemory)[8+sy*16+8][8+sx*16+8] = rand(256);
					uint flags = (*tileManager.Tiles)[getTile(mmap, sx-SCREEN_SIZE/2+mx, sy-SCREEN_SIZE/2+my)].Flags;
					uint colour = 0;
					for(uint py=0;py<6;py++)
						for(uint px=0;px<6;px++)
						{
							if(flags & 1)
							{
								putPixel(8+sx*16+2+px*2  , 8+sy*16+2+py*2  , flagTestColours[colour]);
								putPixel(8+sx*16+2+px*2+1, 8+sy*16+2+py*2  , flagTestColours[colour]);
								putPixel(8+sx*16+2+px*2  , 8+sy*16+2+py*2+1, flagTestColours[colour]);
								putPixel(8+sx*16+2+px*2+1, 8+sy*16+2+py*2+1, flagTestColours[colour]);
							}
							flags >>= 1;
							colour++;
						}
				}
		}+/

		// pathfinder debug
		if(GetKeyState(VK_MENU)>=0 && GetKeyState(VK_SHIFT)<0 && PathFinder.nodeMap && PathFinder.solidityMap)
		{
			for(uint sx=0;sx<SCREEN_SIZE;sx++)
				for(uint sy=0;sy<SCREEN_SIZE;sy++)
				{
					int gx=bx+sx, gy=by+sy;
					
					if(PathFinder.tileSolidityMap[map][gy][gx])
						drawSprite!(16,16)(8+sx*16, 8+sy*16, sprSolidTile);
					else
					if(PathFinder.solidityMap[map][gy][gx])
						drawSprite!(16,16)(8+sx*16, 8+sy*16, sprSolidObject);

					PathFinder.Node* node = PathFinder.nodeMap[map][gy][gx];
					if(node)
					{
						if(node.fx)
						{
							int dx=node.fx-gx;
							int dy=node.fy-gy;
							if(abs(dx)<=1 && abs(dy)<=1)
								for(int z=0;z<8;z++)
									putPixel(
										8+sx*16+8+dx*z,								
										8+sy*16+8+dy*z,
										0xE8);
						}
						if(node.dir>=0)
						{
							int dx=PathFinder.dirVectors[node.dir].dx;
							int dy=PathFinder.dirVectors[node.dir].dy;
							for(int z=0;z<8;z++)
								putPixel(
									8+sx*16+8+dx*z,								
									8+sy*16+8+dy*z,
									0xF1);
						}
					}
				}
			
			if(tileUnderCursor)
			{
				auto node = PathFinder.nodeMap[map][by+mousey][bx+mousex];
				try
					if(node)
						with(*node)
							camera.DrawName(16, 345, toStringz(formatter("{:X8} x={} y={} map={} distance={} turns={} cost={} fx={} fy={} fmap={} dir={} next={:X8} prev={:X8}", node, x, y, map, distance, turns, getCost, fx, fy, fmap, dir, next, prev)), toStringz(""), 0xF1);
				catch(Object o)
					camera.DrawName(16, 345, toStringz(o.toString), toStringz(""), 0xE8);
			}
		}
		
		// pathfinder solidity training (and preview)
		if(GetKeyState(VK_MENU)<0 && GetKeyState(VK_SHIFT)<0)
		{
			if(mainForm.cbCavernMap.checked || map==0)
			{
				readGameData();
				static bool wasPressed = false;
				bool pressed = GetKeyState(VK_LBUTTON)<0;
				scope(exit) wasPressed = pressed;
				if(pressed && !wasPressed && isGameFocused)
					if(tileUnderCursor)
					{
						solidTiles[tileUnderCursor] ^= true;
						saveSolidTiles();
					}

				for(uint sx=0;sx<SCREEN_SIZE;sx++)
					for(uint sy=0;sy<SCREEN_SIZE;sy++)
					{
						uint tile = getTile(map, sx+bx, sy+by);
						if(solidTiles[tile])
							drawSprite!(16,16)(8+sx*16, 8+sy*16, sprSolidTile);
						if(tile == tileUnderCursor)
							drawSprite!(16,16)(8+sx*16, 8+sy*16, sprTileHighlight);
				
						auto obj = objMap[sx][sy];
						if(obj !is null)
							if(obj.ID in globalObjects)
							{
								auto glb = globalObjects[obj.ID];
								if(objectData[glb.objType].flags & ObjectDataFlags.Blocking)
									drawSprite!(16,16)(8+sx*16, 8+sy*16, sprSolidObject);
							}
				
						auto mob = mobMap[sx][sy];
						if(mob !is null)
							drawSprite!(16,16)(8+sx*16, 8+sy*16, sprMob);
					}
			}
			else
				camera.DrawName(125, 125, toStringz("Enable Cavern Auto-Map!"), toStringz(""), 0xE8);
		}

		// chunks
		for(uint sx=0;sx<SCREEN_SIZE;sx++)
			for(uint sy=0;sy<SCREEN_SIZE;sy++)
			{
				if((bx+sx)%16==0)
					for(int y=0;y<16;y++)
						replacePixel(8+sx*16, 8+sy*16+y, 0x00, 0x24);
				if((by+sy)%16==0)
					for(int x=0;x<16;x++)
						replacePixel(8+sx*16+x, 8+sy*16, 0x00, 0x24);
			}
	}

	// health bar
	{
		//ubyte c = healthColourScale[(healthColourScale.length-1) - playerData.Health * (healthColourScale.length-1) / playerData.MaxHealth];
		float health = cast(float)playerData.Health / playerData.MaxHealth;
		if(health>1) health=1;
		uint colour;
		if(health<0.5)
			colour = interpolateColour(0x0000FF, 0x00FFFF, health*2);
		else
			colour = interpolateColour(0x00FFFF, 0x00FF00, health*2-1);
		ubyte barIndex = findColour(colour);
		uint frameIndex = findColour(interpolateColour(0x000000, colour, 0.6));
		const width = 300;
		int x = (8+(21*16-width)/2);
		rectangle(x-1, 2, x+width+1, 5, frameIndex);
		int healThreshhold1 = cast(int)round(0.7*300);
		vline(x+healThreshhold1, 1, 6, findColour(0x00FFFF));
		int healThreshhold2 = cast(int)round(0.4*300);
		vline(x+healThreshhold2, 1, 6, findColour(0xFFFFFF));
		int barWidth = cast(int)round(health*300);
		fillRect(x, 3, x+barWidth, 4, barIndex);
		fillRect(x+barWidth+1, 3, x+width, 4, 0);
	}
}

void hkPostRenderPlayerInfo(Context* context)
{
	// time
	ubyte c = 0xF1;
	/+if(playerData.IsSunrise)
		c = 0xEC;
	else if(playerData.IsSunset)
		c = 0x38;
	else if(playerData.Hour <= 4)
		c = 0x8A;
	else
		c = 0xE0;+/
	camera.DrawName(564, 121, toStringz(getTimeString()), toStringz(""), c);
}

void hkPostRenderAutoMap(Context* context)
{
	if(!playerData.ChatMaximized)
	{
		Gump* automap = playerData.gump.findChild(GumpType.AutoMap);

		for(int sx=automap.x1+8;sx<automap.x2-8;sx++)
			for(int sy=automap.y1+8;sy<automap.y2-8;sy++)
			{
				if((sx-(automap.x1+automap.x2)/2+myX-1)%16==0 || 
				   (sy-(automap.y1+automap.y2)/2+myY-1)%16==0)
					replacePixel(sx, sy, 0x00, 0x24);
			}
		
		static long frame;
		frame++;

		// automap crosshair
		if(frame%2==0 && ((GetKeyState(VK_LBUTTON)<0 && GetKeyState(VK_RBUTTON)<0) || inAutoMapDoubleClick))
		{
			if(automap && mouse.x>=automap.x1+8 && mouse.x<automap.x2-8 && mouse.y>=automap.y1+8 && mouse.y<automap.y2-8)
			{
				for(int x=automap.x1+8;x<automap.x2-8;x++)
					putPixel(x, mouse.y, 0xE8);     
				for(int y=automap.y1+8;y<automap.y2-8;y++)
					putPixel(mouse.x, y, 0xE8);
			}
		}
	}
}

void hkProcessScan(Context* context)
{
	playSound("Sounds/Scan.wav");
	Stdout("[Security] Process scan detected").newline;
}

void hkAskAmount(Context* context)
{
	if(amountOverride>0)
	{
		clientServices.SendAmount(amountOverride);
		amountOverride = 0;
	}
	else
	if(GetKeyState(VK_CONTROL)<0)
	{
		clientServices.SendAmount(1);
	}
	else
	{
		playerData.AskForAmount(context.eax);
	}
}

extern(C) void* function(uint bytes) operatorNew;

extern(C) 
void* hkTradeSkillBox(uint bytes)
{
	assert(bytes == 0xC9C, "unexpected size in hkTradeSkillBox");
	if(tradeSkillItem)
	{
		clientServices.SendTradeSkillBoxItem(tradeSkillItem);
		tradeSkillItem = ObjectType.None;
		return null;
	}
	else
		return operatorNew(bytes);
}

Hook[] hooks;

void initializeConsole()
{
	//debug MessageBoxA(null, toStringz(formatter("stdout handle is {:X8}", (cast(tango.io.DeviceConduit.DeviceConduit)(cast(tango.io.Buffer.Buffer)tango.io.Console.Cout.stream).output).fileHandle)), null, 0);
	if(GetConsoleWindow() is null)
	{
		//debug MessageBoxA(null, "GetConsoleWindow() is null, AllocConsole'ing", null, 0);
		AllocConsole();
		//debug MessageBoxA(null, toStringz(formatter("AllocConsole'd; GetConsoleWindow() is now {:X8}; hiding console", GetConsoleWindow())), null, 0);
		while(!IsWindowVisible(GetConsoleWindow())){}
		while( IsWindowVisible(GetConsoleWindow()))ShowWindow(GetConsoleWindow(), SW_HIDE);
		SetConsoleTitleA("DrunkSick2 log\0".ptr);
		DeleteMenu(GetSystemMenu(GetConsoleWindow(), false), 6, 1024); // delete "close"
	}
	//else
		//debug MessageBoxA(null, toStringz(formatter("Console was present; GetConsoleWindow() is now {:X8}", GetConsoleWindow())), null, 0);
}

dfl.internal._stdcwindows.HINSTANCE dflInstance;

void initializeDFL(HINSTANCE hInstance)
{
	dflInstance = cast(typeof(dflInstance))hInstance;
	Application.setInstance(dflInstance);
}

void runMainUI(HINSTANCE hInstance)
{
	Stdout.flush = true;
	Stdout("=========== LOADED ============").newline;

	try
	{
		openGame();
		SetForegroundWindow(window);
		
		gameSynchronized({
			hooks ~= Hook(cast(void*)Offsets.MessageLoop, 6, &hkMessageLoop);
			hooks ~= Hook(cast(void*)Offsets.PostProcessScreenTiles, 5, &hkPostProcessScreenTiles);
			hooks ~= Hook(cast(void*)Offsets.PlayerData__ProcessClick, 7, &hkPlayerDataClick);
			hooks ~= Hook(cast(void*)Offsets.AutoMap__ProcessClick, 7, &hkAutoMapClick);
			//hooks ~= Hook(cast(void*)Offsets.PlayerData__ProcessMouseEvent, 5, &hkProcessMouseEvent);
			//hooks ~= Hook(cast(void*)0x414C70, 6, &hkProcessDrag);
			hooks ~= Hook.hotwire(cast(void*)Offsets.Process32First, &MyProcess32First);
			hooks ~= Hook.hotwire(cast(void*)Offsets.Process32Next , &MyProcess32Next );
			hooks ~= Hook(cast(void*)Offsets.PlayerData__Draw_End, 5, &hkPostRenderPlayerData);
			hooks ~= Hook(cast(void*)Offsets.PlayerInfo__Draw_End, 5, &hkPostRenderPlayerInfo);
			hooks ~= Hook(cast(void*)Offsets.AutoMap__Draw_End, 6, &hkPostRenderAutoMap);
			hooks ~= Hook(cast(void*)Offsets.Packet_ProcessScan, 5, &hkProcessScan);
			hooks ~= Hook(cast(void*)Offsets.Packet_AskForAmount, 12, &hkAskAmount, true);
			hooks ~= Hook.hookCall(cast(void*)Offsets.Packet_TradeSkillBox, &hkTradeSkillBox, cast(void**)&operatorNew);
			hooks ~= installMessageHook();
		});

		Application.enableVisualStyles();
		
		//Application.run(new MainUI());
		while(!done)
			Sleep(1);

		Stdout("Shutting down: ")();

		foreach(program;programs)
			if(program.running)
			{
				Stdout(program.name)("... ")();
				program.stopAndWait();
			}

		Stdout("timer... ")();
		try
			mainForm.mainTimer.stop;
		catch(Object o)
			Stdout("[Error: ")(o.toString)("]");
		Stdout("hooks... ")();
		gameSynchronized({
			foreach(ref hook;hooks)
				hook.unhook;
		});
		//Stdout("GC... ")();
		customGCstop();
		if(PathFinder.allocated)
		{
			Stdout("PathFinder memory... ")();
			PathFinder.deallocate();
		}

		Stdout("grace period... ")();
		Sleep(50);
		
		//Stdout("window classes... ")();
		dfl.internal.utf.unregisterClasses(dflInstance);
	}
	catch(Object o)
		msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);

	Stdout.newline;
	doGarbageCollect();
	Stdout("========== UNLOADING ==========").newline;
	ShowWindow(GetConsoleWindow(), SW_HIDE);
}
