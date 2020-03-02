################################################################################
#
# matlabMenu.tcl, part of the matlab mode package
# 
# MATLAB menu definitions
# 
################################################################################

proc matlabMenu.tcl {} {}

################################################################################
# Define the MATLAB menu
################################################################################

Menu -n $MATLMenu -M MATL -p matlabMenuItem {
	"<O<U/MswitchToMatlab"
	"<O<U/CcommandWindow"
	"<O<U/HcommandHistory"
	"(-"
	"<O<U/OeditInMatlab"
	"<O<U/SexecuteSelection"
	"<O<U/EsaveAndExecute"
	"<O<U/DopenSelection"
	"(-"
	{Menu -n commandHelp -M MATL -p matlabMenuItem {
		"<O<U//normalHelp"
		"<O<U<I/DhelpSelection"
		"<O<U/tsearchDocumentation"
		"makeDocumentation"
	}}
	{Menu -n workspace -M MATL -p matlabMenuItem {
		"<O<U/PrebuildPath"
		"addToPath"
		"cdToWin"
		"<O<U/KclearWorkspace"
		"<O<U<I/KclearProcedure"
		"<O<U/FcloseAll"
		"clearEventQue"
	}}
	{Menu -n debug -M MATL -p matlabMenuItem {
		"debugInMatlab"
		"<O<U/BstopIfError"
		"stopInFile"
		"stopAtCurrentLine"
		"<B<I/SstepOneLine"
		"clearAllBreakpoints"
		"fileBreakpoints"
		"<O<U/GopenErrorFile"
	}}
	{Menu -n quickOptions -M MATL -p matlabMenuItem {
		"clearOnSave"
		"webHelp"
	}}
}

################################################################################
# Mark the quickOptions
################################################################################

markMenuItem quickOptions clearOnSave $MATLmodeVars(clearOnSave)
markMenuItem quickOptions webHelp $MATLmodeVars(webHelp)

################################################################################
# Call Menu item procs
################################################################################

proc matlabMenuItem {menu item} {
	global MATLMenu
	switch -- $menu $MATLMenu {
		switch -- $item {
			switchToMatlab     {matlab}
			commandWindow      {matlabCmdWindow}
			Matl_commandHistory     {matlabCmdHistWindow}
			editInMatlab       {editInMatlab}
			saveAndExecute     {matlabSaveAndExecute}
			executeSelection   {matlabDoSelectionOrLine}
			openSelection      {matlabOpenSelection}
			default            {catch {matDummyMenuItem $menu $item}}
		}
	} workspace {
		switch -- $item {
			rebuildPath        {matlabRebuildPath}
			clearWorkspace     {matlabClear}
			clearProcedure     {matlabClearProcedure}
			closeAll           {matlabCloseAll}
			addToPath          {matlabAddToPath}
			cdToWin            {matlabCdToWin}
			clearEventQue      {MATL::clearEventQue}
		}
	} commandHelp {
		switch -- $item {
			normalHelp            {matlabHelp}
			searchDocumentation   {matlabSearchHelpDialog}
			helpSelection         {matlabHelpSelection}
			makeDocumentation     {makeMatlabHTML}
		}
	} debug {
		switch -- $item {
			debugInMatlab        {debugInMatlab}
			stopIfError          {matlabStopIfError}
			stopInFile           {matlabStopInFile}
			stopAtCurrentLine    {matlabStopAtCurrentLine}
			stepOneLine          {matlabDebugStep}
			clearAllBreakpoints  {matlabDbClear}
			fileBreakpoints      {matlabDebugStatus}
			openErrorFile        {matlabOpenErrorFile}
		}
	} quickOptions {
		switch -- $item {
			clearOnSave       {matlabMenuSwap clearOnSave}
			webHelp           {matlabMenuSwap webHelp}
		}
	}
}


################################################################################
# Change quickOptions
################################################################################

proc matlabMenuSwap {item} {
   global MATLmodeVars

   set MATLmodeVars($item) [expr ! $MATLmodeVars($item)]
   prefs::modified MATLmodeVars($item)
   markMenuItem quickOptions $item $MATLmodeVars($item)
}

