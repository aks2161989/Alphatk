(* -*-M2-*- *)

(* M2-Example.mod
 * 
 * Included in the Alpha distribution as an example of the M2 mode
 * 
 * For best results you require not only the M2 mode installed in Alpha when
 * opening these example files, but also at least MacMETH or better RAMSES.
 * Both software packages are available as freeware and provide a full fledged
 * (from simple to sophisticated) development environment for the beautiful
 * (and small) Modula-2 language.
 * 
 * You find all what you need at
 * 
 * <http://www.ito.umnw.ethz.ch/SysEcol/>
 * 
 * and the best kept secret of the web site 
 * 
 * <http://www.ito.umnw.ethz.ch/SysEcol/SimSoftware/SimSoftware.html>
 * 
 * Andreas Fischlin, 30 May 2000 / ETH Zurich, Switzerland
 *  
 * These examples include:
 *  
 *   Simple.MOD
 *   AlmostSimple.MOD
 *   LessSimple.MOD
 * 
 * and of the use of ModelWorks, an interactive Simulation environment
 * 
 * <http://www.ito.umnw.ethz.ch/SysEcol/SimSoftware/RAMSES/ModelWorks.html>:
 * 
 *   Logistic.MOD
 *  
 *)


   (***  Simple  ***)

MODULE Simple;
  FROM DMMaster IMPORT RunDialogMachine;
BEGIN
  RunDialogMachine;
END Simple.

   (***  Almost Simple  ***)

MODULE AlmostSimple;  (*A.Fischlin, 26/Jun/86*)

  (*************************************************************
  
     This program module demonstrates how to install a menu
     and a command before starting the "Dialog Machine" and
     the mechanism to provide an application specific action,
     here the display of the waiting symbol during a delay.
     Furthermore the program demonstrates how to produce
     by means of a so-called alert a message telling the 
     user that the application specific action has been 
     terminated.
     
  *************************************************************)
     
  FROM DMAlerts IMPORT ShowAlert, WriteMessage;
  
  FROM DMMenus IMPORT Menu, InstallMenu, Command, InstallCommand, 
    AccessStatus, Marking; 
    
  FROM DMMaster IMPORT RunDialogMachine, 
    ShowWaitSymbol, Wait, HideWaitSymbol;

                                     
  VAR
    myMenu: Menu;
      aCommand: Command;
    

  PROCEDURE HiImFinished;
  BEGIN
    WriteMessage(2,4,"Hello!  I'm finished.");
  END HiImFinished;
    
  PROCEDURE TheBigAction;
    VAR i: INTEGER;
  BEGIN
    FOR i:= 1 TO 10 DO 
      ShowWaitSymbol; 
      Wait(60) (* Å 1 second *); 
    END;
    HideWaitSymbol; ShowAlert(3,35,HiImFinished);
  END TheBigAction;
  
  
  PROCEDURE InitDM;
  BEGIN
    InstallMenu(myMenu,"Do something",enabled);
    InstallCommand(myMenu,aCommand,"boring...",TheBigAction,
                   enabled,unchecked);
  END InitDM;
  
  
BEGIN
  InitDM;
  RunDialogMachine;
END AlmostSimple.


   (***  Less Simple  ***)

MODULE LessSimple; (*A.Fischlin, Mai 86*)

  (**************************************************************)
  (*   Sample program module demonstrating the installation     *)
  (*   of menus, the window management, inclusive content       *)
  (*   restoration and some drawing within the window as        *)
  (*   supported by the "Dialog Machine"                        *)
  (**************************************************************)
  
                      
  FROM DMMenus IMPORT  Menu, Command, AccessStatus, Marking,
    InstallMenu, InstallCommand, InstallAliasChar, Separator,
    InstallSeparator, DisableCommand, EnableCommand, 
    ChangeCommandText;
                       
  FROM DMWindows IMPORT Window, WindowsDone, notExistingWindow,
    WindowKind, ScrollBars, CloseAttr, ZoomAttr, WFFixPoint, 
    WindowFrame, CreateWindow, SetRestoreProc, DummyRestoreProc,
    AutoRestoreProc, GetWindowFrame;

  FROM DMWindIO IMPORT SelectForOutput, Circle, Pattern;
                        
  FROM DMMaster IMPORT MouseHandlers, AddMouseHandler,
    AddSetupProc, RunDialogMachine;
    


  TYPE
    MachineStates = (myWindowDoesNotExist,
                     myWindowExistsButNoAutomaticUpdating,
                     myWindowExistsWithRestoreUpdating,
                     myWindowExistsWithAutoRestoreUpdating);


  VAR
    myMenu: Menu;
    makeWindow, drawCircle, ordUpdating, autoUpdating: Command;
    myWindow: Window; wf: WindowFrame;
    curDMState: MachineStates;


  PROCEDURE CircleRestoreProc(u: Window);
    VAR radius: INTEGER; filled: BOOLEAN; dummyPat: Pattern;
    PROCEDURE Minimum(x,y: CARDINAL): CARDINAL;
    BEGIN (*Minimum*)
      IF x<y THEN RETURN x ELSE RETURN y END
    END Minimum;
  BEGIN (*CircleRestoreProc*)
    GetWindowFrame(u,wf);
    radius:= Minimum(wf.h DIV 3,wf.w DIV 3);
    filled:= FALSE;
    Circle(wf.w DIV 2,wf.h DIV 2,radius,filled,dummyPat)
  END CircleRestoreProc;

  PROCEDURE DrawCircle;
  BEGIN
    SelectForOutput(myWindow);
    CircleRestoreProc(myWindow);
  END DrawCircle;



  CONST
    clRPStr = "Install your own restore procedure";
    auRPStr = "Install DM's automatic restoring mechanism (AutoRestoreProc)";
    rmClRPStr = "Remove your own restore procedure";
    rmAuRPStr = "Remove automatic restoring";

  PROCEDURE SetDMState(s: MachineStates);
  BEGIN
    CASE s OF
      myWindowDoesNotExist:
              myWindow:= notExistingWindow;
              EnableCommand(myMenu, makeWindow);
              DisableCommand(myMenu, drawCircle);
              DisableCommand(myMenu, ordUpdating);
              DisableCommand(myMenu, autoUpdating);
    | myWindowExistsButNoAutomaticUpdating:
              DisableCommand(myMenu, makeWindow);
              EnableCommand(myMenu, drawCircle);
              EnableCommand(myMenu, ordUpdating);
              EnableCommand(myMenu, autoUpdating);
              SetRestoreProc(myWindow,DummyRestoreProc);
              ChangeCommandText(myMenu,ordUpdating,clRPStr);
              ChangeCommandText(myMenu,autoUpdating,auRPStr);
    | myWindowExistsWithRestoreUpdating:
              DisableCommand(myMenu, makeWindow);
              DisableCommand(myMenu, drawCircle);
              EnableCommand(myMenu, ordUpdating);
              DisableCommand(myMenu, autoUpdating);
              SetRestoreProc(myWindow,CircleRestoreProc);
              ChangeCommandText(myMenu,ordUpdating,rmClRPStr);
              ChangeCommandText(myMenu,autoUpdating,rmAuRPStr);
    | myWindowExistsWithAutoRestoreUpdating:
              DisableCommand(myMenu, makeWindow);
              EnableCommand(myMenu, drawCircle);
              DisableCommand(myMenu, ordUpdating);
              EnableCommand(myMenu, autoUpdating);
              SetRestoreProc(myWindow,AutoRestoreProc);
              ChangeCommandText(myMenu,ordUpdating,rmClRPStr);
              ChangeCommandText(myMenu,autoUpdating,rmAuRPStr);
    END(*CASE*);
    curDMState:= s;
  END SetDMState;


  PROCEDURE MakeWindow;
  BEGIN
    wf.x:= 50; wf.y:= 50; wf.w:= 200; wf.h:= 200;
    CreateWindow(myWindow,
                 GrowOrShrinkOrDrag, WithoutScrollBars,
                 WithCloseBox, WithoutZoomBox, bottomLeft,
                 wf, "My Window", DummyRestoreProc);
    IF WindowsDone THEN
      SetDMState(myWindowExistsButNoAutomaticUpdating)
    END(*IF*);
  END MakeWindow;

  PROCEDURE EnableMenuIfWindowCloses(u: Window);
  BEGIN
    SetDMState(myWindowDoesNotExist);
  END EnableMenuIfWindowCloses;


  

  PROCEDURE ToggleUpdtInstallation;
  BEGIN
    IF curDMState = myWindowExistsButNoAutomaticUpdating THEN
      SetDMState(myWindowExistsWithRestoreUpdating);
    ELSIF curDMState = myWindowExistsWithRestoreUpdating THEN
      SetDMState(myWindowExistsButNoAutomaticUpdating);
    END(*IF*);
  END ToggleUpdtInstallation;
  
  PROCEDURE ToggleAutoUpdtInstallation;
  BEGIN
    IF curDMState = myWindowExistsButNoAutomaticUpdating THEN
      SetDMState(myWindowExistsWithAutoRestoreUpdating);
    ELSIF curDMState = myWindowExistsWithAutoRestoreUpdating THEN
      SetDMState(myWindowExistsButNoAutomaticUpdating);
    END(*IF*);
  END ToggleAutoUpdtInstallation;

  


  PROCEDURE SettingUp;
    (* Menus are now installed in the "Dialog Machine", since this 
    procedure will be called automatically after you have activated
    it by calling DMMaster.RunDialogMachine.  Any menu command texts
    etc. may now be changed the same way as during the ordinary 
    running of the "Dialog Machine" *)
  BEGIN
    SetDMState(myWindowDoesNotExist);
  END SettingUp;

  PROCEDURE DMInitialization;
    (* This procedure is called in order to install menus etc. into the
    "Dialog Machine" before it is actually activated by calling procedure
    DMMaster.RunDialogMachine *)
  BEGIN
    InstallMenu(myMenu,"Control",enabled);
    InstallCommand(myMenu, makeWindow,"Open Window", MakeWindow,
                   enabled, unchecked);
    InstallCommand(myMenu,drawCircle,"Draw Circle", DrawCircle,
                   disabled,unchecked);
    InstallAliasChar(myMenu, drawCircle,"D");
    InstallSeparator(myMenu,line);
    InstallCommand(myMenu,ordUpdating,clRPStr,
                   ToggleUpdtInstallation,disabled,unchecked);
    InstallCommand(myMenu,autoUpdating, auRPStr,
                   ToggleAutoUpdtInstallation,disabled,unchecked);
    AddSetupProc(SettingUp, 0);
    AddMouseHandler(CloseWindow,EnableMenuIfWindowCloses, 0);
  END DMInitialization;


BEGIN
  DMInitialization;
  RunDialogMachine
END LessSimple.


  (***  Logistic  ***)


MODULE Logistic;

  (********************************)
  (* MODEL: Logistic grass growth *)
  (* Author: mu, 9.4.88, ETHZ     *)
  (********************************)

  FROM SimBase IMPORT
    Model, IntegrationMethod, DeclM, DeclSV, DeclP, RTCType, 
    StashFiling, Tabulation, Graphing, DeclMV, SetSimTime,
    NoInitialize, NoInput, NoOutput, NoTerminate, NoAbout,
    StateVar, Derivative, Parameter;

  FROM SimMaster IMPORT RunSimEnvironment;


  VAR 
    m:        Model;
    grass:    StateVar;
    grassDot: Derivative;
    c1, c2:   Parameter;


  PROCEDURE Dynamic;
  BEGIN
    grassDot:=  c1*grass - c2*grass*grass;
  END Dynamic;


  PROCEDURE ModelObjects;
  BEGIN
    DeclSV(grass, grassDot,1.0, 0.0, 10000.0,
      "Grass", "G", "g dry weight/m^2");
      
    DeclMV(grass, 0.0,1000.0, "Grass", "G", "g dry weight/m^2", 
      notOnFile, writeInTable, isY);
    DeclMV(grassDot, 0.0,500.0, "Grass derivative", "GDot", "g dry weight/m^2/day", 
      notOnFile, notInTable, notInGraph);
      
    DeclP(c1, 0.7, 0.0, 10.0, rtc, 
      "c1 (growth rate of grass)",  "c1", "/day");
    DeclP(c2, 0.001, 0.0, 1.0, rtc, 
      "c2 (self inhibition coefficient of grass)",  "c2", "m^2/g dw/day");
  END ModelObjects;


  PROCEDURE ModelDefinitions;
  BEGIN
    DeclM(m, Euler, NoInitialize, NoInput, NoOutput, Dynamic, 
          NoTerminate, ModelObjects, "Logistic grass growth model", 
          "LogGrowth", NoAbout);
    SetSimTime(0.0,30.0);
  END ModelDefinitions;

  
BEGIN
  RunSimEnvironment(ModelDefinitions);
END Logistic.