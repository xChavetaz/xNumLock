EnableExplicit
Global XApp.s = "xNumLock"
Global Version.s = Xapp + " v.1.1 (Build " + Str(#pb_editor_buildcount)+")"

IncludeFile  "..\3.xIncludes\IconLibrary.pbi" 
IncludeFile  "..\3.xIncludes\TaskbarHide.pbi" 
IncludeFile  "..\3.xIncludes\LibreriaGral.pbi" 
XIncludeFile "..\3.xIncludes\Multilanguage.pbi"
XIncludeFile "..\3.xIncludes\xWinAPI.pbi"
XIncludeFile "WinAbout.pbf"

UsePNGImageDecoder()

;- ############ Constantes ###############
#DI_NORMAL = $0003
#DI_IMAGE  = $0002

#POPUPMENUITEM = 10
#MENUSYSTRAY   = 11
#MIIM_STATE    = 1  
#MFS_DEFAULT   = 4096  

#XS_BTN_SIZE = 64
#XS_ROW_SIZE = 66

;- ############ Variables ################
Global Salida = 0
Global Event.l , WinEvent.l, GadEvent.l,  MenuEvent.l
Global MainWin
Global Frame
Global Hidden = #True
Global GadgetMenu = 0
Global WinMain_Rows.i = #XS_ROW_SIZE
Global DockMax_Cols.i = 0

;- ############ Procedures #############
Procedure.s AppPath()  ;IMPORTANT: Always includes a trailing slash (\ in Windows, / in Linux&Mac)
  Static init, sVal.s
  If init = 0
    sVal = GetPathPart(ProgramFilename())
    If Right(sVal,1) <> "\" And Right(sVal,1) <> "/"
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        sVal = sVal + "\"
      CompilerElse
        sVal = sVal + "/"
      CompilerEndIf
    EndIf
    init = 1
  EndIf    
  ProcedureReturn sVal
EndProcedure

Procedure SetNumLock()
  If GetMenuItemState(#MENUSYSTRAY, 51) = 1 
    SetMenuItemState(#MENUSYSTRAY, 51, 0)   ; now remove the check mark
    SetKeyboardLED(#VK_NUMLOCK, #False)
  Else                           
    SetMenuItemState(#MENUSYSTRAY, 51, 1)    ; now set the check mark
    SetKeyboardLED(#VK_NUMLOCK, #True)
  EndIf
EndProcedure

Procedure ToogleStartUp()
  Protected tpath.s = xWinAPI::GetKnownFolderPath(#FOLDERID_startup)  + XApp +".lnk"
  
  If GetMenuItemState(#MENUSYSTRAY, 52) = 1 
    SetMenuItemState(#MENUSYSTRAY, 52, 0)   ; now remove the check mark
    DeleteFile(tpath)
  Else                           
    SetMenuItemState(#MENUSYSTRAY, 52, 1)    ; now set the check mark
    xWinAPI::CreateShellLink(ProgramFilename(),tpath, "", XApp, GetPathPart(ProgramFilename()), ProgramFilename(),0)
  EndIf
EndProcedure

Procedure StartUpStatus()
  Protected tpath.s = xWinAPI::GetKnownFolderPath(#FOLDERID_startup)  + XApp +".lnk"
  
  Result.q = FileSize(tpath)
  
  If  Result = -1 
    SetMenuItemState(#MENUSYSTRAY, 52, 0)   ; remove the check mark
  Else
    SetMenuItemState(#MENUSYSTRAY, 52, 1)   ; set the check mark
  EndIf
  
EndProcedure

Procedure SiteLinkEvent(EventType)
  RunProgram ( "https://sites.google.com/view/xsalomone" )
EndProcedure

Procedure PayLinkEvent(EventType)
  RunProgram ( "http://PayPal.Me/Rodrigo32" )
EndProcedure

Language::Load(?English)

;- ############## Menues ################
If CreatePopupMenu(#MENUSYSTRAY)     
  MenuItem(49, Version)      
  MenuBar()   
  MenuItem(51, Language::Get("MenuTray","Numlock"))
  MenuItem(52, Language::Get("MenuTray","AutoRun"))  
  MenuItem(58, Language::Get("MenuTray","About"))      
  MenuBar()      
  MenuItem(59, Language::Get("MenuTray","Quit"))
EndIf

SetMenuItemState(#MENUSYSTRAY, 51, #True)
SetKeyboardLED(#VK_NUMLOCK, #True)

bold.MENUITEMINFO  
bold\cbSize=SizeOf(bold)  
bold\fMask=#MIIM_STATE  
bold\fState=#MFS_DEFAULT  

;- ############## MAIN ################
If CreateMutex_(0,1,XApp)=0 Or GetLastError_()<>0 : End : EndIf

InitHideFromTaskbar()
; ExamineDesktops()
Define DesktopRect.RECT
SystemParametersInfo_(#SPI_GETWORKAREA, 0, @DesktopRect.RECT, 0)
Define DesktopWidth = DesktopRect\right - DesktopRect\left

MainWin = OpenWindow(#PB_Any, 0, 0, DesktopWidth, WinMain_Rows, "", #PB_Window_BorderLess)
DockMax_Cols = Round(WindowWidth(MainWin) / #XS_BTN_SIZE, #PB_Round_Down) - 2
HideFromTaskbar(WindowID(MainWin),#True)
HideWindow(MainWin, Hidden) 

Img_tray = CatchImage(#PB_Any,?Image_tray)
AddSysTrayIcon(1, WindowID(MainWin), ImageID(Img_tray))

StartUpStatus()

;--------------- Main LOOP ---------------
; The main event loop as usual, the only change is to call the automatically
; generated event procedure for each window.
Repeat
  Event = WaitWindowEvent(1000)
  WinEvent = EventWindow()
  GadEvent = EventGadget()
  MenuEvent = EventMenu()
  
  If Event = 0       ;TIMEOUT
    SetKeyboardLED(#VK_NUMLOCK, GetMenuItemState(#MENUSYSTRAY, 51))  
    
  Else
;     Debug "Main->   W" + Str(WinEvent) + "   E" + Str(event)
    Select WinEvent
        
      Case MainWin
        Select Event
            
          Case #PB_Event_CloseWindow
            Result = MessageRequester("debug", "closing")
            
            
          Case #PB_Event_Menu
            Select MenuEvent
  
              Case 51                         ; NumLock
                SetNumLock()
                
              Case 52                         ; Autorun
                ToogleStartUp()
                                
              Case 58                         ; Acerca de...              
                OpenWinAbout()
                SetGadgetText(Editor_1, Language::Get("Main","TextFree"))
                
              Case 59                         ; Salir!
                CloseWindow(#PB_All)
                Salida = 1
                
            EndSelect
            
          Case #PB_Event_SysTray
            Select EventType() 
              Case #PB_EventType_RightClick
                DisplayPopupMenu(#MENUSYSTRAY ,WindowID(MainWin))
                
              Case #PB_EventType_LeftDoubleClick 
;                 Hidden = #False
;                 HideWindow(MainWin, Hidden)
            EndSelect
            
          Case #PB_Event_Gadget
;             Select EventGadget()
;               Case Btn_close
;                 If EventType() = #PB_EventType_LeftClick 
;                   If DockPrefTray
;                     Hidden = #True
;                     HideWindow(MainWin, Hidden) 
;                   Else
;                     CloseWindow(#PB_All)
;                     Salida = 1
;                   EndIf
;                 EndIf
;               Default
;                 Select EventType()
;                     ; Case #PB_EventType_LeftDoubleClick  : Debug "Double-click with left mouse button"
;                     ; Case #PB_EventType_RightDoubleClick : Debug "Double-click with right mouse button"
;                 EndSelect
;             EndSelect
;             
;           Case #WM_HOTKEY
;             If Hidden 
;               Hidden = #False
;             Else
;               Hidden = #True
;             EndIf
;             HideWindow(MainWin, Hidden) 
            
        EndSelect
        ;--------------- WinAbout LOOP ---------------      
      Case WinAbout
        If WinAbout_Events(Event) = #False
          CloseWindow(WinAbout)
          Event = 0
        EndIf                      
    EndSelect
    
  EndIf
  
Until Event = #PB_Event_CloseWindow Or Salida = 1; Quit on any window close

EndHideFromTaskbar()

;- ############## DataSection ################
;--------------- Images --------------- 
DataSection
  Image_tray: 
  IncludeBinary "Img\xnum_24x24-32.png"
  Image_exe: 
  IncludeBinary "Img\xnum_64x64-32.png"
  
;--------------- Lang: English ---------------  
  English:
  ; ===================================================
  Data.s "_GROUP_",            "Main"
  ; ===================================================
  Data.s "Error",            "Error"
  Data.s "ErrPref",          "Unable to open settings file "
  Data.s "TextFree",         "This application can be used and distributed ONLY for non-commercial purposes";"Esta aplicación sólo se podrá usar y distribuir para fines NO comerciales."
  
  ; ===================================================
  Data.s "_GROUP_",            "Popup"
  ; ===================================================
  Data.s "Remove",           "Remove"
  Data.s "Location",         "Open Location"
  
  ; ===================================================
  Data.s "_GROUP_",            "MenuTray"
  ; ===================================================
  Data.s "Show",             "Show"
  Data.s "NumLock",          "NumLock ON"
  Data.s "Prefs",            "Preferences"
  Data.s "About",            "About..."
  Data.s "Quit",             "Quit"
  Data.s "NewStick",         "New Sticky"
  Data.s "SubUtils",         "Utilities"
  Data.s "WinNet",           "Net Info"
  Data.s "AutoRun",          "Start with Windows"  
  
  ; ===================================================
  Data.s "_GROUP_",            "Prefs"
  ; ===================================================
  Data.s "Start",            "Start with Windows"
  Data.s "Close",            "Close to Tray"
  Data.s "DockFrame",        "Dock"
  Data.s "TabGen",           "General"
  Data.s "TabKeys",          "Hotkeys"
  Data.s "TabSys",           "SysInfo"
  Data.s "StickyFrame",      "Stickys"
  
  ; ===================================================
  Data.s "_GROUP_",            "Dock"
  ; ===================================================
  Data.s "Confirm",          "Confirm"
  Data.s "Sure",             "Are You Sure?"

  ; ===================================================
  Data.s "_END_",              ""
  ; ===================================================  
EndDataSection
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 2
; Folding = --
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant