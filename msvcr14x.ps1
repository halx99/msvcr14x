<#
tasks:
  build: build msvcr14x
  install: install msvcr14x
  uninstall: uninstall msvcr14x
  status: query whther msvcr14x installed properly
#>
param(
    $tasks = 'build,install'
)

function println ($msg) {
    Write-Host "msvcr14x: $msg"
}

$conf_file_dict = @{
    x86 = Join-Path $env:LOCALAPPDATA 'Microsoft\MSBuild\v4.0\Microsoft.Cpp.Win32.user.props'
    x64 = Join-Path $env:LOCALAPPDATA 'Microsoft\MSBuild\v4.0\Microsoft.Cpp.x64.user.props'
}

# by default all Microsoft.Cpp.$(arch).user.props files are binary same
$Script:msbuild_ns_uri = 'http://schemas.microsoft.com/developer/msbuild/2003'
$Script:msbuild_default_conf = @"
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Project DefaultTargets="Build" ToolsVersion="12.0" xmlns="$msbuild_ns_uri">
	<ImportGroup Label="PropertySheets">
	</ImportGroup>
	<PropertyGroup Label="UserMacros"/>
	<PropertyGroup>
		<IncludePath>`$(IncludePath)</IncludePath>
	</PropertyGroup>
	<ItemDefinitionGroup/>
	<ItemGroup/>
</Project>
"@

$cfgs = @(
    # off
    @{
        include = '$(IncludePath)';
        libs    = @{x86 = '%(AdditionalLibraryDirectories)'; x64 = '%(AdditionalLibraryDirectories)' }
    }
    # on
    @{
        include = '$(msvcr14x_ROOT)\..\ntdll\include;$(IncludePath)';
        libs    = @{
            x86 = '$(msvcr14x_ROOT)\Release;$(msvcr14x_ROOT)\Debug;$(msvcr14x_ROOT)\AnsiRelease;$(msvcr14x_ROOT)\AnsiDebug;%(AdditionalLibraryDirectories)'
            x64 = '$(msvcr14x_ROOT)\x64\Release;$(msvcr14x_ROOT)\x64\Debug;$(msvcr14x_ROOT)\x64\AnsiRelease;$(msvcr14x_ROOT)\x64\AnsiDebug;%(AdditionalLibraryDirectories)'
        }
    }
)

# for install/uninstall
$install_files = @("Debug\MSVCR14XD.dll"
    "Debug\MSVCP14XD.dll"
    "Debug\MSVCP14X_1D.dll"
    "Debug\MSVCP14X_2D.dll"
    "Debug\MSVCP14XD_ATOMIC_WAIT.dll"
    "Debug\MSVCP14XD_CODECVT_IDS.dll"
    "Debug\CONCRT14XD.dll"
    "Debug\MFC14XUD.dll"
    "Debug\MFC14XD.dll"
    "Release\MSVCR14X.dll"
    "Release\MSVCP14X.dll"
    "Release\MSVCP14X_1.dll"
    "Release\MSVCP14X_2.dll"
    "Release\MSVCP14X_ATOMIC_WAIT.dll"
    "Release\MSVCP14X_CODECVT_IDS.dll"
    "Release\CONCRT14X.dll"
    "Release\MFC14XU.dll"
    "Release\MFC14X.dll"
    "x64\Debug\MSVCR14XD.dll"
    "x64\Debug\MSVCP14XD.dll"
    "x64\Debug\MSVCP14X_1D.dll"
    "x64\Debug\MSVCP14X_2D.dll"
    "x64\Debug\MSVCP14XD_ATOMIC_WAIT.dll"
    "x64\Debug\MSVCP14XD_CODECVT_IDS.dll"
    "x64\Debug\CONCRT14XD.dll"
    "x64\Debug\MFC14XUD.dll"
    "x64\Debug\MFC14XD.dll"
    "x64\Release\MSVCR14X.dll"
    "x64\Release\MSVCP14X.dll"
    "x64\Release\MSVCP14X_1.dll"
    "x64\Release\MSVCP14X_2.dll"
    "x64\Release\MSVCP14X_ATOMIC_WAIT.dll"
    "x64\Release\MSVCP14X_CODECVT_IDS.dll"
    "x64\Release\CONCRT14X.dll"
    "x64\Release\MFC14XU.dll"
    "x64\Release\MFC14X.dll"
    "Release\MFC14XCHS.DLL"
    "Release\MFC14XCHT.DLL"
    "Release\MFC14XDEU.DLL"
    "Release\MFC14XENU.DLL"
    "Release\MFC14XESN.DLL"
    "Release\MFC14XFRA.DLL"
    "Release\MFC14XITA.DLL"
    "Release\MFC14XJPN.DLL"
    "Release\MFC14XKOR.DLL"
    "Release\MFC14XRUS.DLL"
    "x64\Release\MFC14XCHS.DLL"
    "x64\Release\MFC14XCHT.DLL"
    "x64\Release\MFC14XDEU.DLL"
    "x64\Release\MFC14XENU.DLL"
    "x64\Release\MFC14XESN.DLL"
    "x64\Release\MFC14XFRA.DLL"
    "x64\Release\MFC14XITA.DLL"
    "x64\Release\MFC14XJPN.DLL"
    "x64\Release\MFC14XKOR.DLL"
    "x64\Release\MFC14XRUS.DLL")
$system32_path = Join-Path $env:WINDIR 'System32\'
$syswow64_path = Join-Path $env:WINDIR 'SysWow64\'

$os_arch = [System.Runtime.InteropServices.RuntimeInformation, mscorlib]::OSArchitecture.ToString().ToLower()
$install_locs = @()
switch ($os_arch) {
    'x64' {
        $install_locs = @($syswow64_path, $system32_path)
        break
    }
    'x86' {
        $install_locs = @($system32_path, $null)
        break
    }
}

$external_prefix = Join-Path $PSScriptRoot '_deps'
if (!(Test-Path $external_prefix -PathType Container)) { New-Item $external_prefix -ItemType Directory | Out-Null }

function Format-Xml {
    [CmdletBinding()]
    param(
        # The Xml Document
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Document")]
        $Xml,

        # The path to an xml document (on disc or any other content provider).
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [Alias("PsPath")]
        [string]$Path,

        # The indent level (defaults to 2 spaces)
        [Parameter(Mandatory = $false)]
        [int]$Indent = 2,

        # The indent character (defaults to a space)
        [char]$Character = ' '
    )
    process {
        ## Load from file, if necessary
        if ($Path) { [xml]$xml = Get-Content $Path }

        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
        $xmlWriter.Indentation = $Indent
        $xmlWriter.IndentChar = $Character
        $xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        return $StringWriter.ToString()
    }
}

function mod_msbuild_conf($arch, $enable) {
    $conf_file = $conf_file_dict[$arch]

    # begin mod
    $incs = $cfgs[$enable].include
    $libs = $cfgs[$enable].libs[$arch]

    println "mod: $conf_file, incs=$incs, libs=$libs ..."
    $conf_content = $null
    if ((Test-Path $conf_file -PathType Leaf)) { $conf_content = Get-Content $conf_file }
    if (!$conf_content) { $conf_content = $msbuild_default_conf }
    [XML]$msbcDoc = $conf_content
    $nsmgr = [System.Xml.XmlNamespaceManager]::new($msbcDoc.NameTable);
    $nsmgr.AddNamespace('b', $msbuild_ns_uri); 
    $root = $msbcDoc.DocumentElement
    $IncludePathNodes = $root.SelectNodes('//b:IncludePath', $nsmgr)
    if ($IncludePathNodes.Count -gt 0) {
        $IncludePathNodes[0].InnerText = $incs
    }
    else {
        throw "Can't found IncludePath in $conf_file"
    }

    class XmlUtil {
        [System.Xml.XmlDocument]$doc
        [System.Xml.XmlNamespaceManager]$ns
        XmlUtil($doc, $nsmgr) {
            $this.doc = $doc
            $this.ns = $nsmgr
        }
        [System.Xml.XmlElement] child($parent, $name, $force) {
            $xmlNode = $null
            $xmlNodes = $parent.SelectNodes("//b:$name", $this.ns)
            if ($xmlNodes.Count -gt 0) { $xmlNode = $xmlNodes[0] } 
            elseif ($force) {
                $xmlNode = $this.doc.CreateNode('element', $name, $Script:msbuild_ns_uri)
                $null = $parent.AppendChild($xmlNode) 
            }
            return $xmlNode
        }
    }
    $util = [XmlUtil]::new($msbcDoc, $nsmgr)
    $idg = $util.child($root, 'ItemDefinitionGroup', $enable)
    if ($enable) {
        $aldNode = $util.child($util.child($idg, 'Link', $true), 'AdditionalLibraryDirectories', $true)
        $aldNode.InnerText = $libs
    }
    elseif ($idg) {
        $children = $idg.get_ChildNodes()
        foreach ($child in $children) {
            $null = $idg.RemoveChild($child)
        }
        $idg.IsEmpty = $true
    }

    $strXml = Format-Xml -Xml $msbcDoc -Indent 1 -Character "`t"
    Set-Content -Path $conf_file -Value $strXml
    # end mod
}

function check_msvcr14x_status($arch, $print = $false) {
    $conf_file = $conf_file_dict[$arch]
    if (Test-Path $conf_file -PathType Leaf) {
        $conf_content = [System.IO.File]::ReadAllText($conf_file)
    }
    else {
        $conf_content = ''
    }
    if (!$print) { return $conf_content.Contains('msvcr14x') }
    else {
        if ($conf_content.Contains('msvcr14x')) {
            println "$arch installed"
        }
        else {
            println "$arch not installed"
        }
    }
}

function msbuild_enable_msvcr14x ($enable) {
    if ((check_msvcr14x_status 'x86') -ne $enable) {
        mod_msbuild_conf 'x86' $enable
    } 

    if ((check_msvcr14x_status 'x64') -ne $enable) {
        mod_msbuild_conf 'x64' $enable
    }
}


function download_file($url, $out) {
    if ($1k.isfile($out)) { return }
    $1k.println("Downloading $url to $out ...")
    Invoke-WebRequest -Uri $url -OutFile $out
}

function download_and_expand($url, $out, $dest) {
    download_file $url $out
    if ($out.EndsWith('.zip')) {
        try {
            Expand-Archive -Path $out -DestinationPath $dest
        }
        catch {
            Remove-Item $out -Force
            throw "1kiss: Expand archive $out fail, please try again"
        }
    }
    elseif ($out.EndsWith('.tar.gz')) {
        if (!$dest.EndsWith('/')) {
            $1k.mkdirs($dest)
        }
        tar xf "$out" -C $dest
    }
    elseif ($out.EndsWith('.7z')) {
        7z x "$out" "-o$dest" -y | Out-Host
    }
    elseif ($out.EndsWith('.sh')) {
        chmod 'u+x' "$out"
        $1k.mkdirs($dest)
    }
}

function setup7z() {
    $7z_cmd_info = Get-Command '7z' -ErrorAction SilentlyContinue
    if (!$7z_cmd_info) {
        $7z_prog = Join-Path $external_prefix '7z2301-x64/7z.exe'
        $7z_pkg_out = Join-Path $external_prefix '7z2301-x64.zip'
        if (!(Test-Path $7z_prog -PathType Leaf)) {
            # https://www.7-zip.org/download.html
            $7z_url = 'https://gitee.com/simdsoft/1kiss/releases/download/devtools/7z2301-x64.zip'
            Invoke-WebRequest -Uri $7z_url -OutFile $7z_pkg_out
            try {
                Expand-Archive -Path $7z_pkg_out -DestinationPath $external_prefix
            }
            catch {
                Remove-Item $7z_pkg_out -Force
                throw "msvcr14x: Expand archive $out fail, please try again"
            }
        }

        $7z_bin = Split-Path  $7z_prog -Parent
        if (!$env:PATH.Contains($7z_bin)) {
            $env:PATH = "$7z_bin;$env:PATH"
        }

        $7z_cmd_info = Get-Command '7z' -ErrorAction SilentlyContinue
        if (!$7z_cmd_info) {
            throw "setup 7z fail"
        }
    }
}

$Global:vs_inst = $null
$task_schema = @{}

# builtin
$task_schema.prerequisite = @{
    action = {
       #boost 1.86.0 removed 
       #  “D:\dev\x-studio\deps\msvcr14x\msvcr14x.sln”(Build 目标) (1) ->
       # “D:\dev\x-studio\deps\msvcr14x\msvcp14x_2\msvcp14x_2.vcxproj.metaproj”(默认目标) (8) ->
       # “D:\dev\x-studio\deps\msvcr14x\msvcp14x_2\msvcp14x_2.vcxproj”(默认目标) (20) ->
       # (ClCompile 目标) ->
       #  C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433\crt\src\stl\special_math.cpp
       #(26,10): error C1083: 无法打开包括文件: “boost/math/special_functions/bessel.hpp”: No such file or directory [D:\dev\x-s
       #tudio\deps\msvcr14x\msvcp14x_2\msvcp14x_2.vcxproj]
        $boost_ver = '1.85.0'
        $winsdk_ver = '10.0.26100.0'
        $vs_version = "17.0"

        #region find_vs
        $vs_where = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        
        $vs_insts = ConvertFrom-Json "$(&$vs_where -version $vs_version -requires Microsoft.Component.MSBuild -format 'json')"
        $vs_count = $vs_insts.Count
        if ($vs_insts -isnot [array]) { $vs_insts = @($vs_insts) }

        println "Installed visual studio instances:"
        for ($i = 0; $i -lt $vs_count; $i++) {
            println "    $($i + 1). $($vs_insts[$i].installationPath)"
        }

        if (-not $vs_count) { println "The Visual Studio 2022 not installed."; return }
        if ($vs_count -eq 1) {
            $sel_idx = 0
        }
        else {
            println "Which Visual Studio 2022 Edition do you want to use, default is 1:"
            $sel_idx = Read-Host
            if (-not $sel_idx) { $sel_idx = 0 }
        }

        if ($sel_idx -ge $vs_count) { println "Invalid input ID."; return }

        $Global:vs_inst = $vs_insts[$sel_idx]
        $vs_edition = [System.IO.Path]::GetFileNameWithoutExtension($vs_inst.installationPath)

        #endregion find_vs

        if (!([System.Management.Automation.PSTypeName]'System.Windows.MessageBox').Type) {
            Add-Type -AssemblyName PresentationFramework
        }

        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            [System.Windows.MessageBox]::Show("Please install git for windows first!", "msvcr14x", "OK", "Error")
            Start-Process "https://git-scm.com/download/win"
            exit 1
        }
    
        if (-not $vs_edition) { $vs_edition = "Enterprise" }
        
        while (-not (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2022\$vs_edition")) {
            $result = [System.Windows.MessageBox]::Show("Please install Visual Studio 2022 $vs_edition edition first!", "msvcr14x", "YesNo", "Error")
            if ($result -eq "No") { exit 1 }
            Start-Process "https://visualstudio.microsoft.com/zh-hans/thank-you-downloading-visual-studio/?sku=$vs_edition&rel=17"
        }
    
        while (-not (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2022\$vs_edition\VC\Tools\MSVC")) {
            $result = [System.Windows.MessageBox]::Show("Please check 'Desktop development with C++' in Visual Studio 2022 Installer first!", "msvcr14x", "YesNo", "Error")
            if ($result -eq "No") { exit 1 }
            Start-Process "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
        }
    
        while (-not (Test-Path -Path "C:\Program Files (x86)\Windows Kits\10\Source\$winsdk_ver\ucrt")) {
            $result = [System.Windows.MessageBox]::Show("Please install Windows 11 SDK ($winsdk_ver) first!", "msvcr14x", "YesNo", "Error")
            if ($result -eq "No") { exit 1 }
            Start-Process "https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/"
        }
    
        # auto setup boost
        $boost_ROOT = [Environment]::GetEnvironmentVariable("boost_ROOT", "User")
        if (!$boost_ROOT -or !(Test-Path $boost_ROOT -PathType Container)) {
            $folder_name = "boost_$($boost_ver.Replace('.', '_'))"
            $boost_ROOT = Join-Path $external_prefix "$folder_name"
            
            if (!(Test-Path $boost_ROOT -PathType Container)) {
                $boost_url = "https://boostorg.jfrog.io/artifactory/main/release/$boost_ver/source/$folder_name.7z"
                $boost_pkg_out = Join-Path $external_prefix "$folder_name.7z"
                if (!(Test-Path $boost_pkg_out -PathType Leaf)) {
                    curl.exe -L $boost_url -o $boost_pkg_out
                }
                
                if (!(Test-Path $boost_ROOT -PathType Container)) {
                    setup7z
                    7z x $boost_pkg_out "-o$external_prefix" -bsp1 -y | Out-Host
                }
            }

            [Environment]::SetEnvironmentVariable("boost_ROOT", $boost_ROOT, "User")
        }
    }
}
$task_schema.build = @{
    action = {
        Push-Location $PSScriptRoot
        try {
            if (-not $env:boost_ROOT) {
                $env:boost_ROOT = (Get-ItemProperty -Path "HKCU:\Environment" -Name "boost_ROOT").boost_ROOT
            }

            git pull -v --progress "origin"

            while (-not (Test-Path -Path "../ntdll")) {
                git clone "https://github.com/sonyps5201314/ntdll.git" "../ntdll"
            }
            git -C "../ntdll" pull -v --progress "origin"

            while (-not (Test-Path -Path "../YY-Thunks")) {
                git clone "https://github.com/sonyps5201314/YY-Thunks.git" "../YY-Thunks"
            }
            git -C "../YY-Thunks" pull -v --progress "origin"

            # (New-Object -ComObject "WScript.Shell").Run("../ntdll/setup.vbs")
            $ntdll_setup = Join-Path $PSScriptRoot '../ntdll/setup.vbs'
            &$ntdll_setup

            if (!(Get-Command cl -ea SilentlyContinue)) {
                $vs_path = $vs_inst.installationPath
                Import-Module "$vs_path\Common7\Tools\Microsoft.VisualStudio.DevShell.dll" -ea SilentlyContinue
                Enter-VsDevShell -VsInstanceId $vs_inst.instanceId -SkipAutomaticLocation -DevCmdArguments "-arch=x86 -host_arch=x64 -no_logo"
            }

            msbuild "../YY-Thunks\src\YY-Thunks.UnitTest\YY-Thunks.UnitTest.vcxproj" -t:Build_YY_Thunks_List_hpp

            $configuration = @("Debug", "AnsiDebug", "Release", "AnsiRelease")
            $platform = @("x86", "x64")
            foreach ($conf in $configuration) {
                foreach ($plat in $platform) {
                    msbuild /m "msvcr14x.sln" /t:Build /p:Configuration=$conf`;Platform=$plat
                }
            }

            $build_success = $true
        }
        catch {
            Write-Error $_
            $build_success = $false
        }

        Pop-Location

        if (!$build_success) { exit 2 }
    }
}

$task_schema.install = @{
    action = {
        println "Installing msvc14x ..."
        try {
            # emit install instructions
            $instructions = ''
            foreach ($path in $install_files) {
                $install_loc = $install_locs[$path.StartsWith('x64')]
                if ($install_loc) {
                    $full_path = Join-Path $PSScriptRoot $path
                    if (Test-Path $full_path -PathType Leaf) {
                        $instructions += "Copy-Item -Path '$full_path' -Destination $install_loc -Force;`n"
                    }
                }
                else {
                    println "skipped install $path for current os arch: $os_arch"
                }
            }

            if ($instructions) {
                $msvcr14x_root = [Environment]::GetEnvironmentVariable('msvcr14x_ROOT', 'Machine')
                if (!$msvcr14x_root -or $msvcr14x_root -ne $PSScriptRoot) {
                    $instructions += "[Environment]::SetEnvironmentVariable('msvcr14x_ROOT', '$PSScriptRoot', 'Machine');`n"
                }
  
                println $instructions
                Start-Process powershell -ArgumentList '-Command', $instructions -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -Verb runas
                msbuild_enable_msvcr14x $true
                println 'Install msvc14x succeed.'
            }
            else {
                println 'Nothing to do for install, please build first'
            }
        }
        catch {
            println "Install msvcr14x fail: $_"
        }
    }
}

$task_schema.uninstall = @{
    action = {
        Write-Host "msvcr14x: Do you really want uninstall msvcr14x?(y/n): " -NoNewline
        $anwser = Read-Host
        try {
            if ($anwser -like "y*") {
                if ([Environment]::GetEnvironmentVariable('msvcr14x_ROOT', 'Machine')) {
                    $instructions = "[Environment]::SetEnvironmentVariable('msvcr14x_ROOT', `$null, 'Machine');`n"
                }
                else {
                    $instructions = ''
                }
                foreach ($path in $install_files) {
                    $install_loc = $install_locs[$path.StartsWith('x64')]
                    if (!$install_loc) { 
                        continue 
                    }
                    $file_name = Split-Path $path -Leaf
                    $full_path = Join-Path $install_loc $file_name
                    if (Test-Path $full_path -PathType Leaf) {
                        $instructions += "Remove-Item $full_path -Force;`n"
                    }
                }
                if ($instructions) {
                    # dump $instruction
                    println $instructions
                    Start-Process powershell -ArgumentList '-Command', $instructions -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -Verb runas
                    msbuild_enable_msvcr14x $false
                    println 'Uninstall succeed, please rebuild all of your projects which built by msvcr14x!'
                }
                else {
                    println 'Nothing to do for uninstall due to msvcr14x not install yet'
                }
            }
            else { throw 'cancelled' }
        }
        catch {
            println "Uninstall cancelled by user"
        }
    }
}

$task_schema.status = @{
    action = {
        check_msvcr14x_status 'x86' $true
        check_msvcr14x_status 'x64' $true
    }
}

# execute tasks one by one
foreach ($task in "prerequisite,$tasks".Split(',')) {
    if ($task_schema.Contains($task) -and !$task_schema.$task.executed) {
        &$task_schema.$task.action
        $task_schema.$task.executed = $true
    }
    else {
        println "The task:$task not defined!"
    }
}

cmd /c 'pause'
