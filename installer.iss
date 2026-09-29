; Inno Setup script for Spinclip - same shape as the daw-project-manager
; sibling project's installer.iss.

; Version is injected by CI via environment variable APP_VERSION.
; Fallback keeps local builds working.
#define APP_VERSION GetEnv('APP_VERSION')
#if APP_VERSION == ""
  #define APP_VERSION "0.0.0"
#endif

[Setup]
; A fixed, unique identifier so future versions upgrade in place instead of
; installing side by side - generated once for Spinclip specifically, never
; reused from another product.
AppId={{EFDCBED9-2312-4A86-A66A-784FF3120338}
AppName=Spinclip
AppVersion={#APP_VERSION}
AppPublisher=BandPass Records
AppPublisherURL=https://github.com/bandpassrecords/spinclip
AppSupportURL=https://github.com/bandpassrecords/spinclip/issues
AppUpdatesURL=https://github.com/bandpassrecords/spinclip/releases
DefaultDirName={autopf}\Spinclip
DefaultGroupName=Spinclip
OutputBaseFileName=Spinclip_Installer_v{#SetupSetting("AppVersion")}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
; Everything from the Flutter release build, in one line.
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Spinclip"; Filename: "{app}\spinclip.exe"
Name: "{autodesktop}\Spinclip"; Filename: "{app}\spinclip.exe"
