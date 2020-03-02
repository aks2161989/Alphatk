# Automatically created by mode assistant
#
# Mode: VB


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode [list VB "Visual Basic"] 0.1 source {
    *.bas *.frm *.cls *.vbs *.asp *.inc 
} {
} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Microsoft Visual Basic programming files
} help {
    This mode is for editing Microsoft's Visual Basic files.

    Visual Basic is a graphical programming language and development
    environment created by Microsoft in 1990.
    
    More information can be found here: <http://msdn.microsoft.com/vbasic/>
}

# For Tcl 8
namespace eval VB {}

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 0 VB
# To automatically indent the new line produced by pressing Return, turn
# this item on.  The indentation amount is determined by the context||To
# have the Return key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 1 VB

newPref variable indentationAmount 2 VB

# These are used by the ::parseFuncs procedure when the user clicks on
# the {} button in a file edited using this mode.  If you need more sophisticated
# function marking, you need to add a VB::parseFuncs proc

newPref variable funcExpr {^([a-zA-Z]+[ \t]+)?(Sub|Function)[ \t]+([a-zA-Z0-9_]+)\(} VB
newPref variable parseExpr {([a-zA-Z0-9_]+)\($} VB

# Register comment prefix
set VB::commentCharacters(General) '
# Register multiline comments
set VB::commentCharacters(Paragraph) {{' } {' } {' }}
# List of keywords
set VBKeyWords {
    Abs Accept AccessKeyPress Activate Add AddCustom AddFile AddFromFile
    AddFromTemplate AddItem AddNew AddToAddInToolbar AddToolboxProgID
    AfterAddFile AfterChangeFileName AfterCloseFile AfterColEdit
    AfterColUpdate AfterDelete AfterInsert AfterLabelEdit AfterRemoveFile
    AfterUpdate AfterWriteFile AmbienChanged AppActivate Append
    AppendChunk ApplyChanges Arrange Array Asc AscB AscW Assert Associate
    AsyncRead AsyncReadComplete Atn Avg AxisActivated AxisLabelActivated
    AxisLabelSelected AxisLabelUpdated AxisSelected AxisTitleActivated
    AxisTitleSelected AxisTitleUpdated AxisUpdated Base BatchUpdate Beep
    BeforeClick BeforeColEdit BeforeColUpdate BeforeConnect BeforeDelete
    BeforeInsert BeforeLabelEdit BeforeLoadFile BeforeUpdate BeginTrans
    Bind ButtonClick ButtonCompleted ButtonGotFocus ButtonLostFocus Call
    Cancel CancelAsyncRead CancelBatch CancelUpdate CanPropertyChange
    CaptureImage Case CBool CByte CCur CDate CDbl Cdec CellText CellValue
    Change ChartActivated ChartSelected ChartUpdated ChDir ChDrive Choose
    Chr ChrB ChrW CInt Circle Clear ClearFields ClearSel ClearSelCols
    Click CLng Clone Close Cls ColContaining ColEdit Collapse ColResize
    ColumnClick ColumnSize Command CommitTrans CompactDatabase Compare
    Compose ConfigChageCancelled ConfigChanged Connect ConnectionRequest
    Const Copy CopyQueryDef Cos Count CreateDatabase CreateDragImage
    CreateEmbed CreateField CreateGroup CreateIndex CreateLink
    CreateObject CreatePreparedStatement CreatePropery CreateQuery
    CreateQueryDef CreateRelation CreateTableDef CreateUser
    CreateWorkspace CSng CStr CurDir Customize CVar CVDate CVErr
    DataArrival DataChanged DataUpdated Date DateAdd DateDiff DatePart
    DateSerial DateValue Day DblClick DDB Deactivate Declare DefBool
    DefByte DefCur DefDate DefDbl DefDec DefInt DefLng DefObj DefSng
    DefStr Deftype DefVar Delete DeleteColumnLabels DeleteColumns
    DeleteRowLabels DeleteRows DeleteSetting DeviceArrival
    DeviceOtherEvent DeviceQueryRemove DeviceQueryRemoveFailed
    DeviceRemoveComplete DeviceRemovePending DevModeChange Dim Dir
    Disconnect DisplayChanged Dissociate Do DoEvents DoGetNewFileName
    Done DonePainting DoVerb DownClick Drag DragDrop DragOver Draw
    DropDown Edit EditCopy EditPaste EditProperty Else ElseIf End EndDoc
    EnsureVisible EnterCell EnterFocus Enum Environ EOF Erase Error
    EstablishConnection Event Event Execute Exit ExitFocus Exp Expand
    Explicit ExtractIcon False Fetch FetchVerbs FileAttr FileCopy
    FileDateTime FileLen Files FillCache Find FindFirst FindItem FindLast
    FindNext FindPrevious Fix FootnoteActivated FootnoteSelected
    FootnoteUpdated For ForEach Format Forward FreeFile Friend Function
    FV Get GetAllStrings GetAttr GetAutoServerSettings GetBookmark
    GetChunk GetClipString GetData GetFirstVisible GetFormat GetHeader
    GetLineFromChar GetNumTicks GetObject GetRows GetSelectedPart
    GetSetting GetText GetVisibleCount GoBack GoForward GoSub GotFocus
    GoTo HeadClick Hex Hide HitTest HoldFields Hour Idle If IIf IMEStatus
    Implements InfoMessage IniProperties Initialize InitializeLabels
    Input InputB InputBox InsertColumnLabels InsertColumns InsertObjDlg
    InsertRowLabels InsertRows InstB InStr Int IPmt IsArray IsDate
    IsEmpty IsError IsMissing IsNull IsNumeric IsObject Item
    ItemActivated ItemAdded ItemCheck ItemClick ItemReloaded ItemRemoved
    ItemRenamed ItemSeletected KeyDown KeyPress KeyUp Kill KillDoc Layout
    LBound LCase LeaveCell Left LeftB LegendActivated LegendSelected
    LegendUpdated Len LenB Let Line LineInput LinkClose LinkError
    LinkExecute LinkNotify LinkOpen LinkPoke LinkRequest LinkSend Listen
    Load LoadFile LoadPicture LoadResData LoadResPicture LoadResString
    Loc Lock LOF Log LogEvent Loop LostFocus LSet LTrim MakeCompileFile
    MakeReplica Max Mid MidB Min Minute MIRR MkDir Month MoreResults
    MouseDown MouseMove MouseUp Move MoveData MoveFirst MoveLast MoveNext
    MovePrevious MsgBox Name NavigateTo NewPage NewPassword Next
    NextRecordset NodeClick Not Now NPer NPV ObjectMove Oct
    OLECompleteDrag OLEDrag OLEDragDrop OLEDragOver OLEGiveFeedback
    OLESetData OLEStartDrag On OnAddinsUpdate OnAddNew OnComm
    OnConnection OnDisconnection OnError OnStartupComplete Open
    OpenConnection OpenDatabase OpenQueryDef OpenRecordset OpenResultset
    OpenURL Option Overlay Paint PaintPicture PanelClick PanelDblClick
    Partition Paste PastSpecialDlg PathChange PatternChange PeekData Play
    PlotActivated PlotSelected PlotUpdated Pmt Point PointActivated
    PointLabelActivated PointLabelSelected PointLabelUpdated
    PointSelected PointUpdated PopulatePartial PopupMenu
    PowerQuerySuspend PowerResume PowerStatusChanged PowerSuspend PPmt
    Print PrintForm Private Property PropertyChanged PSet Public Put PV
    QBColor QueryChangeConfig QueryComplete QueryCompleted QueryTimeout
    QueryUnload Quit Raise RaiseEvent RandomDataFill RandomFillColumns
    RandomFillRows Randomize Rate rdoCreateEnvironment
    rdoRegisterDataSource ReadFromFile ReadProperties ReadProperty Rebind
    ReDim ReFill Refresh RefreshLink RegisterDatabase Reload Rem Remove
    RemoveAddInFromToolbar RemoveItem Render RepairDatabase Reply
    ReplyAll Reposition Requery RequestChangeFileName RequestWriteFile
    Reset ResetCustom ResetCustomLabel Resize ResolveName RestoreToolbar
    ResultsChanged Resume Resync Return RGB Right RightB RmDir Rnd
    Rollback RollbackTrans RowBookmark RowColChange RowContaining
    RowCurrencyChange RowResize RowStatusChanged RowTop RSet RTrim Save
    SaveAs SaveFile SavePicture SaveSetting SaveToFile SaveToolbar
    SaveToOle1File Scale ScaleX ScaleY Scroll Second Seek SelChange
    Select SelectAll SelectionChanged SelectPart SelPrint Send
    SendComplete SendData SendKeys SendProgress SeriesActivated
    SeriesSelected SeriesUpdated Set SetAttr SetAutoServerSettings
    SetData SetFocus SetOption SetSize SetText SettingChanged SetViewport
    Sgn Shell Show ShowColor ShowFont ShowHelp ShowOpen ShowPrinter
    ShowSave ShowWhatsThis SignOff SignOn Sin Size SLN Space Span Spc
    SplitChange SplitContaining Sqr StartLabelEdit StartLogging
    StateChanged Static StatusUpdate StDev StDevP Stop Str StrComp
    StrConv String Sub Sum Switch SYD Synchronize SysColorsChanged Tab
    Tan Terminate TextHeight TextWidth Then Time TimeChanged Timer
    TimeSerial TimeValue TitleActivated TitleActivated TitleSelected
    ToDefaults Trim True TwipsToChartPart Type TypeByChartType TypeName
    UBound UCase UnboundAddData UnboundDeleteRow
    UnboundGetRelativeBookmark UnboundReadData UnboundWriteData Unload
    Unlock UpClick Update UpdateControls Updated UpdateRecord UpdateRow
    Upto Val Validate ValidationError Var VarP VarType Weekday Wend
    WhatsThisMode While Width WillAssociate WillChangeData WillDissociate
    WillExecute WillUpdateRows With WithEvents Write WriteProperties
    WriteProperty Year ZOrder
    As Begin
}

# Colour the keywords, comments etc.
regModeKeywords -e ' VB $VBKeyWords
# Discard the list
unset VBKeyWords

proc VB::correctIndentation {args} {
    win::parseArgs w pos {next ""}
    set pos0 [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    set pat1 {^[ \t]*[^ \t\n\r]}

    set indPat {(Do|Else|Then|Select Case)\s*$}
    set unIndPat {(End|Next|End If|End Select|Loop|Wend|End Sub)\s*$}
    # Find last non-empty, non-comment line
    if {[catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 -- $pat1 $pos0} match]} {
	return 0
    }
    set pos1   [lindex $match 0]
    set pos2   [pos::math -w $w [pos::nextLineStart -w $w $pos1] - 1]
    set pos3   [pos::math -w $w [lindex $match 1] - 1]
    set line   [getText -w $w $pos1 $pos2]
    set lwhite [lindex [pos::toRowCol -w $w $pos3] 1]
    incr lwhite [expr {[text::getIndentationAmount -w $w] * \
      ([regexp -- $indPat $line] - [regexp -- $unIndPat $next])}]
    # Only happens with poorly formatted files.
    if {$lwhite < 0} {return 0} else {return $lwhite}
}
