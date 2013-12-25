; Copyright (C) 2011 Olivier Tilloy <olivier@tilloy.net>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; NSIS installer script for pyexiv2.

!include MUI.nsh
!include nsDialogs.nsh
!include LogicLib.nsh

!define PYEXIV2_VERSION "0.3.2"

Name "pyexiv2 ${PYEXIV2_VERSION}"
OutFile "pyexiv2-${PYEXIV2_VERSION}-setup.exe"
SetCompressor /SOLID lzma

!define MUI_ICON "art\pyexiv2.ico"
!define MUI_UNICON "art\pyexiv2.ico"

; Installer pages
!insertmacro MUI_PAGE_LICENSE "COPYING"
Page custom InstallationOptions InstallationOptionsLeave
!insertmacro MUI_PAGE_INSTFILES

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

!define PYTHON_MAJOR "2"
!define PYTHON_MINOR "7"
!define PYTHON_KEY "Software\Python\PythonCore\${PYTHON_MAJOR}.${PYTHON_MINOR}\InstallPath"
!define PYEXIV2_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\pyexiv2-${PYEXIV2_VERSION}"

Var python_install_path
Var python_installed_for_all
Var system_wide
Var user_site

; Function called when finishing initialization of the installer
Function .onInit
  ; The user site directory is always for the current user only, not for all users
  SetShellVarContext current
  StrCpy $user_site "$APPDATA\Python\Python${PYTHON_MAJOR}${PYTHON_MINOR}\site-packages"

  ; Look for Python system-wide (HKLM)
  SetShellVarContext all
  StrCpy $python_installed_for_all "true"
  ReadRegStr $python_install_path SHCTX ${PYTHON_KEY} ""
  StrCmp $python_install_path "" 0 Continue

  ; Look for Python for the current user (HKCU)
  SetShellVarContext current
  StrCpy $python_installed_for_all "false"
  ReadRegStr $python_install_path SHCTX ${PYTHON_KEY} ""
  StrCmp $python_install_path "" 0 Continue

  MessageBox MB_OK|MB_ICONSTOP "Unable to locate Python ${PYTHON_MAJOR}.${PYTHON_MINOR}."
  Quit

  Continue:
    StrCpy $system_wide "$python_install_pathLib\site-packages"
FunctionEnd

; Function called when finishing initialization of the uninstaller
Function un.onInit
  ; Look for pyexiv2 installed system-wide (HKLM)
  SetShellVarContext all
  ReadRegStr $INSTDIR SHCTX ${PYEXIV2_KEY} "InstallLocation"
  StrCmp $INSTDIR "" 0 Continue

  ; Look for pyexiv2 installed for the current user (HKCU)
  SetShellVarContext current
  ReadRegStr $INSTDIR SHCTX ${PYEXIV2_KEY} "InstallLocation"
  StrCmp $INSTDIR "" 0 Continue

  ; Cannot find pyexiv2 in the registry, aborting the uninstallation
  MessageBox MB_OK|MB_ICONSTOP "Unable to locate $(^Name)."
  Quit

  Continue:
FunctionEnd

; Custom page initialization for installation options
Function InstallationOptions
  !insertmacro MUI_HEADER_TEXT "Installation options" "Choose where to install pyexiv2."

  nsDialogs::Create 1018
  Var /GLOBAL dialog
  Pop $dialog
  ${If} $dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateRadioButton} 0 0 100% 24u "System wide ($system_wide)"
  Var /GLOBAL rb1
  Pop $rb1
  ${NSD_SetState} $rb1 ${BST_CHECKED}

  ${NSD_CreateRadioButton} 0 34 100% 24u "User site ($user_site)"
  Var /GLOBAL rb2
  Pop $rb2

  nsDialogs::Show
FunctionEnd

; Custom page on-leave callback
Function InstallationOptionsLeave
  ${NSD_GetState} $rb1 $0
  ${If} $0 == ${BST_CHECKED}
    ; Install pyexiv2 system wide
    StrCpy $INSTDIR $system_wide

    ; If Python was installed for all users, the user needs to be an
    ; administrator to install pyexiv2
    StrCmp $python_installed_for_all "true" 0 Continue
    userInfo::getAccountType
    pop $0
    StrCmp $0 "Admin" Continue 0

    MessageBox MB_OK|MB_ICONSTOP "You need to be an administrator to install $(^Name)."
    Quit

    Continue:
  ${Else}
    ; Install pyexiv2 in the user site directory
    StrCpy $INSTDIR $user_site
    SetShellVarContext current
  ${EndIf}
FunctionEnd

; Installation section
Section "pyexiv2"
  SetOutPath $INSTDIR
  File build\libexiv2python.pyd

  SetOutPath $INSTDIR\pyexiv2
  File src\pyexiv2\__init__.py
  File src\pyexiv2\metadata.py
  File src\pyexiv2\exif.py
  File src\pyexiv2\iptc.py
  File src\pyexiv2\xmp.py
  File src\pyexiv2\preview.py
  File src\pyexiv2\utils.py

  ; Create the uninstaller and publish it in the registry
  !define UNINSTALLER "$INSTDIR\pyexiv2-${PYEXIV2_VERSION}-uninstaller.exe"
  WriteUninstaller ${UNINSTALLER}
  WriteRegStr SHCTX ${PYEXIV2_KEY} "DisplayName" "pyexiv2 ${PYEXIV2_VERSION}"
  WriteRegStr SHCTX ${PYEXIV2_KEY} "DisplayVersion" ${PYEXIV2_VERSION}
  WriteRegStr SHCTX ${PYEXIV2_KEY} "DisplayIcon" "$\"${UNINSTALLER}$\""
  WriteRegStr SHCTX ${PYEXIV2_KEY} "InstallLocation" $INSTDIR
  WriteRegStr SHCTX ${PYEXIV2_KEY} "UninstallString" "$\"${UNINSTALLER}$\""
  WriteRegStr SHCTX ${PYEXIV2_KEY} "QuietUninstallString" "$\"${UNINSTALLER}$\" /S"
  WriteRegDWORD SHCTX ${PYEXIV2_KEY} "NoModify" 1
  WriteRegDWORD SHCTX ${PYEXIV2_KEY} "NoRepair" 1
SectionEnd

; Uninstallation section
Section "Uninstall"
  Delete $INSTDIR\libexiv2python.py*
  RMDir /r $INSTDIR\pyexiv2

  DeleteRegKey SHCTX ${PYEXIV2_KEY}

  Delete $INSTDIR\pyexiv2-${PYEXIV2_VERSION}-uninstaller.exe
SectionEnd

