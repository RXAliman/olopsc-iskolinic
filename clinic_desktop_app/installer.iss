; ═══════════════════════════════════════════════════════════════════════
; Inno Setup Script — OLOPSC IskoLinic Desktop App
; ═══════════════════════════════════════════════════════════════════════
;
; Usage:
;   iscc.exe /DMyAppVersion=1.0.0 installer.iss
;
; If MyAppVersion is not provided, defaults to "1.0.0".
; ═══════════════════════════════════════════════════════════════════════

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName "OLOPSC IskoLinic"
#define MyAppPublisher "Rovic Aliman"
#define MyAppExeName "olopsc-iskolinic.exe"
#define MyAppId "{{A9F2D7E0-5B3C-4A1E-8D6F-2C9E7B4A3D1F}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppCopyright=Copyright (C) 2026 {#MyAppPublisher}. All rights reserved.
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=dist
OutputBaseFilename=OLOPSC-IskoLinic-Setup
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
; Close the running app before installing (handles auto-updates too)
CloseApplications=force
CloseApplicationsFilter=olopsc-iskolinic.exe
; Allow updating without uninstalling first
UsePreviousAppDir=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Include all files from the Flutter release build output
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Launch the app after installation (unless running in silent mode)
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
// ═══════════════════════════════════════════════════════════════════
//  Uninstall: prompt user to delete AppData (patient database, etc.)
// ═══════════════════════════════════════════════════════════════════
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDataDir: String;
  ParentDir: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Path where Flutter's getApplicationSupportDirectory() stores data.
    // This contains clinic.db, Google Fonts cache, and other app data.
    AppDataDir := ExpandConstant('{userappdata}\Iskolinic Team\OLOPSC Iskolinic');

    if DirExists(AppDataDir) then
    begin
      if MsgBox(
        'Do you also want to remove all patient data and application settings?' + #13#10 + #13#10 +
        'This will permanently delete the clinic database and all saved data.' + #13#10 +
        'This action cannot be undone.',
        mbConfirmation,
        MB_YESNO or MB_DEFBUTTON2
      ) = IDYES then
      begin
        // Delete the app data directory recursively
        DelTree(AppDataDir, True, True, True);

        // Try to remove the parent company directory if it's now empty
        ParentDir := ExpandConstant('{userappdata}\Iskolinic Team');
        RemoveDir(ParentDir);
      end;
    end;
  end;
end;
