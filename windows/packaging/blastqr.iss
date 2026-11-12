; Inno Setup script for the Windows installer. CI passes AppVersion,
; BuildDir (the Flutter Release folder) and OutputName on the command line.

[Setup]
; Never change AppId: Windows uses it to recognize upgrades of the same app.
AppId={{C6F4B1AF-C395-4913-B0D8-D1ECB39EEC11}
AppName=blastQR
AppVersion={#AppVersion}
AppPublisher=Blast Studio Inc.
AppPublisherURL=https://codeberg.org/blast/blastqr
DefaultDirName={autopf}\blastQR
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\blastQR.exe
OutputBaseFilename={#OutputName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\blastQR"; Filename: "{app}\blastQR.exe"
Name: "{autodesktop}\blastQR"; Filename: "{app}\blastQR.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\blastQR.exe"; Description: "{cm:LaunchProgram,blastQR}"; Flags: nowait postinstall skipifsilent
