## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "tcltkExtendedC.tcl"
 #                                          created: 02/24/2003 {02:09:55 PM}
 #                                      last update: 03/03/2006 {10:28:59 AM}
 # Description:
 # 
 # Provides electric completion and command-double-click support for Tcl/Tk
 # extended C files.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2003-2006 Craig Barton Upright
 # All rights reserved.
 #
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature tcl/TkExtendedC 0.2 "C C++ Objc" {
    # Initialization script.
    C::tcltk::initialize
} {
    # Activation script.
} {
    # Deactivation script.
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    This feature provides support for editing Tcl/Tk extended C files
} help {
    This feature provides support for editing Tcl/Tk extended C files.  After
    activating this feature, all Tcl/Tk commands in the Tcl/Tk 'Libraries'
    that are listed here: <http://dev.scriptics.com/man/tcl8.4/> will be
    available as 'electric' completions in C and C++ modes.
    
    Preferences: Mode-Features-C
    Preferences: Mode-Features-C++
    
    Command double-clicking on any of these commands will also open a help
    file specific to the command from this Tcl web site.  (Or, if the C++
    mode pref for "Tcl/Tk Help Local Folder" points to the locally installed
    help folder, this will be used preferentially.)
    
    N.B. The electric templates provided by this feature will be much more
    useful if the package: betterTemplates is activated.
}

proc tcltkExtendedC.tcl {} {}

# ×××× Tcl extended C ×××× #

namespace eval C::tcltk::tcl {
    
    # The C functions which a Tcl extended C program may use. 
    # 
    # The array names are based on the help files in which the commands are
    # described, so that we can later properly redirect [C++::DblClick].
    # 
    # Note: I'm not sure how '(char *) NULL' should be handled, as in the
    # electric for 'Tcl_SetErrorCode' and a few others.

    array set Access {
        Tcl_Access                      "¥path¥, ¥mode¥"
        Tcl_Stat                        "¥path¥, ¥statPtr¥"
    }
    array set AddErrInfo {
        Tcl_AddObjErrorInfo             "¥interp¥, ¥message¥, ¥length¥"
        Tcl_AddErrorInfo                "¥interp¥, ¥message¥"
        Tcl_SetObjErrorCode             "¥interp¥, ¥errorObjPtr¥"
        Tcl_SetErrorCode                "¥interp¥, ¥element¥, ¥element, ...¥\
	  ¥(char *) NULL¥"
        Tcl_SetErrorCodeVA              "¥interp¥, ¥argList¥"
        Tcl_PosixError                  "¥interp¥"
        Tcl_LogCommandInfo              "¥interp¥, ¥script¥, ¥command¥,\
	  ¥commandLength¥"
    }
    array set Alloc {
        Tcl_Alloc                       "¥size¥"
        Tcl_Free                        "¥ptr¥"
        Tcl_Realloc                     "¥ptr¥, ¥size¥"
        Tcl_AttemptAlloc                "¥size¥"
        Tcl_AttemptRealloc              "¥ptr¥, ¥size¥"
        ckalloc                         "¥size¥"
        ckfree                          "¥ptr¥"
        ckrealloc                       "¥ptr¥, ¥size¥"
        attemptckalloc                  "¥size¥"
        attemptckrealloc                "¥ptr¥, ¥size¥"
    }
    array set AllowExc {
        Tcl_AllowExceptions             "¥interp¥"
    }
    array set AppInit {
        Tcl_AppInit                     "¥interp¥"
    }
    array set AssocData {
        Tcl_GetAssocData                "¥interp¥, ¥key¥, ¥delProcPtr¥"
        Tcl_SetAssocData                "¥interp¥, ¥key¥, ¥delProc¥,\
	  ¥clientData¥"
        Tcl_DeleteAssocData             "¥interp¥, ¥key¥"
    }
    array set Async {
        Tcl_AsyncCreate                 "¥proc¥, ¥clientData¥"
        Tcl_AsyncMark                   "¥async¥"
        Tcl_AsyncInvoke                 "¥interp¥, ¥code¥"
        Tcl_AsyncDelete                 "¥async¥"
        Tcl_AsyncReady                  ""
    }
    array set BackgdErr {
        Tcl_BackgroundError             "¥interp¥"
    }
    array set Backslash {
        Tcl_Backslash                   "¥src¥, ¥countPtr¥"
    }
    array set BoolObj {
        Tcl_NewBooleanObj               "¥boolValue¥"
        Tcl_SetBooleanObj               "¥objPtr¥, ¥boolValue¥"
        Tcl_GetBooleanFromObj           "¥interp¥, ¥objPtr¥, ¥boolPtr¥"
    }
    array set ByteArrObj {
        Tcl_NewByteArrayObj             "¥bytes¥, ¥length¥"
        Tcl_SetByteArrayObj             "¥objPtr¥, ¥bytes¥, ¥length¥"
        Tcl_GetByteArrayFromObj         "¥objPtr¥, ¥lengthPtr¥"
        Tcl_SetByteArrayLength          "¥objPtr¥, ¥length¥"
    }
    array set CallDel {
        Tcl_CallWhenDeleted             "¥interp¥, ¥proc¥, ¥clientData¥"
        Tcl_DontCallWhenDeleted         "¥interp¥, ¥proc¥, ¥clientData¥"
    }
    array set ChnlStack {
        Tcl_StackChannel                "¥interp¥, ¥typePtr¥, ¥clientData¥,\
	  ¥mask¥, ¥channel¥"
        Tcl_UnstackChannel              "¥interp¥, ¥channel¥"
        Tcl_GetStackedChannel           "¥channel¥"
        Tcl_GetTopChannel               "¥channel¥"
    }
    array set CmdCmplt {
        Tcl_CommandComplete             "¥cmd¥"
    }
    array set Concat {
        Tcl_Concat                      "¥argc¥, ¥argv¥"
    }
    array set contents {

    }
    array set CrtChannel {
        Tcl_CreateChannel               "¥typePtr¥, ¥channelName¥,\
	  ¥instanceData¥, ¥mask¥"
        Tcl_GetChannelInstanceData      "¥channel¥"
        Tcl_GetChannelType              "¥channel¥"
        Tcl_GetChannelName              "¥channel¥"
        Tcl_GetChannelHandle            "¥channel¥, ¥direction¥, ¥handlePtr¥"
        Tcl_GetChannelThread            "¥channel¥"
        Tcl_GetChannelBufferSize        "¥channel¥"
        Tcl_SetChannelBufferSize        "¥channel¥, ¥size¥"
        Tcl_NotifyChannel               "¥channel¥, ¥mask¥"
        Tcl_BadChannelOption            "¥interp¥, ¥optionName¥, ¥optionList¥"
        Tcl_IsChannelShared             "¥channel¥"
        Tcl_IsChannelRegistered         "¥interp¥, ¥channel¥"
        Tcl_IsChannelExisting           "¥channelName¥"
        Tcl_CutChannel                  "¥channel¥"
        Tcl_SpliceChannel               "¥channel¥"
        Tcl_ClearChannelHandlers        "¥channel¥"
        Tcl_ChannelBuffered             "¥channel¥"
        Tcl_ChannelName                 "¥typePtr¥"
        Tcl_ChannelVersion              "¥typePtr¥"
        Tcl_ChannelBlockModeProc        "¥typePtr¥"
        Tcl_ChannelCloseProc            "¥typePtr¥"
        Tcl_ChannelClose2Proc           "¥typePtr¥"
        Tcl_ChannelInputProc            "¥typePtr¥"
        Tcl_ChannelOutputProc           "¥typePtr¥"
        Tcl_ChannelSeekProc             "¥typePtr¥"
        Tcl_ChannelWideSeekProc         "¥typePtr¥"
        Tcl_ChannelSetOptionProc        "¥typePtr¥"
        Tcl_ChannelGetOptionProc        "¥typePtr¥"
        Tcl_ChannelWatchProc            "¥typePtr¥"
        Tcl_ChannelGetHandleProc        "¥typePtr¥"
        Tcl_ChannelFlushProc            "¥typePtr¥"
        Tcl_ChannelHandlerProc          "¥typePtr¥"
    }
    array set CrtChnlHdlr {
        Tcl_CreateChannelHandler        "¥channel¥, ¥mask¥, ¥proc¥\
	  , ¥clientData¥"
        Tcl_DeleteChannelHandler        "¥channel¥, ¥proc¥, ¥clientData¥"
    }
    array set CrtCloseHdlr {
        Tcl_CreateCloseHandler          "¥channel¥, ¥proc¥, ¥clientData¥"
        Tcl_DeleteCloseHandler          "¥channel¥, ¥proc¥, ¥clientData¥"
    }
    array set CrtCommand {
        cl_CreateCommand                "¥interp¥, ¥cmdName¥, ¥proc¥,\
	  ¥clientData¥, ¥deleteProc¥"
    }
    array set CrtFileHdlr {
        Tcl_CreateFileHandler           "¥fd¥, ¥mask¥, ¥proc¥, ¥clientData¥"
        Tcl_DeleteFileHandler           "¥fd¥"
    }
    array set CrtInterp {
        Tcl_CreateInterp                ""
        Tcl_DeleteInterp                "¥interp¥"
        Tcl_InterpDeleted               "¥interp¥"
    }
    array set CrtMathFnc {
        Tcl_CreateMathFunc              "¥interp¥, ¥name¥, ¥numArgs¥,\
	  ¥argTypes¥, ¥proc¥, ¥clientData¥"
        Tcl_GetMathFuncInfo             "¥interp¥, ¥name¥, ¥numArgsPtr¥,\
	  ¥argTypesPtr¥, ¥procPtr¥, ¥clientDataPtr¥"
        Tcl_ListMathFuncs               "¥interp¥, ¥pattern¥"
    }
    array set CrtObjCmd {
        Tcl_CreateObjCommand            "¥interp¥, ¥cmdName¥, ¥proc¥,\
	  ¥clientData¥, ¥deleteProc¥"
        Tcl_DeleteCommand               "¥interp¥, ¥cmdName¥"
        Tcl_DeleteCommandFromToken      "¥interp¥, ¥token¥"
        Tcl_GetCommandInfo              "¥interp¥, ¥cmdName¥, ¥infoPtr¥"
        Tcl_SetCommandInfo              "¥interp¥, ¥cmdName¥, ¥infoPtr¥"
        Tcl_GetCommandInfoFromToken     "¥token¥, ¥infoPtr¥"
        Tcl_SetCommandInfoFromToken     "¥token¥, ¥infoPtr¥"
        Tcl_GetCommandName              "¥interp¥, ¥token¥"
        Tcl_GetCommandFullName          "¥interp¥, ¥token¥, ¥objPtr¥"
        Tcl_GetCommandFromObj           "¥interp¥, ¥objPtr¥"
    }
    array set CrtSlave {
        Tcl_IsSafe                      "¥interp¥"
        Tcl_MakeSafe                    "¥interp¥"
        Tcl_CreateSlave                 "¥interp¥, ¥slaveName¥, ¥isSafe¥"
        Tcl_GetSlave                    "¥interp¥, ¥slaveName¥"
        Tcl_GetMaster                   "¥interp¥"
        Tcl_GetInterpPath               "¥askingInterp¥, ¥slaveInterp¥"
        Tcl_CreateAlias                 "¥slaveInterp¥, ¥slaveCmd¥,\
	  ¥targetInterp¥, ¥targetCmd¥, ¥argc¥, ¥argv¥"
        Tcl_CreateAliasObj              "¥slaveInterp¥, ¥slaveCmd¥,\
	  ¥targetInterp¥, ¥targetCmd¥, ¥objc¥, ¥objv¥"
        Tcl_GetAlias                    "¥interp¥, ¥slaveCmd¥,\
	  ¥targetInterpPtr¥, ¥targetCmdPtr¥, ¥argcPtr¥, ¥argvPtr¥"
        Tcl_GetAliasObj                 "¥interp¥, ¥slaveCmd¥,\
	  ¥targetInterpPtr¥, ¥targetCmdPtr¥, ¥objcPtr¥, ¥objvPtr¥"
        Tcl_ExposeCommand               "¥interp¥, ¥hiddenCmdName¥,\
	  ¥cmdName¥"
        Tcl_HideCommand                 "¥interp¥, ¥cmdName¥, ¥hiddenCmdName¥"
    }
    array set CrtTimerHdlr {
        Tcl_CreateTimerHandler          "¥milliseconds¥, ¥proc¥, ¥clientData¥"
        Tcl_DeleteTimerHandler          "¥token¥"
    }
    array set CrtTrace {
        Tcl_CreateTrace                 "¥interp¥, ¥level¥, ¥proc¥,\
	  ¥clientData¥"
        Tcl_CreateObjTrace              "¥interp¥, ¥level¥, ¥flags¥,\
	  ¥objProc¥, ¥clientData¥, ¥deleteProc¥"
        Tcl_DeleteTrace                 "¥interp¥, ¥trace¥"
    }
    array set DetachPids {
        Tcl_DetachPids                  "¥numPids¥, ¥pidPtr¥"
        Tcl_ReapDetachedProcs           ""
        Tcl_WaitPid                     "¥pid¥, ¥statPtr¥, ¥options¥"
    }
    array set DoOneEvent {
        Tcl_DoOneEvent                  "¥flags¥"
    }
    array set DoubleObj {
        Tcl_NewDoubleObj                "¥doubleValue¥"
        Tcl_SetDoubleObj                "¥objPtr¥, ¥doubleValue¥"
        Tcl_GetDoubleFromObj            "¥interp¥, ¥objPtr¥, ¥doublePtr¥"
    }
    array set DoWhenIdle {
        Tcl_DoWhenIdle                  "¥proc¥, ¥clientData¥"
        Tcl_CancelIdleCall              "¥proc¥, ¥clientData¥"
    }
    array set DString {
        Tcl_DStringInit                 "¥dsPtr¥"
        Tcl_DStringAppend               "¥dsPtr¥, ¥string¥, ¥length¥"
        Tcl_DStringAppendElement        "¥dsPtr¥, ¥string¥"
        Tcl_DStringStartSublist         "¥dsPtr¥"
        Tcl_DStringEndSublist           "¥dsPtr¥"
        Tcl_DStringLength               "¥dsPtr¥"
        Tcl_DStringValue                "¥dsPtr¥"
        Tcl_DStringSetLength            "¥dsPtr¥, ¥newLength¥"
        Tcl_DStringTrunc                "¥dsPtr¥, ¥newLength¥"
        Tcl_DStringFree                 "¥dsPtr¥"
        Tcl_DStringResult               "¥interp¥, ¥dsPtr¥"
        Tcl_DStringGetResult            "¥interp¥, ¥dsPtr¥"
    }
    array set DumpActiveMemory {
        Tcl_DumpActiveMemory            "¥fileName¥"
        Tcl_InitMemory                  "¥interp¥"
        Tcl_ValidateAllMemory           "¥fileName¥, ¥line¥"
    }
    array set Encoding {
        Tcl_GetEncoding                 "¥interp¥, ¥name¥"
        Tcl_FreeEncoding                "¥encoding¥"
        Tcl_ExternalToUtfDString        "¥encoding¥, ¥src¥, ¥srcLen¥, ¥dstPtr¥"
        Tcl_ExternalToUtf               "¥interp¥, ¥encoding¥, ¥src¥,\
	  ¥srcLen¥, ¥flags¥, ¥statePtr¥, ¥dst¥, ¥dstLen¥, ¥srcReadPtr¥,\
	  ¥dstWrotePtr¥, ¥dstCharsPtr¥"
        Tcl_UtfToExternalDString        "¥encoding¥, ¥src¥, ¥srcLen¥, ¥dstPtr¥"
        Tcl_UtfToExternal               "¥interp¥, ¥encoding¥, ¥src¥,\
	  ¥srcLen¥, ¥flags¥, ¥statePtr¥, ¥dst¥, ¥dstLen¥, ¥srcReadPtr¥,\
	  ¥dstWrotePtr¥, ¥dstCharsPtr¥"
        Tcl_WinTCharToUtf               "¥tsrc¥, ¥srcLen¥, ¥dstPtr¥"
        Tcl_WinUtfToTChar               "¥src¥, ¥srcLen¥, ¥dstPtr¥"
        Tcl_GetEncodingName             "¥encoding¥"
        Tcl_SetSystemEncoding           "¥interp¥, ¥name¥"
        Tcl_GetEncodingNames            "¥interp¥"
        Tcl_CreateEncoding              "¥typePtr¥"
        Tcl_GetDefaultEncodingDir       "¥void¥"
        Tcl_SetDefaultEncodingDir       "¥path¥"
    }
    array set Environment {
        Tcl_PutEnv                      "¥string¥"
    }
    array set Eval {
        Tcl_EvalObjEx                   "¥interp¥, ¥objPtr¥, ¥flags¥"
        Tcl_EvalFile                    "¥interp¥, ¥fileName¥"
        Tcl_EvalObjv                    "¥interp¥, ¥objc¥, ¥objv¥, ¥flags¥"
        Tcl_Eval                        "¥interp¥, ¥script¥"
        Tcl_EvalEx                      "¥interp¥, ¥script¥, ¥numBytes¥, ¥flags¥"
        Tcl_GlobalEval                  "¥interp¥, ¥script¥"
        Tcl_GlobalEvalObj               "¥interp¥, ¥objPtr¥, ¥flags¥"
        Tcl_VarEval                     "¥interp¥, ¥string¥, ¥string, ...¥\
	  ¥(char *) NULL¥"
        Tcl_VarEvalVA                   "¥interp¥, ¥argList¥"
    }
    array set Exit {
        Tcl_Exit                        "¥status¥"
        Tcl_Finalize                    ""
        Tcl_CreateExitHandler           "¥proc¥, ¥clientData¥"
        Tcl_DeleteExitHandler           "¥proc¥, ¥clientData¥"
        Tcl_ExitThread                  "¥status¥"
        Tcl_FinalizeThread              ""
        Tcl_CreateThreadExitHandler     "¥proc¥, ¥clientData¥"
        Tcl_DeleteThreadExitHandler     "¥proc¥, ¥clientData¥"
    }
    array set ExprLong {
        Tcl_ExprLong                    "¥interp¥, ¥string¥, ¥longPtr¥"
        Tcl_ExprDouble                  "¥interp¥, ¥string¥, ¥doublePtr¥"
        Tcl_ExprBoolean                 "¥interp¥, ¥string¥, ¥booleanPtr¥"
        Tcl_ExprString                  "¥interp¥, ¥string¥"
    }
    array set ExprLongObj {
        Tcl_ExprLongObj                 "¥interp¥, ¥objPtr¥, ¥longPtr¥"
        Tcl_ExprDoubleObj               "¥interp¥, ¥objPtr¥, ¥doublePtr¥"
        Tcl_ExprBooleanObj              "¥interp¥, ¥objPtr¥, ¥booleanPtr¥"
        Tcl_ExprObj                     "¥interp¥, ¥objPtr¥, ¥resultPtrPtr¥"
    }
    array set FileSystem {
        Tcl_FSRegister                  "¥clientData¥, ¥fsPtr¥"
        Tcl_FSUnregister                "¥fsPtr¥"
        Tcl_FSData                      "¥fsPtr¥"
        Tcl_FSMountsChanged             "¥fsPtr¥"
        Tcl_FSGetFileSystemForPath      "¥pathObjPtr¥"
        Tcl_FSGetPathType               "¥pathObjPtr¥"
        Tcl_FSCopyFile                  "¥srcPathPtr¥, ¥destPathPtr¥"
        Tcl_FSCopyDirectory             "¥srcPathPtr¥, ¥destPathPtr¥,\
	  ¥errorPtr¥"
        Tcl_FSCreateDirectory           "¥pathPtr¥"
        Tcl_FSDeleteFile                "¥pathPtr¥"
        Tcl_FSRemoveDirectory           "¥pathPtr¥, int recursive, ¥errorPtr¥"
        Tcl_FSRenameFile                "¥srcPathPtr¥, ¥destPathPtr¥"
        Tcl_FSListVolumes               "¥void¥"
        Tcl_FSEvalFile                  "¥interp¥, ¥pathPtr¥"
        Tcl_FSLoadFile                  "¥interp¥, ¥pathPtr¥, ¥sym1¥, ¥sym2¥,\
	  proc1Ptr, proc2Ptr, ¥handlePtr¥, unloadProcPtr"
        Tcl_FSMatchInDirectory          "¥interp¥, ¥result¥, ¥pathPtr¥,\
	  ¥pattern¥, types"
        Tcl_FSLink                      "¥linkNamePtr¥, ¥toPtr¥, ¥linkAction¥"
        Tcl_FSLstat                     "¥pathPtr¥, ¥statPtr¥"
        Tcl_FSUtime                     "¥pathPtr¥, ¥tval¥"
        Tcl_FSFileAttrsGet              "¥interp¥, ¥int index¥, ¥pathPtr¥,\
	  ¥objPtrRef¥"
        Tcl_FSFileAttrsSet              "¥interp¥, ¥int index¥, ¥pathPtr¥,\
	  ¥Tcl_Obj¥ ¥objPtr¥"
        Tcl_FSFileAttrStrings           "¥pathPtr¥, ¥objPtrRef¥"
        Tcl_FSStat                      "¥pathPtr¥, ¥statPtr¥"
        Tcl_FSAccess                    "¥pathPtr¥, ¥mode¥"
        Tcl_FSOpenFileChannel           "¥interp¥, ¥pathPtr¥, ¥modeString¥,\
	  ¥permissions¥"
        Tcl_FSGetCwd                    "¥interp¥"
        Tcl_FSChdir                     "¥pathPtr¥"
        Tcl_FSPathSeparator             "¥pathPtr¥"
        Tcl_FSJoinPath                  "¥listObj¥, ¥elements¥"
        Tcl_FSSplitPath                 "¥pathPtr¥, ¥lenPtr¥"
        Tcl_FSEqualPaths                "¥firstPtr¥, ¥secondPtr¥"
        Tcl_FSGetNormalizedPath         "¥interp¥, ¥pathPtr¥"
        Tcl_FSJoinToPath                "¥basePtr¥, ¥objc¥, ¥objv¥"
        Tcl_FSConvertToPathType         "¥interp¥, ¥pathPtr¥"
        Tcl_FSGetInternalRep            "¥pathPtr¥, ¥fsPtr¥"
        Tcl_FSGetTranslatedPath         "¥interp¥, ¥pathPtr¥"
        Tcl_FSGetTranslatedStringPath   "¥interp¥, ¥pathPtr¥"
        Tcl_FSNewNativePath             "¥fsPtr¥, ¥clientData¥"
        Tcl_FSGetNativePath             "¥pathPtr¥"
        Tcl_FSFileSystemInfo            "¥pathPtr¥"
        Tcl_AllocStatBuf                ""
    }
    array set FindExec {
        Tcl_FindExecutable              "¥argv0¥"
        Tcl_GetNameOfExecutable         ""
    }
    array set GetCwd {
        Tcl_GetCwd                      "¥interp¥, ¥bufferPtr¥"
        Tcl_Chdir                       "¥path¥"
    }
    array set GetHostName {
        Tcl_GetHostName                 ""
    }
    array set GetIndex {
        Tcl_GetIndexFromObj             "¥interp¥, ¥objPtr¥, ¥tablePtr¥,\
	  ¥msg¥, ¥flags¥, ¥indexPtr¥"
        Tcl_GetIndexFromObjStruct       "¥interp¥, ¥objPtr¥, ¥structTablePtr¥,\
	  ¥offset¥, ¥msg¥, ¥flags¥, ¥indexPtr¥"
    }
    array set GetInt {
        Tcl_GetInt                      "¥interp¥, ¥string¥, ¥intPtr¥"
        Tcl_GetDouble                   "¥interp¥, ¥string¥, ¥doublePtr¥"
        Tcl_GetBoolean                  "¥interp¥, ¥string¥, ¥boolPtr¥"
    }
    array set GetOpnFl {
        Tcl_GetOpenFile                 "¥interp¥, ¥string¥, ¥write¥,\
	  ¥checkUsage¥, ¥filePtr¥"
    }
    array set GetStdChan {
        Tcl_GetStdChannel               "¥type¥"
        Tcl_SetStdChannel               "¥channel¥, ¥type¥"
    }
    array set GetTime {
        Tcl_GetTime                     "¥timePtr¥"
    }
    array set GetVersion {
        Tcl_GetVersion                  "¥major¥, ¥minor¥, ¥patchLevel¥,\
	  ¥type¥"
    }
    array set Hash {
        Tcl_InitHashTable               "¥tablePtr¥, ¥keyType¥"
        Tcl_InitCustomHashTable         "¥tablePtr¥, ¥keyType¥, ¥typePtr¥"
        Tcl_InitObjHashTable            "¥tablePtr¥"
        Tcl_DeleteHashTable             "¥tablePtr¥"
        Tcl_CreateHashEntry             "¥tablePtr¥, ¥key¥, ¥newPtr¥"
        Tcl_DeleteHashEntry             "¥entryPtr¥"
        Tcl_FindHashEntry               "¥tablePtr¥, ¥key¥"
        Tcl_GetHashValue                "¥entryPtr¥"
        Tcl_SetHashValue                "¥entryPtr¥, ¥value¥"
        Tcl_GetHashKey                  "¥tablePtr¥, ¥entryPtr¥"
        Tcl_FirstHashEntry              "¥tablePtr¥, ¥searchPtr¥"
        Tcl_NextHashEntry               "¥searchPtr¥"
        Tcl_HashStats                   "¥tablePtr¥"
    }
    array set Init {
        Tcl_Init                        "¥interp¥"
    }
    array set InitStubs {
        Tcl_InitStubs                   "¥interp¥, ¥version¥, ¥exact¥"
    }
    array set Interp {}
    array set IntObj {
        Tcl_NewIntObj                   "¥intValue¥"
        Tcl_NewLongObj                  "¥longValue¥"
        Tcl_NewWideIntObj               "¥wideValue¥"
        Tcl_SetIntObj                   "¥objPtr¥, ¥intValue¥"
        Tcl_SetLongObj                  "¥objPtr¥, ¥longValue¥"
        Tcl_SetWideIntObj               "¥objPtr¥, ¥wideValue¥"
        Tcl_GetIntFromObj               "¥interp¥, ¥objPtr¥, ¥intPtr¥"
        Tcl_GetLongFromObj              "¥interp¥, ¥objPtr¥, ¥longPtr¥"
        Tcl_GetWideIntFromObj           "¥interp¥, ¥objPtr¥, widePtr"
    }
    array set LinkVar {
        Tcl_LinkVar                     "¥interp¥, ¥varName¥, ¥addr¥, ¥type¥"
        Tcl_UnlinkVar                   "¥interp¥, ¥varName¥"
        Tcl_UpdateLinkedVar             "¥interp¥, ¥varName¥"
    }
    array set ListObj {
        Tcl_ListObjAppendList           "¥interp¥, ¥listPtr¥, ¥elemListPtr¥"
        Tcl_ListObjAppendElement        "¥interp¥, ¥listPtr¥, ¥objPtr¥"
        Tcl_NewListObj                  "¥objc¥, ¥objv¥"
        Tcl_SetListObj                  "¥objPtr¥, ¥objc¥, ¥objv¥"
        Tcl_ListObjGetElements          "¥interp¥, ¥listPtr¥, ¥objcPtr¥,\
	  ¥objvPtr¥"
        Tcl_ListObjLength               "¥interp¥, ¥listPtr¥, ¥intPtr¥"
        Tcl_ListObjIndex                "¥interp¥, ¥listPtr¥, ¥index¥,\
	  ¥objPtrPtr¥"
        Tcl_ListObjReplace              "¥interp¥, ¥listPtr¥, ¥first¥,\
	  ¥count¥, ¥objc¥, ¥objv¥"
    }
    array set Macintosh {
        Tcl_MacEvalResource             "¥interp¥, ¥resourceName¥,\
	  ¥resourceNumber¥, ¥fileName¥"
        Tcl_MacConvertTextResource      "¥resource¥"
        Tcl_MacFindResource             "¥interp¥, ¥resourceType¥,\
	  ¥resourceName¥, ¥resourceNumber¥, ¥resFileRef¥, ¥releaseIt¥"
        Tcl_NewOSTypeObj                "¥newOSType¥"
        Tcl_SetOSTypeObj                "¥objPtr¥, ¥newOSType¥"
        Tcl_GetOSTypeFromObj            "¥interp¥, ¥objPtr¥, ¥osTypePtr¥"
        Tcl_MacSetEventProc             "¥procPtr¥"
    }
    array set Notifier {
        Tcl_CreateEventSource           "¥setupProc¥, ¥checkProc¥,\
	  ¥clientData¥"
        Tcl_DeleteEventSource           "¥setupProc¥, ¥checkProc¥,\
	  ¥clientData¥"
        Tcl_SetMaxBlockTime             "¥timePtr¥"
        Tcl_QueueEvent                  "¥evPtr¥, ¥position¥"
        Tcl_ThreadQueueEvent            "¥threadId¥, ¥evPtr¥, ¥position¥"
        Tcl_ThreadAlert                 "¥threadId¥, ¥clientData¥"
        Tcl_GetCurrentThread            ""
        Tcl_DeleteEvents                "¥deleteProc¥, ¥clientData¥"
        Tcl_InitNotifier                ""
        Tcl_FinalizeNotifier            "¥clientData¥"
        Tcl_WaitForEvent                "¥timePtr¥"
        Tcl_AlertNotifier               "¥clientData¥"
        Tcl_SetTimer                    "¥timePtr¥"
        Tcl_ServiceAll                  ""
        Tcl_ServiceEvent                "¥flags¥"
        Tcl_GetServiceMode              ""
        Tcl_SetServiceMode              "¥mode¥"
    }
    array set Object {
        Tcl_NewObj                      ""
        Tcl_DuplicateObj                "¥objPtr¥"
        Tcl_IncrRefCount                "¥objPtr¥"
        Tcl_DecrRefCount                "¥objPtr¥"
        Tcl_IsShared                    "¥objPtr¥"
        Tcl_InvalidateStringRep         "¥objPtr¥"
    }
    array set ObjectType {
        Tcl_RegisterObjType             "¥typePtr¥"
        Tcl_GetObjType                  "¥typeName¥"
        Tcl_AppendAllObjTypes           "¥interp¥, ¥objPtr¥"
        Tcl_ConvertToType               "¥interp¥, ¥objPtr¥, ¥typePtr¥"
    }
    array set OpenFileChnl {
        Tcl_OpenFileChannel             "¥interp¥, ¥fileName¥, ¥mode¥,\
	  ¥permissions¥"
        Tcl_OpenCommandChannel          "¥interp¥, ¥argc¥, ¥argv¥, ¥flags¥"
        Tcl_MakeFileChannel             "¥handle¥, ¥readOrWrite¥"
        Tcl_GetChannel                  "¥interp¥, ¥channelName¥, ¥modePtr¥"
        Tcl_GetChannelNames             "¥interp¥"
        Tcl_GetChannelNamesEx           "¥interp¥, ¥pattern¥"
        Tcl_RegisterChannel             "¥interp¥, ¥channel¥"
        Tcl_UnregisterChannel           "¥interp¥, ¥channel¥"
        Tcl_DetachChannel               "¥interp¥, ¥channel¥"
        Tcl_IsStandardChannel           "¥channel¥"
        Tcl_Close                       "¥interp¥, ¥channel¥"
        Tcl_ReadChars                   "¥channel¥, ¥readObjPtr¥,\
	  ¥charsToRead¥, ¥appendFlag¥"
        Tcl_Read                        "¥channel¥, ¥readBuf¥, ¥bytesToRead¥"
        Tcl_GetsObj                     "¥channel¥, ¥lineObjPtr¥"
        Tcl_Gets                        "¥channel¥, ¥lineRead¥"
        Tcl_Ungets                      "¥channel¥, ¥input¥, ¥inputLen¥,\
	  ¥addAtEnd¥"
        Tcl_WriteObj                    "¥channel¥, ¥writeObjPtr¥"
        Tcl_WriteChars                  "¥channel¥, ¥charBuf¥, ¥bytesToWrite¥"
        Tcl_Write                       "¥channel¥, ¥byteBuf¥, ¥bytesToWrite¥"
        Tcl_ReadRaw                     "¥channel¥, ¥readBuf¥, ¥bytesToRead¥"
        Tcl_WriteRaw                    "¥channel¥, ¥byteBuf¥, ¥bytesToWrite¥"
        Tcl_Eof                         "¥channel¥"
        Tcl_Flush                       "¥channel¥"
        Tcl_InputBlocked                "¥channel¥"
        Tcl_InputBuffered               "¥channel¥"
        Tcl_OutputBuffered              "¥channel¥"
        Tcl_Seek                        "¥channel¥, ¥offset¥, ¥seekMode¥"
        Tcl_Tell                        "¥channel¥"
        Tcl_GetChannelOption            "¥interp¥, ¥channel¥, ¥optionName¥,\
	  ¥optionValue¥"
        Tcl_SetChannelOption            "¥interp¥, ¥channel¥, ¥optionName¥,\
	  ¥newValue¥"
    }
    array set OpenTcp {
        Tcl_OpenTcpClient               "¥interp¥, ¥port¥, ¥host¥, ¥myaddr¥,\
	  ¥myport¥, ¥async¥"
        Tcl_MakeTcpClientChannel        "¥sock¥"
        Tcl_OpenTcpServer               "¥interp¥, ¥port¥, ¥myaddr¥, ¥proc¥,\
	  ¥clientData¥"
    }
    array set Panic {
        Tcl_Panic                       "¥format¥, ¥arg, arg, ...¥"
        Tcl_PanicVA                     "¥format¥, ¥argList¥"
        Tcl_SetPanicProc                "¥panicProc¥"
        panic                           "¥format¥, ¥arg, arg, ...¥"
        panicVA                         "¥format¥, ¥argList¥"
    }
    array set ParseCmd {
        Tcl_ParseCommand                "¥interp¥, ¥string¥, ¥numBytes¥,\
	  ¥nested¥, ¥parsePtr¥"
        Tcl_ParseExpr                   "¥interp¥, ¥string¥, ¥numBytes¥,\
	  ¥parsePtr¥"
        Tcl_ParseBraces                 "¥interp¥, ¥string¥, ¥numBytes¥,\
	  ¥parsePtr¥, ¥append¥, ¥termPtr¥"
        Tcl_ParseQuotedString           "¥interp¥, ¥string¥, ¥numBytes¥,\
	  ¥parsePtr¥, ¥append¥, ¥termPtr¥"
        Tcl_ParseVarName                "¥interp¥, ¥string¥, ¥numBytes¥,\
	  ¥parsePtr¥, ¥append¥"
        Tcl_ParseVar                    "¥interp¥, ¥string¥, ¥termPtr¥"
        Tcl_FreeParse                   "¥usedParsePtr¥"
        Tcl_EvalTokens                  "¥interp¥, ¥tokenPtr¥, ¥numTokens¥"
        Tcl_EvalTokensStandard          "¥interp¥, ¥tokenPtr¥, ¥numTokens¥"
    }
    array set PkgRequire {
        Tcl_PkgRequire                  "¥interp¥, ¥name¥, ¥version¥, ¥exact¥"
        Tcl_PkgRequireEx                "¥interp¥, ¥name¥, ¥version¥, ¥exact¥,\
	  ¥clientDataPtr¥"
        Tcl_PkgPresent                  "¥interp¥, ¥name¥, ¥version¥, ¥exact¥"
        Tcl_PkgPresentEx                "¥interp¥, ¥name¥, ¥version¥, ¥exact¥,\
	  ¥clientDataPtr¥"
        Tcl_PkgProvide                  "¥interp¥, ¥name¥, ¥version¥"
        Tcl_PkgProvideEx                "¥interp¥, ¥name¥, ¥version¥,\
	  ¥clientData¥"
    }
    array set Preserve {
        Tcl_Preserve                    "¥clientData¥"
        Tcl_Release                     "¥clientData¥"
        Tcl_EventuallyFree              "¥clientData¥, ¥freeProc¥"
    }
    array set PrintDbl {
        Tcl_PrintDouble                 "¥interp¥, ¥value¥, ¥dst¥"
    }
    array set RecEvalObj {
        Tcl_RecordAndEvalObj            "¥interp¥, cmdPtr, ¥flags¥"
    }
    array set RecordEval {
        Tcl_RecordAndEval               "¥interp¥, ¥cmd¥, ¥flags¥"
    }
    array set RegExp {
        Tcl_RegExpMatchObj              "¥interp¥, ¥strObj¥, ¥patObj¥"
        Tcl_RegExpMatch                 "¥interp¥, ¥string¥, ¥pattern¥"
        Tcl_RegExpCompile               "¥interp¥, ¥pattern¥"
        Tcl_RegExpExec                  "¥interp¥, ¥regexp¥, ¥string¥, ¥start¥"
        Tcl_RegExpRange                 "¥regexp¥, ¥index¥, ¥startPtr¥,\
	  ¥endPtr¥"
        Tcl_GetRegExpFromObj            "¥interp¥, ¥patObj¥, ¥cflags¥"
        Tcl_RegExpExecObj               "¥interp¥, ¥regexp¥, ¥objPtr¥,\
	  ¥offset¥, ¥nmatches¥, ¥eflags¥"
        Tcl_RegExpGetInfo               "¥regexp¥, ¥infoPtr¥"
    }
    array set SaveResult {
        Tcl_SaveResult                  "¥interp¥, ¥statePtr¥"
        Tcl_RestoreResult               "¥interp¥, ¥statePtr¥"
        Tcl_DiscardResult               "¥statePtr¥"
    }
    array set SetErrno {
        Tcl_SetErrno                    "¥errorCode¥"
        Tcl_GetErrno                    ""
        Tcl_ErrnoId                     ""
        Tcl_ErrnoMsg                    "¥errorCode¥"
    }
    array set SetRecLmt {
        Tcl_SetRecursionLimit           "¥interp¥, ¥depth¥"
    }
    array set SetResult {
        Tcl_SetObjResult                "¥interp¥, ¥objPtr¥"
        Tcl_GetObjResult                "¥interp¥"
        Tcl_SetResult                   "¥interp¥, ¥string¥, ¥freeProc¥"
        Tcl_GetStringResult             "¥interp¥"
        Tcl_AppendResult                "¥interp¥, ¥string¥, ¥string, ... ,¥\
	  ¥(char *) NULL¥"
        Tcl_AppendResultVA              "¥interp¥, ¥argList¥"
        Tcl_AppendElement               "¥interp¥, ¥string¥"
        Tcl_ResetResult                 "¥interp¥"
        Tcl_FreeResult                  "¥interp¥"
    }
    array set SetVar {
        Tcl_SetVar2Ex                   "¥interp¥, ¥name1¥, ¥name2¥,\
	  ¥newValuePtr¥, ¥flags¥"
        Tcl_SetVar                      "¥interp¥, ¥varName¥, ¥newValue¥,\
	  ¥flags¥"
        Tcl_SetVar2                     "¥interp¥, ¥name1¥, ¥name2¥,\
	  ¥newValue¥, ¥flags¥"
        Tcl_ObjSetVar2                  "¥interp¥, ¥part1Ptr¥, ¥part2Ptr¥,\
	  ¥newValuePtr¥, ¥flags¥"
        Tcl_GetVar2Ex                   "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥"
        Tcl_GetVar                      "¥interp¥, ¥varName¥, ¥flags¥"
        Tcl_GetVar2                     "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥"
        Tcl_ObjGetVar2                  "¥interp¥, ¥part1Ptr¥, ¥part2Ptr¥,\
	  ¥flags¥"
        Tcl_UnsetVar                    "¥interp¥, ¥varName¥, ¥flags¥"
        Tcl_UnsetVar2                   "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥"
    }
    array set Signal {
        Tcl_SignalId                    "¥sig¥"
        Tcl_SignalMsg                   "¥sig¥"
    }
    array set Sleep {
        Tcl_Sleep                       "¥ms¥"
    }
    array set SourceRCFile {
        Tcl_SourceRCFile                "¥interp¥"
    }
    array set SplitList {
        Tcl_SplitList                   "¥interp¥, ¥list¥, ¥argcPtr¥,\
	  ¥argvPtr¥"
        Tcl_Merge                       "¥argc¥, ¥argv¥"
        Tcl_ScanElement                 "¥src¥, ¥flagsPtr¥"
        Tcl_ScanCountedElement          "¥src¥, ¥length¥, ¥flagsPtr¥"
        Tcl_ConvertElement              "¥src¥, ¥dst¥, ¥flags¥"
        Tcl_ConvertCountedElement       "¥src¥, ¥length¥, ¥dst¥, ¥flags¥"
    }
    array set SplitPath {
        Tcl_SplitPath                   "¥path¥, ¥argcPtr¥, ¥argvPtr¥"
        Tcl_JoinPath                    "¥argc¥, ¥argv¥, ¥resultPtr¥"
        Tcl_GetPathType                 "¥path¥"
    }
    array set StaticPkg {
        Tcl_StaticPackage               "¥interp¥, ¥pkgName¥, ¥initProc¥,\
	  ¥safeInitProc¥"
    }
    array set StdChannels {}
    array set StringObj {
        Tcl_NewStringObj                "¥bytes¥, ¥length¥"
        Tcl_NewUnicodeObj               "¥unicode¥, ¥numChars¥"
        Tcl_SetStringObj                "¥objPtr¥, ¥bytes¥, ¥length¥"
        Tcl_SetUnicodeObj               "¥objPtr¥, ¥unicode¥, ¥numChars¥"
        Tcl_GetStringFromObj            "¥objPtr¥, ¥lengthPtr¥"
        Tcl_GetString                   "¥objPtr¥"
        Tcl_GetUnicodeFromObj           "¥objPtr¥, ¥lengthPtr¥"
        Tcl_GetUnicode                  "¥objPtr¥"
        Tcl_GetUniChar                  "¥objPtr¥, ¥index¥"
        Tcl_GetCharLength               "¥objPtr¥"
        Tcl_GetRange                    "¥objPtr¥, ¥first¥, ¥last¥"
        Tcl_AppendToObj                 "¥objPtr¥, ¥bytes¥, ¥length¥"
        Tcl_AppendUnicodeToObj          "¥objPtr¥, ¥unicode¥, ¥numChars¥"
        Tcl_AppendObjToObj              "¥objPtr¥, ¥appendObjPtr¥"
        Tcl_AppendStringsToObj          "¥objPtr¥, ¥string¥, ¥string, ...¥\
	  ¥(char *) NULL¥"
        Tcl_AppendStringsToObjVA         "¥objPtr¥, ¥argList¥"
        Tcl_SetObjLength                "¥objPtr¥, ¥newLength¥"
        Tcl_AttemptSetObjLength         "¥objPtr¥, ¥newLength¥"
        Tcl_ConcatObj                   "¥objc¥, ¥objv¥"
    }
    array set StrMatch {
        Tcl_StringMatch                 "¥string¥, ¥pattern¥"
        Tcl_StringCaseMatch             "¥string¥, ¥pattern¥, ¥nocase¥"
    }
    array set SubstObj {
        Tcl_SubstObj                    "¥interp¥, ¥objPtr¥, ¥flags¥"
    }
    array set Tcl_Main {
        Tcl_Main                        "¥argc¥, ¥argv¥, ¥appInitProc¥"
        Tcl_SetMainLoop                 "¥mainLoopProc¥"
    }
    array set TCL_MEM_DEBUG {}
    array set Thread {
        Tcl_ConditionNotify             "¥condPtr¥"
        Tcl_ConditionWait               "¥condPtr¥, ¥mutexPtr¥, ¥timePtr¥"
        Tcl_ConditionFinalize           "¥condPtr¥"
        Tcl_GetThreadData               "¥keyPtr¥, ¥size¥"
        Tcl_MutexLock                   "¥mutexPtr¥"
        Tcl_MutexUnlock                 "¥mutexPtr¥"
        Tcl_MutexFinalize               "¥mutexPtr¥"
        Tcl_CreateThread                "¥idPtr¥, ¥threadProc¥, ¥clientData¥,\
	  ¥stackSize¥, ¥flags¥"
        Tcl_JoinThread                  "¥id¥, ¥result¥"
    }
    array set ToUpper {
        Tcl_UniCharToUpper              "¥ch¥"
        Tcl_UniCharToLower              "¥ch¥"
        Tcl_UniCharToTitle              "¥ch¥"
        Tcl_UtfToUpper                  "¥str¥"
        Tcl_UtfToLower                  "¥str¥"
        Tcl_UtfToTitle                  "¥str¥"
    }
    array set TraceCmd {
        Tcl_CommandTraceInfo            "¥interp¥, ¥cmdName¥, ¥flags¥,\
	  ¥proc¥, ¥prevClientData¥"
        Tcl_TraceCommand                "¥interp¥, ¥cmdName¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
        Tcl_UntraceCommand              "¥interp¥, ¥cmdName¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
    }
    array set TraceVar {
        Tcl_TraceVar                    "¥interp¥, ¥varName¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
        Tcl_TraceVar2                   "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
        Tcl_UntraceVar                  "¥interp¥, ¥varName¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
        Tcl_UntraceVar2                 "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥,\
	  ¥proc¥, ¥clientData¥"
        Tcl_VarTraceInfo                "¥interp¥, ¥varName¥, ¥flags¥,\
	  ¥proc¥, ¥prevClientData¥"
        Tcl_VarTraceInfo2               "¥interp¥, ¥name1¥, ¥name2¥, ¥flags¥,\
	  ¥proc¥, ¥prevClientData¥"
    }
    array set Translate {
        Tcl_TranslateFileName           "¥interp¥, ¥name¥, ¥bufferPtr¥"
    }
    array set UniCharIsAlpha {
        Tcl_UniCharIsAlnum              "¥ch¥"
        Tcl_UniCharIsAlpha              "¥ch¥"
        Tcl_UniCharIsControl            "¥ch¥"
        Tcl_UniCharIsDigit              "¥ch¥"
        Tcl_UniCharIsGraph              "¥ch¥"
        Tcl_UniCharIsLower              "¥ch¥"
        Tcl_UniCharIsPrint              "¥ch¥"
        Tcl_UniCharIsPunct              "¥ch¥"
        Tcl_UniCharIsSpace              "¥ch¥"
        Tcl_UniCharIsUpper              "¥ch¥"
        Tcl_UniCharIsWordChar           "¥ch¥"
    }
    array set UpVar {
        Tcl_UpVar                       "¥interp¥, ¥frameName¥,\
	  ¥sourceName¥, ¥destName¥, ¥flags¥"
        Tcl_UpVar2                      "¥interp¥, ¥frameName¥,\
	  ¥name1¥, ¥name2¥, ¥destName¥, ¥flags¥"
    }
    array set Utf {
        Tcl_UniCharToUtf                "¥ch¥, ¥buf¥"
        Tcl_UtfToUniChar                "¥src¥, ¥chPtr¥"
        Tcl_UniCharToUtfDString         "¥uniStr¥, ¥numChars¥, ¥dstPtr¥"
        Tcl_UtfToUniCharDString         "¥src¥, ¥len¥, ¥dstPtr¥"
        Tcl_UniCharLen                  "¥uniStr¥"
        Tcl_UniCharNcmp                 "¥uniStr¥, ¥uniStr¥, ¥num¥"
        Tcl_UniCharNcasecmp             "¥uniStr¥, ¥uniStr¥, ¥num¥"
        Tcl_UniCharCaseMatch            "¥uniStr¥, ¥uniPattern¥, ¥nocase¥"
        Tcl_UtfNcmp                     "¥src¥, ¥src¥, ¥num¥"
        Tcl_UtfNcasecmp                 "¥src¥, ¥src¥, ¥num¥"
        Tcl_UtfCharComplete             "¥src¥, ¥len¥"
        Tcl_NumUtfChars                 "¥src¥, ¥len¥"
        Tcl_UtfFindFirst                "¥src¥, ¥ch¥"
        Tcl_UtfFindLast                 "¥src¥, ¥ch¥"
        Tcl_UtfNext                     "¥src¥"
        Tcl_UtfPrev                     "¥src¥, ¥start¥"
        Tcl_UniCharAtIndex              "¥src¥, ¥index¥"
        Tcl_UtfAtIndex                  "¥src¥, ¥index¥"
        Tcl_UtfBackslash                "¥src¥, ¥readPtr¥, ¥dst¥"
    }
    array set WrongNumArgs {
        Tcl_WrongNumArgs                "¥interp¥, ¥objc¥, ¥objv¥, ¥message¥"
    }
}

# ×××× Tk extended C ×××× #

namespace eval C::tcltk::tk {
    
    # The C functions which a Tk extended C program may use. 
    # 
    # The array names are based on the help files in which the commands are
    # described, so that we can later properly redirect [C++::DblClick].

    array set 3DBorder {
        Tk_Alloc3DBorderFromObj         "¥interp¥, ¥tkwin¥, ¥objPtr¥"
        Tk_Get3DBorder                  "¥interp¥, ¥tkwin¥, ¥colorName¥"
        Tk_Get3DBorderFromObj           "¥tkwin¥, ¥objPtr¥"
        Tk_Draw3DRectangle              "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥x¥, ¥y¥, ¥width¥, ¥height¥, ¥borderWidth¥, ¥relief¥"
        Tk_Fill3DRectangle              "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥x¥, ¥y¥, ¥width¥, ¥height¥, ¥borderWidth¥, ¥relief¥"
        Tk_Draw3DPolygon                "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥pointPtr¥, ¥numPoints¥, ¥polyBorderWidth¥, ¥leftRelief¥"
        Tk_Fill3DPolygon                "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥pointPtr¥, ¥numPoints¥, ¥polyBorderWidth¥, ¥leftRelief¥"
        Tk_3DVerticalBevel              "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥x¥, ¥y¥, ¥width¥, ¥height¥, ¥leftBevel¥, ¥relief¥"
        Tk_3DHorizontalBevel            "¥tkwin¥, ¥drawable¥, ¥border¥,\
	  ¥x¥, ¥y¥, ¥width¥, ¥height¥, ¥leftIn¥, ¥rightIn¥, ¥topBevel¥,\
	  ¥relief¥"
        Tk_SetBackgroundFromBorder      "¥tkwin¥, ¥border¥"
        Tk_NameOf3DBorder               "¥border¥"
        Tk_3DBorderColor                "¥border¥"
        Tk_3DBorderGC                   "¥tkwin¥, ¥border¥, which"
        Tk_Free3DBorderFromObj          "¥tkwin¥, ¥objPtr¥"
        Tk_Free3DBorder                 "¥border¥"
    }
    array set AddOption {
        Tk_AddOption                    "¥tkwin¥, ¥name¥, ¥value¥, ¥priority¥"
    }
    array set BindTable {
        Tk_CreateBindingTable           "¥interp¥"
        Tk_DeleteBindingTable           "¥bindingTable¥"
        Tk_CreateBinding                "¥interp¥, ¥bindingTable¥, ¥object¥,\
	  ¥eventString¥, ¥script¥, ¥append¥"
        Tk_DeleteBinding                "¥interp¥, ¥bindingTable¥, ¥object¥,\
	  ¥eventString¥"
        Tk_GetBinding                   "¥interp¥, ¥bindingTable¥, ¥object¥,\
	  ¥eventString¥"
        Tk_GetAllBindings               "¥interp¥, ¥bindingTable¥, ¥object¥"
        Tk_DeleteAllBindings            "¥bindingTable¥, ¥object¥"
        Tk_BindEvent                    "¥bindingTable¥, ¥eventPtr¥, ¥tkwin¥,\
	  ¥numObjects¥, ¥objectPtr¥"
    }
    array set CanvPsY {
        Tk_CanvasPsY                    "¥canvas¥, ¥canvasY¥"
        Tk_CanvasPsBitmap               "¥interp¥, ¥canvas¥, ¥bitmap¥,\
	  ¥x¥, ¥y¥, ¥width¥, ¥height¥"
        Tk_CanvasPsColor                "¥interp¥, ¥canvas¥, ¥colorPtr¥"
        Tk_CanvasPsFont                 "¥interp¥, ¥canvas¥, ¥tkFont¥"
        Tk_CanvasPsPath                 "¥interp¥, ¥canvas¥, ¥coordPtr¥,\
	  ¥numPoints¥"
        Tk_CanvasPsStipple              "¥interp¥, ¥canvas¥, ¥bitmap¥"
    }
    array set CanvTkwin {
        Tk_CanvasTkwin                  "¥canvas¥"
        Tk_CanvasGetCoord               "¥interp¥, ¥canvas¥, ¥string¥,\
	  ¥doublePtr¥"
        Tk_CanvasDrawableCoords         "¥canvas¥, ¥x¥, ¥y¥, ¥drawableXPtr¥,\
	  ¥drawableYPtr¥"
        Tk_CanvasSetStippleOrigin       "¥canvas¥, ¥gc¥"
        Tk_CanvasWindowCoords           "¥canvas¥, ¥x¥, ¥y¥, ¥screenXPtr¥,\
	  ¥screenYPtr¥"
        Tk_CanvasEventuallyRedraw       "¥canvas¥, ¥x1¥, ¥y1¥, ¥x2¥, ¥y2¥"
    }
    array set CanvTxtInfo {
        Tk_CanvasGetTextInfo            "¥canvas¥"
    }
    array set Clipboard {
        Tk_ClipboardClear               "¥interp¥, ¥tkwin¥"
        Tk_ClipboardAppend              "¥interp¥, ¥tkwin¥, ¥target¥, ¥format¥,\
	  ¥buffer¥"
    }
    array set ClrSelect {
        Tk_ClearSelection               "¥tkwin¥, ¥selection¥"
    }
    array set ConfigWidg {
        Tk_ConfigureWidget              "¥interp¥, ¥tkwin¥, ¥specs¥, ¥argc¥,\
	  ¥argv¥, ¥widgRec¥, ¥flags¥"
        Tk_Offset                       "¥type¥, ¥field¥"
        Tk_ConfigureInfo                "¥interp¥, ¥tkwin¥, ¥specs¥, ¥widgRec¥,\
	  ¥argvName¥, ¥flags¥"
        Tk_ConfigureValue               "¥interp¥, ¥tkwin¥, ¥specs¥, ¥widgRec¥,\
	  ¥argvName¥, ¥flags¥"
        Tk_FreeOptions                  "¥specs¥, ¥widgRec¥, ¥display¥,\
	  ¥flags¥"
    }
    array set ConfigWind {
        Tk_ConfigureWindow              "¥tkwin¥, ¥valueMask¥, ¥valuePtr¥"
        Tk_MoveWindow                   "¥tkwin¥, ¥x¥, ¥y¥"
        Tk_ResizeWindow                 "¥tkwin¥, ¥width¥, ¥height¥"
        Tk_MoveResizeWindow             "¥tkwin¥, ¥x¥, ¥y¥, ¥width¥, ¥height¥"
        Tk_SetWindowBorderWidth         "¥tkwin¥, ¥borderWidth¥"
        Tk_ChangeWindowAttributes       "¥tkwin¥, ¥valueMask¥, ¥attsPtr¥"
        Tk_SetWindowBackground          "¥tkwin¥, ¥pixel¥"
        Tk_SetWindowBackgroundPixmap    "¥tkwin¥, ¥pixmap¥"
        Tk_SetWindowBorder              "¥tkwin¥, ¥pixel¥"
        Tk_SetWindowBorderPixmap        "¥tkwin¥, ¥pixmap¥"
        Tk_SetWindowColormap            "¥tkwin¥, ¥colormap¥"
        Tk_DefineCursor                 "¥tkwin¥, ¥cursor¥"
        Tk_UndefineCursor               "¥tkwin¥"
    }
    array set CoordToWin {
        Tk_CoordsToWindow               "¥rootX¥, ¥rootY¥, ¥tkwin¥"
    }
    array set CrtCmHdlr {
        Tk_CreateClientMessageHandler   "¥proc¥"
        Tk_DeleteClientMessageHandler   "¥proc¥"
    }
    array set CrtErrHdlr {
        Tk_CreateErrorHandler           "¥display¥, ¥error¥, ¥request¥,\
	  ¥minor¥, ¥proc¥, ¥clientData¥"
        Tk_DeleteErrorHandler           "¥handler¥"
    }
    array set CrtGenHdlr {
        Tk_CreateGenericHandler         "¥proc¥, ¥clientData¥"
        Tk_DeleteGenericHandler         "¥proc¥, ¥clientData¥"
    }
    array set CrtImgType {
        Tk_CreateImageType              "¥typePtr¥"
        Tk_GetImageMasterData           "¥interp¥, ¥name¥, ¥typePtrPtr¥"
        Tk_InitImageArgs                "¥interp¥, ¥argc¥, ¥argvPtr¥"
    }
    array set CrtItemType {
        Tk_CreateItemType               "¥typePtr¥"
        Tk_GetItemTypes                 ""
    }
    array set CrtPhImgFmt {
        Tk_CreatePhotoImageFormat       "¥formatPtr¥"
    }
    array set CrtSelHdlr {
        Tk_CreateSelHandler             "¥tkwin¥, ¥selection¥, ¥target¥,\
	  ¥proc¥, ¥clientData¥, ¥format¥"
        Tk_DeleteSelHandler             "¥tkwin¥, ¥selection¥, ¥target¥"
    }
    array set CrtWindow {
        Tk_CreateWindow                 "¥interp¥, parent, ¥name¥,\
	  ¥topLevScreen¥"
        Tk_Window
        Tk_CreateAnonymousWindow        "¥interp¥, parent, ¥topLevScreen¥"
        Tk_Window
        Tk_CreateWindowFromPath         "¥interp¥, ¥tkwin¥, ¥pathName¥,\
	  ¥topLevScreen¥"
        Tk_DestroyWindow                "¥tkwin¥"
        Tk_MakeWindowExist              "¥tkwin¥"
        
    }
    array set DeleteImg {
        Tk_DeleteImage                  "¥interp¥, ¥name¥"
    }
    array set DrawFocHlt {
        Tk_DrawFocusHighlight           "¥tkwin¥, ¥gc¥, ¥width¥, ¥drawable¥"
    }
    array set EventHndlr {
        Tk_CreateEventHandler           "¥tkwin¥, ¥mask¥, ¥proc¥, ¥clientData¥"
        Tk_DeleteEventHandler           "¥tkwin¥, ¥mask¥, ¥proc¥, ¥clientData¥"
    }
    array set FindPhoto {
        Tk_FindPhoto                    "¥interp¥, ¥imageName¥"
        Tk_PhotoPutBlock                "¥handle¥, ¥blockPtr¥, ¥x¥, ¥y¥,\
	  ¥width¥, ¥height¥, ¥compRule¥"
        Tk_PhotoPutZoomedBlock          "¥handle¥, ¥blockPtr¥, ¥x¥, ¥y¥,\
	  ¥width¥, ¥height¥, ¥zoomX¥, ¥zoomY¥, ¥subsampleX¥, ¥subsampleY¥,\
	  ¥compRule¥"
        Tk_PhotoGetImage                "¥handle¥, ¥blockPtr¥"
        Tk_PhotoBlank                   "¥handle¥"
        Tk_PhotoExpand                  "¥handle¥, ¥width¥, ¥height¥"
        Tk_PhotoGetSize                 "¥handle¥, ¥widthPtr¥, ¥heightPtr¥"
        Tk_PhotoSetSize                 "¥handle¥, ¥width¥, ¥height¥"
    }
    array set FontId {
        Tk_FontId                       "¥tkfont¥"
        Tk_GetFontMetrics               "¥tkfont¥, ¥fmPtr¥"
        Tk_PostscriptFontName           "¥tkfont¥, ¥dsPtr¥"
    }
    array set FreeXId {
        Tk_FreeXId                      "¥display¥, ¥id¥"
    }
    array set GeomReq {
        Tk_GeometryRequest              "¥tkwin¥, ¥reqWidth¥, ¥reqHeight¥"
        Tk_SetMinimumRequestSize        "¥tkwin¥, ¥minWidth¥, ¥minHeight¥"
        Tk_SetInternalBorder            "¥tkwin¥, ¥width¥"
        Tk_SetInternalBorderEx          "¥tkwin¥, ¥left¥, ¥right¥, ¥top¥,\
	  ¥bottom¥"
    }
    array set GetAnchor {
        Tk_GetAnchorFromObj             "¥interp¥, ¥objPtr¥, ¥anchorPtr¥"
        Tk_GetAnchor                    "¥interp¥, ¥string¥, ¥anchorPtr¥"
        Tk_NameOfAnchor                 "¥anchor¥"
    }
    array set GetBitmap {
        Tk_GetBitmapFromObj             "¥interp¥, ¥tkwin¥, ¥objPtr¥"
        Tk_GetBitmap                    "¥interp¥, ¥tkwin¥, ¥info¥"
        Tk_GetBitmapFromObj             "¥tkwin¥, ¥objPtr¥"
        Tk_DefineBitmap                 "¥interp¥, ¥name¥, ¥source¥, ¥width¥,\
	  ¥height¥"
        Tk_NameOfBitmap                 "¥display¥, ¥bitmap¥"
        Tk_SizeOfBitmap                 "¥display¥, ¥bitmap¥, ¥widthPtr¥,\
	  ¥heightPtr¥"
        Tk_FreeBitmapFromObj            "¥tkwin¥, ¥objPtr¥"
        Tk_FreeBitmap                   "¥display¥, ¥bitmap¥"
    }
    array set GetCapStyl {
        Tk_GetCapStyle                  "¥interp¥, ¥string¥, capPtr"
        Tk_NameOfCapStyle               "¥cap¥"
    }
    array set GetClrmap {
        Tk_GetColormap                  "¥interp¥, ¥tkwin¥, ¥string¥"
        Tk_FreeColormap                 "¥display¥, ¥colormap¥"
    }
    array set GetColor {
        Tk_AllocColorFromObj            "¥interp¥, ¥tkwin¥, ¥objPtr¥"
        Tk_GetColor                     "¥interp¥, ¥tkwin¥, ¥name¥"
        Tk_GetColorFromObj              "¥tkwin¥, ¥objPtr¥"
        Tk_GetColorByValue              "¥tkwin¥, ¥prefPtr¥"
        Tk_NameOfColor                  "¥colorPtr¥"
        Tk_GCForColor                   "¥colorPtr¥, ¥drawable¥"
        Tk_FreeColorFromObj             "¥tkwin¥, ¥objPtr¥"
        Tk_FreeColor                    "¥colorPtr¥"
    }
    array set GetCursor {
        Tk_AllocCursorFromObj           "¥interp¥, ¥tkwin¥, ¥objPtr¥"
        Tk_GetCursor                    "¥interp¥, ¥tkwin¥, ¥name¥"
        Tk_GetCursorFromObj             "¥tkwin¥, ¥objPtr¥"
        Tk_GetCursorFromData            "¥interp¥, ¥tkwin¥, ¥source¥,\
	  ¥mask¥, ¥width¥, ¥height¥, ¥xHot¥, ¥yHot¥, ¥fg¥, ¥bg¥"
        Tk_NameOfCursor                 "¥display¥, ¥cursor¥"
        Tk_FreeCursorFromObj            "¥tkwin¥, ¥objPtr¥"
        Tk_FreeCursor                   "¥display¥, ¥cursor¥"
    }
    array set GetDash {
        Tk_GetDash                      "¥interp¥, ¥string¥, ¥dashPtr¥"
    }
    array set GetFont {
        Tk_AllocFontFromObj             "¥interp¥, ¥tkwin¥, ¥objPtr¥"
        Tk_GetFont                      "¥interp¥, ¥tkwin¥, ¥string¥" 
        Tk_GetFontFromObj               "¥tkwin¥, ¥objPtr¥"
        Tk_NameOfFont                   "¥tkfont¥"
        Tk_FreeFontFromObj              "¥tkwin¥, ¥objPtr¥"
        Tk_FreeFont                     "¥tkfont¥"
    }
    array set GetGC {
        Tk_GetGC                        "¥tkwin¥, ¥valueMask¥, ¥valuePtr¥"
        Tk_FreeGC                       "¥display¥, ¥gc¥"
    }
    array set GetHINSTANCE {
        Tk_GetHINSTANCE                 ""
    }
    array set GetHWND {
        Tk_GetHWND                      "¥window¥"
    }
    array set GetImage {
        Tk_GetImage                     "¥interp¥, ¥tkwin¥, ¥name¥,\
	  ¥changeProc¥, ¥clientData¥"
        Tk_RedrawImage                  "¥image¥, ¥imageX¥, ¥imageY¥\
	  , ¥width¥, ¥height¥, ¥drawable¥, ¥drawableX¥, ¥drawableY¥"
        Tk_SizeOfImage                  "¥image¥, ¥widthPtr¥, ¥heightPtr¥"
        Tk_FreeImage                    "¥image¥"
    }
    array set GetJoinStl {
        Tk_GetJoinStyle                 "¥interp¥, ¥string¥, ¥joinPtr¥"
        Tk_NameOfJoinStyle              "¥join¥"
    }
    array set GetJustify {
        Tk_GetJustifyFromObj            "¥interp¥, ¥objPtr¥, ¥justifyPtr¥"
        Tk_GetJustify                   "¥interp¥, ¥string¥, ¥justifyPtr¥"
        Tk_NameOfJustify                "¥justify¥"
    }
    array set GetOption {
        Tk_GetOption                    "¥tkwin¥, ¥name¥, ¥class¥"
    }
    array set GetPixels {
        Tk_GetPixelsFromObj             "¥interp¥, ¥tkwin¥, ¥objPtr¥, ¥intPtr¥"
        Tk_GetPixels                    "¥interp¥, ¥tkwin¥, ¥string¥, ¥intPtr¥"
        Tk_GetMMFromObj                 "¥interp¥, ¥tkwin¥, ¥objPtr¥,\
	  ¥doublePtr¥"
        Tk_GetScreenMM                  "¥interp¥, ¥tkwin¥, ¥string¥,\
	  ¥doublePtr¥"
    }
    array set GetPixmap {
        Tk_GetPixmap                    "¥display¥, d, ¥width¥, ¥height¥,\
	  ¥depth¥"
        Tk_FreePixmap                   "¥display¥, ¥pixmap¥"
    }
    array set GetRelief {
        Tk_GetReliefFromObj             "¥interp¥, ¥objPtr¥, ¥reliefPtr¥"
        Tk_GetRelief                    "¥interp¥, ¥name¥, ¥reliefPtr¥"
        Tk_NameOfRelief                 "¥relief¥"
    }
    array set GetRootCrd {
        Tk_GetRootCoords                "¥tkwin¥, ¥xPtr¥, ¥yPtr¥"
    }
    array set GetScroll {
        Tk_GetScrollInfo                "¥interp¥, ¥argc¥, ¥argv¥, ¥dblPtr¥,\
	  ¥intPtr¥"
        Tk_GetScrollInfoObj             "¥interp¥, ¥objc¥, ¥objv¥, ¥dblPtr¥,\
	  ¥intPtr¥"
    }
    array set GetSelect {
        Tk_GetSelection                 "¥interp¥, ¥tkwin¥, ¥selection¥,\
	  ¥target¥, ¥proc¥, ¥clientData¥"
    }
    array set GetUid {
        Tk_GetUid                       "¥string¥"      
    }
    array set GetVisual {
        Tk_GetVisual                    "¥interp¥, ¥tkwin¥, ¥string¥,\
	  ¥depthPtr¥, ¥colormapPtr¥"
    }
    array set GetVRoot {
        Tk_GetVRootGeometry             "¥tkwin¥, ¥xPtr¥, ¥yPtr¥, ¥widthPtr¥,\
	  ¥heightPtr¥"
    }
    array set Grab {
        Tk_Grab                         "¥interp¥, ¥tkwin¥, ¥grabGlobal¥"
        Tk_Ungrab                       "¥tkwin¥"
    }
    array set HandleEvent {
        Tk_HandleEvent                  "¥eventPtr¥"
    }
    array set HWNDToWindow {
        Tk_HWNDToWindow                 "¥hwnd¥"
    }
    array set IdToWindow {
        Tk_IdToWindow                   "¥display¥, ¥window¥"
    }
    array set ImgChanged {
        Tk_ImageChanged                 "¥imageMaster¥, ¥x¥, ¥y¥, ¥width¥,\
	  ¥height¥, ¥imageWidth¥, ¥imageHeight¥"
    }
    array set InternAtom {
        Tk_InternAtom                   "¥tkwin¥, ¥name¥"
        Tk_GetAtomName                  "¥tkwin¥, ¥atom¥"
    }
    array set MainLoop {
        Tk_MainLoop                     ""
    }
    array set MaintGeom {
        Tk_MaintainGeometry             "¥slave¥, ¥master¥, ¥x¥, ¥y¥,\
	  ¥width¥, ¥height¥"
        Tk_UnmaintainGeometry           "¥slave¥, ¥master¥"
    }
    array set MainWin {
        Tk_MainWindow                   "¥interp¥"
        Tk_GetNumMainWindows            ""
    }
    array set ManageGeom {
        Tk_ManageGeometry               "¥tkwin¥, ¥mgrPtr¥, ¥clientData¥"
    }
    array set MapWindow {
        Tk_MapWindow                    "¥tkwin¥"
        Tk_UnmapWindow                  "¥tkwin¥"
    }
    array set MeasureChar {
        Tk_MeasureChars                 "¥tkfont¥, ¥string¥, ¥numBytes¥,\
	  ¥maxPixels¥, ¥flags¥, ¥lengthPtr¥"
        Tk_TextWidth                    "¥tkfont¥, ¥string¥, ¥numBytes¥"
        Tk_DrawChars                    "¥display¥, ¥drawable¥, ¥gc¥,\
	  ¥tkfont¥, ¥string¥, ¥numBytes¥, ¥x¥, ¥y¥"
        Tk_UnderlineChars               "¥display¥, ¥drawable¥, ¥gc¥,\
	  ¥tkfont¥, ¥string¥, ¥x¥, ¥y¥, ¥firstByte¥, ¥lastByte¥"
    }
    array set MoveToplev {
        Tk_MoveToplevelWindow           "¥tkwin¥, ¥x¥, ¥y¥"
    }
    array set Name {
        Tk_Name                         "¥tkwin¥"
        Tk_PathName                     "¥tkwin¥"
        Tk_NameToWindow                 "¥interp¥, ¥pathName¥, ¥tkwin¥"
    }
    array set NameOfImg {
        Tk_NameOfImage                  "¥typePtr¥"
    }
    array set OwnSelect {
        Tk_OwnSelection                 "¥tkwin¥, ¥selection¥, ¥proc¥,\
	  ¥clientData¥"
    }
    array set ParseArgv {
        Tk_ParseArgv                    "¥interp¥, ¥tkwin¥, ¥argcPtr¥,\
	  ¥argv¥, argTable, ¥flags¥"       
    }
    array set QWinEvent {
        Tk_CollapseMotionEvents         "¥display¥, ¥collapse¥"
        Tk_QueueWindowEvent             "¥eventPtr¥, ¥position¥"
    }
    array set Restack {
        Tk_RestackWindow                "¥tkwin¥, ¥aboveBelow¥, ¥other¥"
    }
    array set RestrictEv {
        Tk_RestrictEvents               "¥proc¥, ¥clientData¥,\
	  ¥prevClientDataPtr¥"
    }
    array set SetAppName {
        Tk_SetAppName                   "¥tkwin¥, ¥name¥"
    }
    array set SetCaret {
        Tk_SetCaretPos                  "¥tkwin¥, ¥x¥, ¥y¥, ¥height¥"
    }
    array set SetClass {
        Tk_SetClass                     "¥tkwin¥, ¥class¥"
        Tk_Class                        "¥tkwin¥"
    }
    array set SetClassProcs {
        Tk_SetClassProcs                "¥tkwin¥, ¥procs¥, ¥instanceData¥"
    }
    array set SetGrid {
        Tk_SetGrid                      "¥tkwin¥, ¥reqWidth¥, ¥reqHeight¥,\
	  ¥widthInc¥, ¥heightInc¥"
        Tk_UnsetGrid                    "¥tkwin¥"
    }
    array set SetOptions {
        Tk_CreateOptionTable            "¥interp¥, ¥templatePtr¥"
        Tk_DeleteOptionTable            "¥optionTable¥"
        Tk_InitOptions                  "¥interp¥, ¥recordPtr¥, ¥optionTable¥,\
	  ¥tkwin¥"
        Tk_SetOptions                   "¥interp¥, ¥recordPtr¥, ¥optionTable¥,\
	  ¥objc¥, ¥objv¥, ¥tkwin¥, ¥savePtr¥, ¥maskPtr¥"
        Tk_FreeSavedOptions             "¥savedPtr¥"
        Tk_RestoreSavedOptions          "¥savedPtr¥"
        Tk_GetOptionValue               "¥interp¥, ¥recordPtr¥, ¥optionTable¥,\
	  ¥namePtr¥, ¥tkwin¥"
        Tk_GetOptionInfo                "¥interp¥, ¥recordPtr¥, ¥optionTable¥,\
	  ¥namePtr¥, ¥tkwin¥"
        Tk_FreeConfigOptions            "¥recordPtr¥, ¥optionTable¥, ¥tkwin¥"
        Tk_Offset                       "¥type¥, ¥field¥"
    }
    array set SetVisual {
        Tk_SetWindowVisual              "¥tkwin¥, visual, ¥depth¥, ¥colormap¥"
    }
    array set StrictMotif {
        Tk_StrictMotif                  "¥tkwin¥"
    }
    array set TextLayout {
        Tk_ComputeTextLayout            "¥tkfont¥, ¥string¥, ¥numChars¥,\
	  ¥wrapLength¥, ¥justify¥, ¥flags¥, ¥widthPtr¥, ¥heightPtr¥"
        Tk_FreeTextLayout               "¥layout¥"
	Tk_DrawTextLayout               "¥display¥, ¥drawable¥, ¥gc¥,\
	  ¥layout¥, ¥x¥, ¥y¥, ¥firstChar¥, ¥lastChar¥"
        Tk_UnderlineTextLayout          "¥display¥, ¥drawable¥, ¥gc¥,\
	  ¥layout¥, ¥x¥, ¥y¥, ¥underline¥"
        Tk_PointToChar                  "¥layout¥, ¥x¥, ¥y¥"
        Tk_CharBbox                     "¥layout¥, ¥index¥, ¥xPtr¥, ¥yPtr¥,\
	  ¥widthPtr¥, ¥heightPtr¥"
        Tk_DistanceToTextLayout         "¥layout¥, ¥x¥, ¥y¥"
        Tk_IntersectTextLayout          "¥layout¥, ¥x¥, ¥y¥, ¥width¥,\
	  ¥height¥"
        Tk_TextLayoutToPostscript       "¥interp¥, ¥layout¥"
    }
    array set Tk_Init {
        Tk_Init                         "¥interp¥"
        Tk_SafeInit                     "¥interp¥"
    }
    array set Tk_Main {
        Tk_Main                         "¥argc¥, ¥argv¥, ¥appInitProc¥"
    }   
    array set TkInitStubs {
        Tk_InitStubs                    "¥interp¥, ¥version¥, ¥exact¥"
    }
    array set WindowId {
        Tk_WindowId                     "¥tkwin¥"
        Tk_Parent                       "¥tkwin¥"
        Tk_Display                      "¥tkwin¥"
        Tk_DisplayName                  "¥tkwin¥"
        Tk_ScreenNumber                 "¥tkwin¥"
        Tk_Screen                       "¥tkwin¥"
        Tk_X                            "¥tkwin¥"
        Tk_Y                            "¥tkwin¥"
        Tk_Width                        "¥tkwin¥"
        Tk_Height                       "¥tkwin¥"
        Tk_Changes                      "¥tkwin¥"
        Tk_Attributes                   "¥tkwin¥"
        Tk_IsContainer                  "¥tkwin¥"
        Tk_IsEmbedded                   "¥tkwin¥"
        Tk_IsMapped                     "¥tkwin¥"
        Tk_IsTopLevel                   "¥tkwin¥"
        Tk_ReqWidth                     "¥tkwin¥"
        Tk_ReqHeight                    "¥tkwin¥"
        Tk_MinReqWidth                  "¥tkwin¥"
        Tk_MinReqHeight                 "¥tkwin¥"
        Tk_InternalBorderLeft           "¥tkwin¥"
        Tk_InternalBorderRight          "¥tkwin¥"
        Tk_InternalBorderTop            "¥tkwin¥"
        Tk_InternalBorderBottom         "¥tkwin¥"
        Tk_Visual                       "¥tkwin¥"
        Tk_Depth                        "¥tkwin¥"
        Tk_Colormap                     "¥tkwin¥"
    }
}

# ×××× -------- ×××× #

namespace eval C::tcltk {}

##
 # --------------------------------------------------------------------------
 # 
 # "C::tcltk::initialize" --
 # 
 # Called when this package is first initialized.
 # 
 # Define new 'Celectrics', 'Ccmds' based on the arrays defined above.
 # Define some prefs that we need for command double-clicking.
 # 
 # Register a mode::init hook so that we can redefine [C++::DblClick] after
 # the mode has been loaded.  Note that we also attempt to do so immediately,
 # in case this package is activated after C/C++ mode has been loaded.
 # 
 # --------------------------------------------------------------------------
 ##

proc C::tcltk::initialize {} {
    
    # Attempt to load Tcl mode.
    loadAMode "Tcl"
    # Command-Double-Clicking on a Tcl/Tk command will provide web-based
    # documentation from this local help directory.
    newPref folder tcl/TkHelpLocalFolder \
      [lindex [mode::getVarInfo tcl/TkHelpLocalFolder Tcl] 1] C++
    # Command-Double-Clicking on a Tcl/Tk command will provide web-based
    # documentation from this location if the 'Tcl/Tk Help Local Folder'
    # doesn't exist.
    newPref url tcl/TkHelpUrlDir \
      [lindex [mode::getVarInfo tcl/TkHelpUrlDir Tcl] 1] C++
    
    # Define the new C electrics.
    C::tcltk::defineCelectrics
    C::tcltk::defineCcmds
    C::tcltk::defineDblClick
    # Register a mode::init hook.
    hook::register mode::init {C::tcltk::defineDblClick} C C++ Objc
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "C::tcltk::defineCelectrics" --
 # 
 # Creates electric completions for C/C++ modes for the Tcl/Tk commands
 # defined above.
 # 
 # --------------------------------------------------------------------------
 ##

proc C::tcltk::defineCelectrics {} {
    
    global Celectrics C++electrics Objcelectrices
    
    variable tclKeywords
    variable tkKeywords
    variable tcltkKeywordsRedirect

    foreach type [list "tcl" "tk"] {
	foreach arrayName [info vars "::C::tcltk::${type}::*"] {
	    regsub "^::C::tcltk::${type}::" $arrayName "" helpFile
	    foreach item [array names $arrayName] {
		foreach m [list "C" "C++" "Objc"] {
		    set ${m}electrics($item) "([set [set arrayName]($item)])¥¥"
		} 
		set tcltkKeywordsRedirect($item) $helpFile
		lappend ${type}Keywords $item
	    }
	}
    }
    set tclKeywords [lsort -dictionary -unique $tclKeywords]
    set tkKeywords  [lsort -dictionary -unique $tkKeywords]
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "C::tcltk::defineCcmds" --
 # 
 # Adds all of the Tcl/Tk commands defined above to the 'Ccmds' list.
 # 
 # --------------------------------------------------------------------------
 ##

proc C::tcltk::defineCcmds {} {
    
    global Ccmds C++cmds Ojbccmds
    
    variable tclKeywords
    variable tkKeywords
    
    foreach m [list "C" "C++" "Objc"] {
	eval [list lappend ${m}cmds] $tclKeywords $tkKeywords
	set ${m}cmds [lsort -dictionary -unique [set ${m}cmds]]
    } 
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "C::tcltk::defineDblClick" --
 # "C::tcltk::DblClick" --
 # 
 # Intervene in [C++::DblClick] so that we can provide web-based help for the
 # Tcl/Tk commands defined above.  If [C++::DblClick] cannot be auto_loaded,
 # then something is seriously wrong!
 # 
 # --------------------------------------------------------------------------
 ##

proc C::tcltk::defineDblClick {args} {

    if {![llength [info procs ::C++::DblClick]] \
      && ![auto_load ::C++::DblClick]} {
	return
    }
    if {![llength [info procs preTcltkExtendedDblClick]]} {
	rename ::C++::DblClick preTcltkExtendedDblClick
    } 
    ;proc ::C++::DblClick {args} {eval C::tcltk::DblClick $args}
}

proc C::tcltk::DblClick {args} {
    
    global C++modeVars

    variable tclKeywords
    variable tkKeywords
    variable tcltkKeywordsRedirect

    # Is the click word included in one of our lists?
    set txt1 [getText [lindex $args 0] [lindex $args 1]]
    if {[lsearch -sorted -dictionary $tclKeywords $txt1] > -1} {
	set dirName  "TclLib"
    } elseif {[lsearch -sorted -dictionary $tkKeywords $txt1] > -1} {
        set dirName  "TkLib"
    } else {
	return [eval preTcltkExtendedDblClick $args]
    }
    # Still here?
    set redirect   $tcltkKeywordsRedirect($txt1)
    set localHelp  [set C++modeVars(tcl/TkHelpLocalFolder)]
    set remoteHelp [set C++modeVars(tcl/TkHelpUrlDir)]
    set baseDir    [file join $localHelp $dirName]
    if {[file isdir $baseDir]} {
	htmlView [file join $baseDir ${redirect}.htm]
    } else {
	urlView ${remoteHelp}/${dirName}/${redirect}.htm
    }
    return
}

# ===========================================================================
# 
# .