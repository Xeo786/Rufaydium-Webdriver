; WDM aka WebDriver management Class for Rufaydium.ahk 
; incl. Auto download supporting WebDriver when browser gets update
; By Xeo786

Class RunDriver
{
	__New(Location,Parameters:= "--port=0")
	{
		if !FileExist(Location)
			if !instr(Location,".exe")
				Location .= ".exe"
		SplitPath, Location,Name,Dir,,DriverName
		this.Dir := Dir ? Dir : A_ScriptDir
		this.exe := Name
		if RegExMatch(Parameters, "--port=(\d+)",P)
			this.param := p1 ? p : 0
		this.Name := DriverName
		switch this.Name
		{
			case "chromedriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "chrome"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9515")
			case "msedgedriver" : 
				this.Options := "ms:edgeOptions"
				this.browser := "msedge"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9516")
			case "geckodriver" : 
				this.Options := "moz:firefoxOptions"
				this.browser := "firefox"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9517")
			case "operadriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "opera"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9518")
			case "BraveDriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "Brave"
				this.exe := "chromedriver.exe"
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9515")	
			Default:
				if !this.param
					this.param := RegExReplace(Parameters, "(--port)=(\d+)", "$1=9519")
		}
		
		if !FileExist(Location) and this.browser
		{
			if A_Is64bitOS
				Location := this.GetDriver(,"64")
			else
				Location := this.GetDriver()
		}
			
		This.Target := Location " " chr(34) this.param chr(34)
		if !FileExist(Location)
		{
			MsgBox 0x40040, ,Rufaydium WebDriver Support,Unable to download driver`nRufaydium exiting
			ExitApp
		}

		if RegExMatch(this.param,"--port=(\d+)",port)
			This.Port := Port1
		else
		{
			MsgBox 0x40040, ,"Rufaydium WebDriver Support,Unable to download driver from`nURL :" this.DriverUrl "`nRufaydium exiting"
			ExitApp
		}
	

		PID := this.GetDriverbyPort(this.Port)
		if PID
		{
			this.PID := PID
		}
		else			
			this.Launch()
	}
	
	__Delete()
	{
		;this.exit()
	}
	
	exit()
	{
		Process, Close, % This.PID
	}
	
	Delete()
	{
		Process, Close, % This.PID
		FileDelete, % this.Dir "\" this.exe
	}

	Launch()
	{
		Run % this.Target,,Hide,PID
		Process, Wait, % PID
		this.PID := PID
	}
	
	help(Location)
	{
		Run % comspec " /k " chr(34) Location chr(34) " --help > dir.txt",,Hide,PID
		while !FileExist(this.Dir "\dir.txt")
			sleep, 200
		sleep, 200
		FileRead, Content, % this.Dir "dir.txt"
		while FileExist(this.Dir "\dir.txt")
			FileDelete, % this.Dir "\dir.txt"
		Process, Close, % PID
		return Content
	}
	
	visible
	{
		get
		{
			return this.visibility
		}
		
		set
		{
			if(value = 1) and !this.visibility
			{
				WinShow, % "ahk_pid " this.pid
				this.visibility := 1
			}
			else
			{
				WinHide, % "ahk_pid " this.pid
				this.visibility := 0
			}
		}
	}
	
	; thanks for AHK_user for driver auto-download suggestion and his code https://www.autohotkey.com/boards/viewtopic.php?f=6&t=102616&start=60#p460812
	GetDriver(Version="STABLE",bit="32")
	{
		switch this.Name
		{
			case "chromedriver" :
				this.zip := "chromedriver-win32.zip"
				RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+)",Dver)
				if RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+.\d+.\d+)",bver)
				{
					if Dver1 > 115 ; 
					{
						uri := "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
						for k, obj in json.load(this.GetVersion(uri)).versions
						{
							if instr(obj.version,bver2)
							{
								for i, download in obj.downloads.chromedriver
								{
									if download.platform = "win32"
									{
										this.DriverUrl := download.url
										break
									}
								}
								break
							}
						}
					}
					else
					{
						uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"  bver2
						DriverVersion := this.GetVersion(uri)
						this.DriverUrl := "https://chromedriver.storage.googleapis.com/" DriverVersion "/" this.zip
					}
				}
				else
				{
					uri := "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json"
					DriverVersion := json.load(this.GetVersion(uri)).channels.Stable.version
					this.DriverUrl := "https://storage.googleapis.com/chrome-for-testing-public/" DriverVersion "/win32/chromedriver-win32.zip"
					; this.DriverUrl := "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/" DriverVersion "/win32/chromedriver-win32.zip"
				}
			case "BraveDriver" :
				this.zip := "chromedriver_win32.zip"
				if RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+.\d+.\d+)",bver) ; iam clueless for response when loading another binary which does not matches chrome driver 
					uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"  bver2
				else
					uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE", bver1 := "unknown"
				DriverVersion := this.GetVersion(uri)
				this.DriverUrl := "https://chromedriver.storage.googleapis.com/" DriverVersion "/" this.zip
			case "msedgedriver" :
				if instr(bit,"64")
					this.zip := "edgedriver_win64.zip"
				else 
					this.zip := "edgedriver_win32.zip" 
				if RegExMatch(Version,"version ([\d.]+).*\n.*browser version is (\d+)",bver)
					uri := "https://msedgedriver.azureedge.net/LATEST_" "RELEASE_" bver2
				else if(Version != "STABLE")
					uri := "https://msedgedriver.azureedge.net/LATEST_RELEASE_" Version
				else
					uri := "https://msedgedriver.azureedge.net/LATEST_" Version, bver1 := "unknown"
				DriverVersion := this.GetVersion(uri) ; Thanks RaptorX fixing Issues GetEdgeDrive
				this.DriverUrl := "https://msedgedriver.azureedge.net/" DriverVersion "/" this.zip
			case "geckodriver" :
				; haven't received any error msg from previous driver tell about driver version 
				; therefor unable to figure out which driver to version to download as v0.028 support latest Firefox
				; this will be uri in case driver suggest version for firefox
				; uri := "https://api.github.com/repos/mozilla/geckodriver/releases/tags/v0.31.0"
				; till that just delete geckodriver.exe if you thing its old Rufaydium will download latest
				uri := "https://api.github.com/repos/mozilla/geckodriver/releases/latest"
				for i, asset in json.load(this.GetVersion(uri)).assets
				{
					if instr(asset.name,"win64.zip") and instr(bit,"64")
					{
						this.DriverUrl := asset.browser_download_url
						this.zip := asset.name
					}
					else if instr(asset.name,"win32.zip") 
					{
						this.DriverUrl := asset.browser_download_url
						this.zip := asset.name
					}
				}
			case "operadriver" :
				if RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+.\d+.\d+)",bver)
				{
					uri := "https://api.github.com/repos/operasoftware/operachromiumdriver/releases"
					for i, asset in json.load(this.GetVersion(uri)).assets
					{
						if instr(asset.name,bver1)
						{
							uri := "https://api.github.com/repos/operasoftware/operachromiumdriver/releases/tags/" asset.tag_name
						}
					}
				}	
				else
					uri := "https://api.github.com/repos/operasoftware/operachromiumdriver/releases/latest", bver1 := "unknown"
				
				for i, asset in json.load(this.GetVersion(uri)).assets
				{
					if instr(asset.name,"win64.zip") and instr(bit,"64")
					{
						this.DriverUrl := asset.browser_download_url
						this.zip := asset.name
					}
					else if instr(asset.name,"win32.zip") 
					{
						this.DriverUrl := asset.browser_download_url
						this.zip := asset.name
					}
				}
		} 

		if InStr(this.DriverVersion, "NoSuchKey"){
			MsgBox 0x40010,Testing,Error`nDriverVersion
			return false
		}
		
		if !FileExist(this.Dir "\Backup")
			FileCreateDir, % this.Dir "\Backup"
		
		while FileExist(this.Dir "\" this.exe)
		{
			Process, Close, % this.GetDriverbyPort(this.Port)
			FileMove, % this.Dir "\" this.exe, % this.Dir "\Backup\" this.name " Version " bver1 ".exe", 1
		}
		
		this.zip := this.dir "\" this.zip
		return this.DownloadnExtract()
	}
	
	GetVersion(uri)
	{
		if(this.Name = "msedgedriver")
		{
			WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			WebRequest.Open("GET", uri, false)
			WebRequest.SetRequestHeader("Content-Type","application/json")
			WebRequest.Send()
			bytes := WebRequest.Responsebody
			loop, % WebRequest.GetResponseHeader("Content-Length") ;loop over responsebody 1 byte at a time
					text .= chr(bytes[A_Index-1]) ;lookup each byte and assign a charter
			return SubStr(text, 3)
		}
		WebRequest := ComObjCreate("Msxml2.XMLHTTP")
		WebRequest.open("GET", uri, False)
		WebRequest.SetRequestHeader("Content-Type","application/json")
		WebRequest.Send()
		return WebRequest.responseText
	}

	DownloadnExtract()
	{
		;static fso := ComObjCreate("Scripting.FileSystemObject") idr why this is here
		URLDownloadToFile, % this.DriverUrl,  % this.zip
		AppObj := ComObjCreate("Shell.Application")
		FolderObj := AppObj.Namespace(this.zip)	
		FileObj := FolderObj.ParseName(this.exe)
		if !isobject(FileObj)
			For Item in FolderObj.Items
			{
				FileObj := FolderObj.ParseName(Item.Name "\" this.exe)
				if isobject(FileObj) 
					break
			}	
		AppObj.Namespace(this.Dir "\").CopyHere(FileObj, 4|16)
		FileDelete, % this.zip
			return this.Dir "\" this.exe
	}

	GetDriverbyPort(Port)
	{
		for process in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" this.exe "'")
		{
			RegExMatch(process.CommandLine, "(--port)=(\d+)",$)
			if (Port != $2)
			 	continue
			else
				return Process.processId
		}
	}

	GetPIDbyName(name) 
	{
		for Process in ComObjGet("winmgmts:\\.\root\cimv2").ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" name "'")
			return Process.processId
	}

	GetPortbyPID(PID)
	{
		for process in ComObjGet("winmgmts:\\.\root\cimv2").ExecQuery("Select * from Win32_Process where ProcessId=" PID)
		{
			RegExMatch(process.CommandLine, "(--port)=(\d+)",$)
			 return $2
		}
	}

	GetPath() 
	{
		if this.PID
			for process in ComObjGet("winmgmts:").ExecQuery("Select * FROM Win32_Process WHERE ProcessId=" This.PID)
			{
				return process.ExecutablePath
			}		
	}
}



