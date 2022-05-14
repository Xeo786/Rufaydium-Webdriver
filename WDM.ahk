; WDM aka Web Driver management Class for Rufaydium.ahk 
; I am upto/will add support update auto download supporting Webdriver when browser gets update
; By Xeo786

Class RunDriver
{
	__New(Location,Parameters:= "--port=9515")
	{
		SplitPath, Location,Name,Dir,,DriverName
		this.Dir := Dir
		switch DriverName
		{
			case "chromedriver" :
			if !FileExist(Location)
				DriverName := this.GetChromeDriver() 
			this.Options := "goog:chromeOptions"
			
			case "msedgedriver" : 
			if !FileExist(Location)
				DriverName := this.GetEdgeDrive() 
			this.Options := "ms:edgeOptions"
		}
		
		if !FileExist(Location)
		{
			Msgbox,64,Rufaydium WebDriver Support,Unable to download driver`nRufaydium exitting
			Exitapp
		}
		this.param := Parameters
		This.Target := Location " " chr(34) Parameters chr(34)
		this.Name := DriverName
		if RegExMatch(this.param,"--port=(\d+)",port)
			This.Port := Port1
		else
		{
			Msgbox,64,Rufaydium WebDriver Support,Unable to download driver`nRufaydium exitting
			exitapp
		}
		
		PID := GetPIDbyName(Name)
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
	
	Launch()
	{
		Run % this.Target,,Hide,PID
		Process, Wait, % PID
		this.PID := PID
	}
	
	help(Location)
	{
		Run % comspec " /k " chr(34) Location chr(34) " --help > dir.txt",,Hide,PID
		while !FileExist(A_ScriptDir "\dir.txt")
			sleep, 200
		sleep, 200
		FileRead, Content, dir.txt
		while FileExist(A_ScriptDir "\dir.txt")
			FileDelete, % A_ScriptDir "\dir.txt"
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
				winshow, % "ahk_pid " this.pid
				this.visibility := 1
			}
			else
			{
				winhide, % "ahk_pid " this.pid
				this.visibility := 0
			}
		}
	}
	
	; supports for edge and other driver will soon be added 
	; thanks for AHK_user for driver auto-download suggestion and his code https://www.autohotkey.com/boards/viewtopic.php?f=6&t=102616&start=60#p460812
	GetChromeDriver(Version="")
	{
		exe := "chromedriver.exe"
		zip := "chromedriver_win32.zip"
		if RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+.\d+.\d+)",bver)
			Version := "_" bver2
		else
			bver1 := "unkown"
		uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE"  Version
		DriverVersion := Request(uri,"GET")
		if InStr(DriverVersion, "NoSuchKey"){
			MsgBox,16,Testing,Error`nDriverVersion
			return false
		}
		
		if !FileExist(this.Dir "\Backup")
			FileCreateDir, % this.Dir "\Backup"
		
		while FileExist(this.Dir "\" exe)
		{
			Process, Close, % GetPIDbyName(exe)
			FileMove, % this.Dir "\" exe, % this.Dir "\Backup\Chromedriver Version " bver1 ".exe", 1
		}
		
		DriverUrl := "https://chromedriver.storage.googleapis.com/" DriverVersion "/" zip
		return DownloadnExtract(DriverUrl,this.dir "\" zip,exe)
	}
	
	; Thanks RaptorX fixing Issues GetEdgeDrive
	GetEdgeDrive(Version="STABLE",bit="32")
	{
		exe := "msedgedriver.exe"
		if RegExMatch(Version,"version ([\d.]+).*\n.*browser version is (\d+)",bver)
			Version := "RELEASE_" bver2
		else if(Version != "STABLE")
		 	Version := "RELEASE_" Version
		else
			bver1 := "unkown"
		uri := "https://msedgedriver.azureedge.net/LATEST_" Version
		DriverVersion := Request(uri,"GET")
		
		if InStr(DriverVersion, "BlobNotFound") or InStr(DriverVersion, "error")
		{
			MsgBox,16,Testing,Error`nDriverVersion
			return false
		}
		
		if instr(bit,"64")
			zip := "edgedriver_win64.zip"
		else 
			zip := "edgedriver_win32.zip"
		
		if !FileExist(this.Dir "\Backup")
			FileCreateDir, % this.Dir "\Backup"
		
		while FileExist(this.Dir "\" exe)
		{
			Process, Close, % GetPIDbyName(exe)
			FileMove, % this.Dir "\" exe, % this.Dir "\Backup\Chromedriver Version " bver1 ".exe", 1
		}
		DriverUrl := "https://msedgedriver.azureedge.net/" DriverVersion "/" zip
		return DownloadnExtract(DriverUrl,this.dir "\" zip,exe)
	}
}

DownloadnExtract(url,zip,exe)
{
	URLDownloadToFile, % url ,  % zip
	SplitPath, zip,,Dir
	fso := ComObjCreate("Scripting.FileSystemObject")
	AppObj := ComObjCreate("Shell.Application")
	FolderObj := AppObj.Namespace(zip)	
	FileObj := FolderObj.ParseName(exe)
	AppObj.Namespace(Dir "\").CopyHere(FileObj, 4|16)
	FileDelete, % zip
	return Dir "\" exe
}

/*
 Rufaydium totally depends on Rest API (HTTP) calls and 
 I would have created so many Winhttp com objects
 therefore I came up with this trick
 Single function per single process
 */
Request(url,Method,Payload := 0,WaitForResponse := 0) {
	static WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	WebRequest.Open(Method, url, false)
	WebRequest.SetRequestHeader("Content-Type","application/json")
	
	if Payload
		WebRequest.Send(Payloadfix(Payload))
	else
		WebRequest.Send()
	if WaitForResponse
		WebRequest.WaitForResponse()
	
	if url ~= "msedge"
		return SubStr(ConvertResponseBody(WebRequest), 3)
	else
		return WebRequest.responseText
}

ConvertResponseBody(oHTTP){
	bytes:=oHTTP.Responsebody ;Responsebody has an array of bytes.  Single characters.
	loop, % oHTTP.GetResponseHeader("Content-Length") ;loop over  responsbody 1 byte at a time
		text .= chr(bytes[A_Index-1]) ;lookup each byte and assign a charter
	return text
}

Payloadfix(p)
{
	p := StrReplace(json.dump(p),"[[]]","[{}]") ; why using StrReplace() >> https://www.autohotkey.com/boards/viewtopic.php?f=6&p=450824#p450824
	p := RegExReplace(p,"\\\\uE(\d+)","\uE$1")  ; fixing Keys turn '\\uE000' into '\uE000'
	return p
}

GetPIDbyName(name) {
	static wmi := ComObjGet("winmgmts:\\.\root\cimv2")
	for Process in wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" name "'")
		return Process.processId
}