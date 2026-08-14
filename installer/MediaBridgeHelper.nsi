; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

Unicode True
SetCompressor /SOLID zlib

!include "MUI2.nsh"

!define APP_NAME "Media Bridge Helper"
!define APP_VERSION "0.2.2"
!define NATIVE_HOST "com.media_bridge.helper"

Name "${APP_NAME}"
OutFile "..\dist\installer\MediaBridgeHelper-Setup-${APP_VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\Media Bridge Helper"
InstallDirRegKey HKCU "Software\Media Bridge\Helper" "InstallDir"
RequestExecutionLevel user
BrandingText "Media Bridge"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Media Bridge Helper" SEC_MAIN
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File /r "..\dist\helper\MediaBridgeHelper\*"
  File /oname=${NATIVE_HOST}.chromium.json "..\.build\installer\${NATIVE_HOST}.chromium.json"
  File /oname=${NATIVE_HOST}.firefox.json "..\.build\installer\${NATIVE_HOST}.firefox.json"

  SetRegView 64
  WriteRegStr HKCU "Software\Google\Chrome\NativeMessagingHosts\${NATIVE_HOST}" "" "$INSTDIR\${NATIVE_HOST}.chromium.json"
  WriteRegStr HKCU "Software\Microsoft\Edge\NativeMessagingHosts\${NATIVE_HOST}" "" "$INSTDIR\${NATIVE_HOST}.chromium.json"
  WriteRegStr HKCU "Software\Mozilla\NativeMessagingHosts\${NATIVE_HOST}" "" "$INSTDIR\${NATIVE_HOST}.firefox.json"
  WriteRegStr HKCU "Software\Media Bridge\Helper" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "Publisher" "Soft Harbor Studio"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper" "NoRepair" 1

  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  SetRegView 64
  DeleteRegKey HKCU "Software\Google\Chrome\NativeMessagingHosts\${NATIVE_HOST}"
  DeleteRegKey HKCU "Software\Microsoft\Edge\NativeMessagingHosts\${NATIVE_HOST}"
  DeleteRegKey HKCU "Software\Mozilla\NativeMessagingHosts\${NATIVE_HOST}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MediaBridgeHelper"
  DeleteRegKey HKCU "Software\Media Bridge\Helper"
  RMDir /r "$INSTDIR"
SectionEnd
