# File : "codewarriorCompletions.tcl"
#                        Created : 2001-10-01 08:45:09
#              Last modification : 2003-11-03 17:36:01
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fragment>
# www : <http://webperso.easyconnect.fr/bdesgraupes/>
# Description : Info arrays for the CodeWarrior Menu.
# 

# Files info
# ==========
set cw_info(CMPD)    "Last compilation date"
set cw_info(CSZE)    "Code size"
set cw_info(DBUG)    "Generate debugging symbols"
set cw_info(DPND)    "Dependents"
set cw_info(DSZE)    "Data size"
set cw_info(FTYP)    "Type"
set cw_info(ID)      "Internal ID"
set cw_info(INIT)    "'Initialize before' flag"
set cw_info(LIDX)    "Index in target�s link order"
set cw_info(LINK)    "Linked in this target"
set cw_info(MODD)    "Last modification date"
set cw_info(MRGE)    "Merged into other fragment"
set cw_info(PRER)    "Prerequisites"
set cw_info(WEAK)    "Weak link (PowerPC)"

set cw_info(Bfor)    "�Initialize Before� flag"
set cw_info(CSiz)    "Code size"
set cw_info(DSiz)    "Data size"
set cw_info(IncF)    "Prerequisites"
set cw_info(SrcT)    "Type"
set cw_info(SymG)    "Generate debugging symbols"
set cw_info(UpTD)    "Updated"
set cw_info(Weak)    "Weak link (PowerPC)"


# Settings info:
# ==============
# Access paths
set cw_info(PA01)    "User Paths"
set cw_info(PA02)    "Always Search User Paths"
set cw_info(PA03)    "System Paths"
set cw_info(PA04)    "Interpret DOS and Unix Paths"
# Build Extras    
set cw_info(EX04)    "Use Modification Date Caching"
set cw_info(EX09)    "Activate Browser"
set cw_info(EX30)    "Dump Internal Browse Info"
set cw_info(EX31)    "Cache Subprojects"
# C/C++ Compiler    
set cw_info(FE01)    "Force C++ Compilation"
set cw_info(FE02)    "ARM Conformance"
set cw_info(FE03)    "ANSI Keywords Only"
set cw_info(FE04)    "Require Function Prototypes"
set cw_info(FE05)    "Expand Trigraph Sequences"
set cw_info(FE06)    "Enums Always Ints"
set cw_info(FE07)    "Relaxed Pointer Type Rules"
set cw_info(FE08)    "Prefix File"
set cw_info(FE09)    "Enable C++ Exceptions"
set cw_info(FE10)    "Deferred Inlining"
set cw_info(FE11)    "Pool Strings"
set cw_info(FE12)    "Dont Reuse Strings"
set cw_info(FE13)    "ANSI Strict"
set cw_info(FE14)    "Map Newlines to CR"
set cw_info(FE15)    "Enable RTTI"
set cw_info(FE16)    "Multibyte Aware"
set cw_info(FE17)    "Use Unsigned Chars"
set cw_info(FE18)    "Inline depth"
set cw_info(FE19)    "Enable bool Support"
set cw_info(FE20)    "Direct To SOM"
set cw_info(FE23)    "AutoInlining"
set cw_info(FE24)    "Enable wchar_t"
set cw_info(FE25)    "ECPlusPlus Compatibility"
set cw_info(FE26)    "Objective C"
# C/C++ Warnings    
set cw_info(WA01)    "Illegal Pragmas"
set cw_info(WA02)    "Empty Declarations"
set cw_info(WA03)    "Possible Errors"
set cw_info(WA04)    "Unused Variables"
set cw_info(WA05)    "Unused Arguments"
set cw_info(WA06)    "Extra Commas"
set cw_info(WA07)    "Extended Error Checking"
set cw_info(WA08)    "Treat all Warnings as Errors"
set cw_info(WA09)    "Hidden Virtual Functions"
set cw_info(WA10)    "Implicit Arithmetic Conversion"
set cw_info(WA11)    "Non-inlined Functions"
set cw_info(WA12)    "Inconsistent use of 'class' and 'struct'"
# File Mappings    
set cw_info(PR04)    "File Type"
set cw_info(TA02)    "Ext"
set cw_info(TA03)    "Res"
set cw_info(TA04)    "Precomp"
set cw_info(TA05)    "Launch"
set cw_info(TA06)    "Ignore"
set cw_info(TA07)    "Compiler"
# Layout Editor    
set cw_info(LEco)    "Show Component Palette"
set cw_info(LEoi)    "Show Object Inspector"
set cw_info(LEgx)    "Grid Size x"
set cw_info(LEgy)    "Grid Size y"
# MacOS Merge Panel    
set cw_info(PR01)    "Project type"   ; # PRPA: Application / Code Resource / Resource File / Shared Library / Static Library / Stub Library
set cw_info(PR02)    "File name"
set cw_info(PR03)    "Creator"
set cw_info(PR04)    "Type"
set cw_info(MG01)    "Copy code fragments"
set cw_info(MG02)    "Copy resources"
set cw_info(MG03)    "Skip res types"
# MetroNub Panel    
set cw_info(DB01)    "Prog in bg while stepping"
set cw_info(DB12)    "Auto Target Apps"
set cw_info(DB03)    "Stop for Traps"
set cw_info(DB04)    "Catch PPC Traps"
set cw_info(DB05)    "Catch 68K Traps"
set cw_info(DB10)    "Use file mappings for symbolics"
set cw_info(DB11)    "Log DebugStr messages"
# Output Flags    
set cw_info(OLok)    "File Locked"
set cw_info(RLok)    "Resource Map Locked"
set cw_info(PDmf)    "Printer Driver Multifinder Comp"
set cw_info(FFiv)    "Invisible"
set cw_info(FFhb)    "Has Bundle"
set cw_info(FFnl)    "name Locked"
set cw_info(FFsy)    "Stationery"
set cw_info(FFci)    "Has Custom Icon"
set cw_info(FFsh)    "Shared"
set cw_info(FFin)    "Has Been Inited"
set cw_info(FFlb)    "Label"
set cw_info(Comt)    "Comment"
# PPC Disassembler    
set cw_info(DS02)    "Show Code Modules"
set cw_info(DS23)    "Use Extended Mnemonics"
set cw_info(DS21)    "Show Source Code"
set cw_info(DS22)    "Only Show Operands And Mnemonics"
set cw_info(DS03)    "Show Data Modules"
set cw_info(DS31)    "Disassemble Exception Tables"
set cw_info(DS04)    "Show SYM Info"
set cw_info(DS05)    "Show Name Tables"
# PPC Global Optimizer    
set cw_info(GO01)    "Optimize for"
set cw_info(GO02)    "Optimization Level"
# PPC Linker    
set cw_info(LN02)    "Generate SYM File"
set cw_info(LN03)    "Full Path in SYM Paths"
set cw_info(LN04)    "Generate Link Map"
set cw_info(L605)    "Link Mode"
set cw_info(L601)    "Suppress Warnings"
set cw_info(L602)    "Initialization"
set cw_info(L603)    "Entry Point"
set cw_info(L604)    "Termination"
set cw_info(LN10)    "Dead-Strip Static Init Code"
set cw_info(LN11)    "Mult Defs as Warnings"
# PPC PEF    
set cw_info(PE01)    "Export Symbols"
set cw_info(PE02)    "Old Definition"
set cw_info(PE03)    "Old Implementation"
set cw_info(PE04)    "Current Version"
set cw_info(PE05)    "Code Sorting"
set cw_info(PE06)    "Share Data Section"
set cw_info(PE07)    "Expand Uninitialized Data"
set cw_info(PE08)    "Fragment Name"
set cw_info(PE09)    "Library Folder ID"
set cw_info(PE10)    "Collapse Unused TOC-reloads"
# PPC Project    
set cw_info(PR01)    "Project Type"
set cw_info(PR02)    "File Name"
set cw_info(PR03)    "File Creator"
set cw_info(PR04)    "File Type"
set cw_info(PR05)    "Minimum Size"
set cw_info(PR06)    "Preferred Size"
set cw_info(PR07)    "SIZE Flags"
set cw_info(PR08)    "SYM File"
set cw_info(PR09)    "Resource Name"
set cw_info(PR11)    "Display Dialogs"
set cw_info(PR12)    "Merge To File"
set cw_info(PR13)    "Resource Flags"
set cw_info(PR14)    "Resource Type"
set cw_info(PR15)    "Resource ID"
set cw_info(P601)    "Stack Size"
set cw_info(PR16)    "Header Type"
# PPCAsm Panel    
set cw_info(PPC6)    "Prefix File"
set cw_info(PPC3)    "Perform Typechecking"
set cw_info(PPC4)    "Disable All Warnings"
set cw_info(PPC5)    "Case Sensitive"
set cw_info(PPC1)    "Symbolic Debugging"
set cw_info(PPC2)    "Assembler Dialect"
# Rez Compiler    
set cw_info(CR01)    "No Warnings for Redeclared Res Types"
set cw_info(CR02)    "Prefix File"
set cw_info(CR03)    "Escape Control Chars"
set cw_info(CR04)    "Max String Width"
set cw_info(CR05)    "Filter Mode"
set cw_info(CR06)    "Resource Types"
set cw_info(CR07)    "Alignment"
set cw_info(CR08)    "Script Language"
# Runtime Settings    
set cw_info(RS01)    "Host Appl for Libs & Code Resources"
set cw_info(RS02)    "Program Arguments"
set cw_info(RS03)    "Working Directory"
set cw_info(RS04)    "Environment Settings"
# Source Trees    
set cw_info(ST01)    "Source Trees"
# Target Settings    
set cw_info(TA01)    "Linker"
set cw_info(TA13)    "Pre-Linker"
set cw_info(TA09)    "Post-Linker"
set cw_info(TA10)    "Target Name"
set cw_info(TA11)    "Name of Output Dir"
set cw_info(TA12)    "Output Path Type"
set cw_info(TA16)    "Output Directory"
set cw_info(TA15)    "Save Proj Entries using Rel Paths"
# Build Settings
set cw_info(BX01)    "Play sound after Updt & Make"
set cw_info(BX02)    "Success sound"
set cw_info(BX03)    "Failure sound"
set cw_info(BX07)    "Save open files before build"
set cw_info(BX04)    "Build before running"
set cw_info(BX05)    "Include file cache"
set cw_info(BX06)    "Compiler thread stack"
# Shielded Folders
set cw_info(SF01)    "Folders to skip regexp"
set cw_info(SF02)    "Skip in project operations"
set cw_info(SF03)    "Skip in Find&Compare operations"
# Plugin Settings
set cw_info(PX01)    "Plugin Diagnostics Level"
set cw_info(PX02)    "Disable 3rd Party COM Plugs"
# Debugger Display
set cw_info(Db01)    "Show variable types"
set cw_info(Db09)    "Show locals"
set cw_info(Db02)    "Sort functions by method"
set cw_info(Db03)    "Enable RTTI"
set cw_info(Db04)    "Threads in sep windows"
set cw_info(Db05)    "Show variable hints"
set cw_info(Db06)    "Watchpoint hilite color"
set cw_info(Db07)    "Var changed hilite color"
set cw_info(Db08)    "Default array size"
set cw_info(Db10)    "Show values as decimal"
# Extras
set cw_info(EX19)    "Automatic Toolbar Help"
set cw_info(EX08)    "Find Reference using"
set cw_info(EX07)    "Full Screen Zoom"
set cw_info(EX16)    "Recent Documents Count"
set cw_info(EX17)    "Recent Projects Count"
set cw_info(EX10)    "Use Editor Extensions"
set cw_info(EX11)    "Use External Editor"
set cw_info(EX12)    "Use Script Menu"
set cw_info(EX18)    "Use ToolServer Menu"
# Font
set cw_info(FN01)    "Auto Indent"
set cw_info(FN02)    "Tab Size"
set cw_info(FN03)    "Tab Indents Selection"
set cw_info(FN04)    "Tab Inserts Spaces"
set cw_info(ptxf)    "Text Font"
set cw_info(ptps)    "Text Size"
# Syntax Coloring
set cw_info(GH01)    "Syntax Coloring"
set cw_info(GH02)    "Comment Color"
set cw_info(GH03)    "Keyword Color"
set cw_info(GH04)    "String Color"
set cw_info(GH05)    "Custom Color 1"
set cw_info(GH06)    "Custom Color 2"
set cw_info(GH07)    "Custom Color 3"
set cw_info(GH08)    "Custom Color 4"
# VCS Setup
set cw_info(VC01)    "VCS Active"
set cw_info(VC02)    "Connection Method"
set cw_info(VC03)    "Username"
set cw_info(VC04)    "Password"
set cw_info(VC05)    "Auto Connect"
set cw_info(VC06)    "Store Password"
set cw_info(VC07)    "Always Prompt"
set cw_info(VC08)    "Mount Volume"
set cw_info(VC09)    "Database Path"
set cw_info(VC10)    "Local Path"
set cw_info(VC11)    "Use Global Settings"

# Classes
set cw_info(Acce)    "access"
set cw_info(Clas)    "class"
set cw_info(DcEn)    "declaration end offset"
set cw_info(DcFl)    "declaration file"
set cw_info(DcSt)    "declaration start offset"
set cw_info(DfEn)    "implementation end offset"
set cw_info(DfFl)    "implementation file"
set cw_info(DfSt)    "implementation start offset"
set cw_info(Lang)    "language"
set cw_info(Stat)    "static"
set cw_info(SubA)    "all subclasses"
set cw_info(SubC)    "subclasses"
set cw_info(Virt)    "virtual"
set cw_info(pnam)    "name"

# Enumerated values
# =================
# File type
set cw_enum(FTxt)    "source file"
set cw_enum(FUnk)    "unknown"
# Type of source file
set cw_enum(LIBF)    "library file"
set cw_enum(PRJF)    "project file"
set cw_enum(RESF)    "resource file"
set cw_enum(TXTF)    "text file"
set cw_enum(UNKN)    "unknown file"
# Paths
set cw_enum(Abso)    "absolute"
set cw_enum(PRel)    "project relative"
set cw_enum(SRel)    "shell relative"
set cw_enum(YRel)    "system relative"
set cw_enum(RRel)    "root relative"
# Platform
set cw_enum(TxF0)    "MacOS"
set cw_enum(TxF1)    "DOS"
set cw_enum(TxF2)    "Unix"
# Language
set cw_enum(LC)      "C"
set cw_enum(LC++)    "C++"
set cw_enum(LP)      "Pascal"
set cw_enum(LP++)    "Object Pascal"
set cw_enum(LJav)    "Java"
set cw_enum(LAsm)    "Assembler"
set cw_enum(L?)      "Unknown"
# Access
set cw_enum(Publ)    "public"
set cw_enum(Prot)    "protected"
set cw_enum(Priv)    "private"
# Inlining
set cw_enum(FEID)    "Don't inline"
set cw_enum(FEIS)    "Smart"
set cw_enum(FEI1)    "1"
set cw_enum(FEI2)    "2"
set cw_enum(FEI3)    "3"
set cw_enum(FEI4)    "4"
set cw_enum(FEI5)    "5"
set cw_enum(FEI6)    "6"
set cw_enum(FEI7)    "7"
set cw_enum(FEI8)    "8"
# Direct to SOM
set cw_enum(sOff)    "Off"
set cw_enum(sOnn)    "On"
set cw_enum(sOnE)    "On w/ env check"
# Label
set cw_enum(LBno)    "None"
set cw_enum(LB#1)    "Label 1"
set cw_enum(LB#2)    "Label 2"
set cw_enum(LB#3)    "Label 3"
set cw_enum(LB#4)    "Label 4"
set cw_enum(LB#5)    "Label 5"
set cw_enum(LB#6)    "Label 6"
set cw_enum(LB#7)    "Label 7"
# Link mode
set cw_enum(LNNR)    "Normal"
set cw_enum(LNFS)    "Faster"
set cw_enum(LNSL)    "Slower"
# Export symbols
set cw_enum(LNNO)    "None"
set cw_enum(PEEF)    "Use exp file"
set cw_enum(PEEA)    "All globals"
set cw_enum(PEPR)    "Use pragma"
set cw_enum(PEFP)    "Use pragma and exp file"
# Code sorting
set cw_enum(PESN)    "None"
set cw_enum(PESP)    "By pragma seg"
set cw_enum(PESD)    "By depth first"
set cw_enum(PESB)    "By breadth first"
set cw_enum(PESF)    "Use .arr file"
# Plugin diagnostics
set cw_enum(PXd1)    "None"
set cw_enum(PXd2)    "Errors only"
set cw_enum(PXd3)    "All info"
# Symbolic debugging
set cw_enum(PPsA)    "Auto"
set cw_enum(PPsM)    "Manual"
# Assembler dialect
set cw_enum(PPd1)    "Power"
set cw_enum(PPd2)    "PowerPC"
set cw_enum(PPd3)    "PPC64"
# PPC Global Optimizer
set cw_enum(GOF1)    "Smaller Code Size"
set cw_enum(GOF2)    "Faster Execution Speed"
# Derez filter
set cw_enum(SKIP)    "skip specified res types"
set cw_enum(ONLY)    "only specified res types"
# Script language
set cw_enum(SCR0)    "Roman"
set cw_enum(SCR1)    "Japanese"
set cw_enum(SCR2)    "Korean"
set cw_enum(SCR3)    "Simplified Chinese"
set cw_enum(SCR4)    "Traditional Chinese"

# CodeWarrior Shell error codes
# =============================
# Error codes defined in CWAppleEvents.h in "MacOS Examples"
# 0 noErr
set cw_error(1)    "action failed"
set cw_error(2)    "file not found"
set cw_error(3)    "duplicate file"
set cw_error(4)    "compile error"
set cw_error(5)    "make failed"
set cw_error(6)    "no open project"
set cw_error(7)    "window not open"
set cw_error(8)    "segment not found"
set cw_error(ErCE) "compiler error"
set cw_error(ErCW) "compiler warning"
set cw_error(ErLE) "linker error"
set cw_error(ErLW) "linker warning"
set cw_error(ErDf) "definition"
set cw_error(ErFn) "find result"
set cw_error(ErGn) "generic error"
set cw_error(ErIn) "information"
