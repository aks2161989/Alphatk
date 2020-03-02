{ Pascal-Example.p                                                           }
{                                                                            }
{ Included in the Alpha distribution as an example of the Pasc mode          }
{                                                                            }
{ source of original document:                                               }
{                                                                            }
{ http://pascal-central.com/                                                 }

{ MakeBHT.p                                                                  }
{                                                                            }
{ Make Balloon Compiler Text                                                 }

{ Works in conjunction with the Peter M Lewis's excellent Balloon Help       }
{ Compiler for Code Warrior.  It's something I whipped up using Code         }
{ Warrior's 9 Pascal compiler to take all the menus and dialogs in a resedit }
{ (rsrc) or Application and spit them out in a CW text file in the same      }
{ format as Peter's Ballon Help Compiler requires.  It's a simple 68K        }
{ application and there won't be a fat version cause it's not worth writing  }
{ (like 10 seconds vs 2 seconds to rip through an application with 42 menus  }
{ and about 200 dialogs).                                                    }
{                                                                            }
{ This is a FreeWare Application and may be freely distributed and used.     }
{                                                                            }
{ Copyright © 1996 Milton Aupperle                                           }
{ <aupperlm@cadvision.com>                                                   }

program MakeBHT;
uses 
	ConditionalMacros, MixedMode, Types, QuickDraw, fp, fenv, fixmath,
	Strings, Events, Windows, PictUtils, GestaltEqu, AERegistry, AEObjects,
	AEPackObject, Aliases, AppleScript, ASRegistry, OSAComp, OSA,
	OSAGeneric, Dialogs, Fonts, DiskInit, TextEdit,Traps, Devices, Memory,
	SegLoad, FSM, Displays, Translation, TranslationExtensions, {For
	Macintosh Easy open} Scrap, ToolUtils, OSUtils, Menus, Palettes,
	Processes, PPCToolbox, EPPC, ColorPicker, Notification, AppleEvents,
	QDOffscreen, Folders, Controls, TextUtils, script, Packages, Editions,
	Lists, files, StandardFile, Resources, Printing, Sound, DeskBus, Video,
	imageCompression, QuickTimeComponents, imageCodec, MoviesFormat,
	Movies, MediaHandlers, AIFF, SoundInput, SoundComponents, Speech;
{Standard UPI header stuff}

const
var
	OutVol, ApplResFile: Integer;
	GlobalError: Integer;
function NumToStr (num: double_t; NDig: Integer): Str255;
begin
	NumToStr := StringOf(Num:0:Ndig);
end;
procedure ShowError (Code: LongInt);
	const
		IsStop = 0;
		IsCaution = 1;
		IsNote = 2;
		ErrorAlrtID = 1003;
		IOErrStrID = 450;
	var
		S, S1: Str255;
		Itemhit: Integer;
		Abort: Boolean;

	function ALertResponse (WhichAlert, AlertType: Integer): Integer;
		var
			HAlrt: AlertTHndl;
			X, Y: Integer;
			Width, Height: Integer;
		begin
			ALertResponse := 1;
			HAlrt := AlertTHndl(GetResource('ALRT', WhichAlert));
			if HAlrt <> nil then
				begin
					with HAlrt^^.BoundsRect do
						begin
							Width := (Right - left);
							Height := (Bottom - Top);
						end;
					with Qd.SCREENBITS.BOUNDS do
						begin
							X := Left + (Right - Left - Width) div 2;
							Y := 50;{25 pixels below Menubar}
						end;
					SetRect(HAlrt^^.BoundsRect, X, Y, X + Width, Y + Height);
					ParamText(S, S1, '', '');
					case AlertType of
						IsStop: 
							ALertResponse := StopAlert(WhichAlert, nil);
						IsCaution: 
							ALertResponse := CautionAlert(WhichAlert, nil);
						IsNote: 
							ALertResponse := NoteAlert(WhichAlert, nil);
					end;
				end;
		end;
	begin
		itemhit := SetVol(nil, OutVol);
		UseResFile(ApplResFile);
		if code <> NoErr then
			sysbeep(1);
		case Code of  {**Convert # to Message**}
			NoErr: {Final message}
				Itemhit := 15;{Should be the last item in the strings}
			-39, -36: 
				itemhit := 2;{Emty File,Data Miss, Blank Line Err}
			-130: 
				itemhit := 3;{bad data in X or Y col error}
			-33, -34, -194: 
				itemhit := 7;{FullDsk Err}
			-44, -45, -46, -54, -61: 
				itemhit := 8;{Locked dsk/file Err}
			-35, -43, -53, -192, -193: 
				itemhit := 9;{Nofindfolder}
			-27: 
				itemhit := 13;{Unknown printing error}
			-47, -49: 
				ItemHit := 14;{File already open}
			otherwise
				Itemhit := 12;{SYS Error or unknown type error}
		end;
		SetCursor(Qd.Arrow);
		S := '';
		GetIndString(S1, IOErrStrID, itemhit);
		if itemhit = 15 then
			Abort := ALertResponse(ErrorAlrtID, isNote) > 0
		else {}
			if (itemhit = 12) and (Code > 0) then
				begin {System error}
					SysError(Code);
					ExitToShell;
				end
			else
				begin
					S := Concat('Error# ', NumtoStr(Code, 0));
					if itemhit = 12 then
						SysError(Code)
					else
						Abort := ALertResponse(ErrorAlrtID, isStop) > 0;
				end;
	end;

Procedure DisToBallons;
const
	CheckedC = Chr(CheckMark);
	NoMarkC = chr(nomark);
var
	ThisMenu:MenuRef;
	menuID,first,last:Integer;
	ThisItem, firstitem, lastitem:Integer;
	optType,TheItem,itemhit: Integer;
	ItemHdl: Handle;
	OptBox: rect;
	S,S1,S2:Str255;
	TheStatFlag:Integer;
	TheDialog:Dialogptr;
	theactualID: INTEGER;
	theRType: ResType;
	WatchCursor: Cursor;
	hcurs: CursHandle;
	Fout:Text;
	TempResHandle:Handle;
	FileInNum:Integer;
	Where:Point;
	typeList: SFTypeList;
	Reply: SFReply;
	AChar:Char;
Begin
	SetPt(Where, -1, -1);{Auto center the Open file dialog}
	S := ' ';
	TypeList[0] := 'APPL';
	TypeList[1] := 'rsrc';
	SFGetFile(Where, S, nil, 2, @TypeList, nil, Reply);
	if Reply.Good then
	begin
		Hcurs := GetCursor(401);{Watch}
		WatchCursor := Hcurs^^;
		SetCursor(WatchCursor);
		itemhit := SetVol(nil, Reply.vRefnum);
		S := Reply.Fname;
		FileInNum := OpenResFile(S);{The current resource is now MCC ¹ or Ä}
		GlobalError := ResError;
		if (GlobalError <> NoErr) or (FileInNum = -1) then
		begin
			if GlobalError = NoErr then
				GlobalError := -192;{Resource not found}
			showerror(GlobalError);
			Exit(DisToBallons);{Failed}
		end;
		S := concat(Reply.Fname,'.bh');
		ReWrite(Fout,S);
		UseResFile(FileInNum);
		last := Count1Resources('MENU');
		for menuID := 1 to last do
		begin
			TempResHandle := Get1IndResource('MENU', menuID);
			if (TempResHandle <> nil) and (reserror = noerr) then
			Begin
				GetResInfo(TempResHandle, theactualID, theRType, S);
				ReleaseResource(TempResHandle);
				ThisMenu := GetMenu(theactualID);
				lastitem := CountMItems(ThisMenu);
				S := concat('MENU ',NumtoStr(theactualID,0),' ',S);{should be MENU 80 name}
				Writeln(Fout,S);
				for ThisItem := 1 to lastitem do
				begin
					GetMenuItemText(ThisMenu, ThisItem, S);
					GetItemMark(ThisMenu,ThisItem,AChar);
					if AChar = NoMarkC then
						TheStatFlag := 1 + ord(S='-')
					else
						if AChar = CheckedC then
							TheStatFlag := 3
						else
							TheStatFlag := 4;{something else}
					S := concat(NumtoStr(ThisItem+TheStatFlag*0.10,1),' ',S);
					Writeln(Fout,S);
				end;
				S := 'END-MENU';
				Writeln(Fout,S);
				DisposeMenu(ThisMenu);
			end;
		end;{Of menu loop}
		last := Count1Resources('DLOG');
		for menuID := 1 to last do
		begin
			TempResHandle := Get1IndResource('DLOG', menuID);
			if (TempResHandle <> Nil) and (ResError = noerr) then
			Begin
				GetResInfo(TempResHandle, theactualID, theRType, S);
				ReleaseResource(TempResHandle);
				TheDialog := GetNewDialog(theactualID, nil, Pointer(-1));
				S := concat('DIALOG ',NumToStr(theactualID,0),' ',S);
				Writeln(Fout,S);
				{Write it out}
				lastitem := CountDitl(TheDialog);{Current # of items in ditl list}
				for ThisItem := 1 to lastitem do
				begin
					GetDialogItem(TheDialog, ThisItem, optType, ItemHdl, OptBox);
					if optType >= itemDisable then
					Begin
						optType := optType - itemDisable;
						TheStatFlag := 2;
					end
					else
						TheStatFlag := 1;
					case optType of
						0 : S2 := 'utm';{user item}
						4 : S2 := 'btn';{button}
						5 : S2 := 'cbx';{checkbox}
						6 : S2 := 'rbt';{radiobutton}
						7: S2 := 'cnt';{Some sort of res control probably a scroll bar}
						8 : S2 := 'stt';{stattext}
						16 : S2 := 'ett';{edit text}
						32 : S2 := 'icn';{icon}
						64 : S2 := 'pic';{pict}
						otherwise {unknows}
							S2 := '???';
					end;
					if optType in [4,5,6] then {get control name}
					Begin
						GetControlTitle(ControlRef(ItemHdl),S1);
						if TheStatFlag = 1 then {it's on}
						Begin
							TheStatFlag := 1+ GetControlValue(ControlRef(ItemHdl))*2;
							if TheStatFlag > 3 then
								TheStatFlag := 4;
						end;
					end
					else
					 	if (optType = 8) or (optType = 16) then {get string name}
					 		GetDialogItemText(ItemHdl,S1)
					 	else
					 		S1 := '';
					S := Concat(Numtostr((ThisItem+TheStatFlag*0.10),1),' ¥',S2,'¥ ', S1);
					Writeln(Fout,S);
				end;{for ditl item loop}
				S := 'END-DIALOG';{post this too}
				Writeln(Fout,S);
				DisposeDialog(TheDialog);
			end;{of error check for good restype}
		end; {of dialog loop}
		Writeln(Fout,'END');
		Close(Fout);
		CLoseResFile(FileInNum);
		UseResFile(ApplResFile);
	end;
end;
begin
	MaxApplZone;                  { expand application heap to maximum }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	MoreMasters;{This allocates }
	InitGraf(@Qd.ThePort);           { initialize QuickDraw }
	InitFonts;                    {     "      Font Manager }
	InitWindows;                  {     "      Window Manager }
	InitMenus;                    {     "      Menu Manager }
	TEInit;                       {     "      Text Edit }
	InitDialogs(nil);       {@TryAgain     "      Dialog Manager }
	InitCursor;                   { change to arrow cursor }
	ApplResFile := CurResFile;
	GlobalError := GetVol(nil, OutVol);
	DisToBallons;
end.