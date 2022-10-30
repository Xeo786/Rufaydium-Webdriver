; Rufaydium v1.7.0
;
; Rufaydium          : AutoHotkey WebDriver Library to interact with browsers.
; Requirement        : WebDriver version needs to be compatible with the Browser version.
;                      Rufaydium will automatically try to download the correct version.
; Supported browsers : Chrome, MS Edge, Firefox, Opera
;
; Rufaydium utilizes Rest API of W3C from https://www.w3.org/TR/webdriver2/
; and also supports Chrome Devtools Protocols same as chrome.ahk
;
; Note : no need to install / setup Selenium, Rufaydium is AHK's Selenium
; Link : https://www.autohotkey.com/boards/viewtopic.php?f=6&t=102616
; Git  : https://github.com/Xeo786/Rufaydium-Webdriver
; By Xeo786 - GPL-3.0 license, see LICENSE
#include %A_LineFile%\..\
#Include WDM.ahk
#Include CDP.ahk
#Include JSON.ahk
#include WDElements.ahk
#Include Capabilities.ahk
#include actions.ahk 

Class Rufaydium
{
	static WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	__new(DriverName:="chromedriver.exe",Parameters:="--port=9515")
	{
		this.Driver := new RunDriver(DriverName,Parameters)
		this.DriverUrl := "http://127.0.0.1:" This.Driver.Port
		Switch this.Driver.Name
		{
			case "chromedriver" :
				this.capabilities := new ChromeCapabilities(this.Driver.browser,this.Driver.Options)
			case "msedgedriver" :
				this.capabilities := new EdgeCapabilities(this.Driver.browser,this.Driver.Options)
			case "geckodriver" :
				this.capabilities := new FireFoxCapabilities(this.Driver.browser,this.Driver.Options)
			case "operadriver" :
				this.capabilities := new OperaCapabilities(this.Driver.browser,this.Driver.Options)
			case "BraveDriver" :
				this.capabilities := new BraveCapabilities(this.Driver.browser,this.Driver.Options)
				this.capabilities.Setbinary("C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe") 
				; drive might crash for 32 Brave on 64 bit OS there for we can load binary while new session, 
				; i.e. >> NewSession("32bit brave browser exe location")
		}
		if !isobject(cap := this.capabilities.cap)
			this.capabilities := capabilities.Simple
	}

	__Delete()
	{
		;this.QuitAllSessions()
		;this.Exit()
	}

	Exit()
	{
		this.Driver.Exit()
	}

	send(url,Method,Payload:= 0,WaitForResponse:=1)
	{
		if !instr(url,"HTTP")
			url := this.address "/" url
		if !Payload and (Method = "POST")
			Payload := Json.null
		try r := Json.load(this.Request(url,Method,Payload,WaitForResponse)).value ; Thanks to GeekDude for his awesome cJson.ahk
		if(r.error = "chrome not reachable") ; incase someone close browser manually but session is not closed for driver
			this.quit() ; so we close session for driver at cost of one time response wait lag
		if r
			return r
	}

	Request(url,Method,p:=0,w:=0)
	{
		Rufaydium.WebRequest.Open(Method, url, false)
		Rufaydium.WebRequest.SetRequestHeader("Content-Type","application/json")

		if p
		{
			p := StrReplace(json.dump(p),"[[]]","[{}]") ; why using StrReplace() >> https://www.autohotkey.com/boards/viewtopic.php?f=6&p=450824#p450824
			p := RegExReplace(p,"\\\\uE(\d+)","\uE$1")  ; fixing Keys turn '\\uE000' into '\uE000'
			Rufaydium.WebRequest.Send(p)
		}
		else
			Rufaydium.WebRequest.Send()
		if w
			Rufaydium.WebRequest.WaitForResponse()
		return Rufaydium.WebRequest.responseText
	}

	NewSession(Binary:="")
	{
		if !this.capabilities.options
		{
			Msgbox,64,Rufaydium WebDriver Support, % "Unknown Driver Loaded`n.Please read readme and manually set capabilities for " this.Driver.Name ".exe"
			return
		}
		if Binary
			this.capabilities.Setbinary(Binary)
		this.Driver.Options := this.capabilities.options ; in case someone uses a custom driver and want to change capabilities manually
		k := this.Send( this.DriverUrl "/session","POST",this.capabilities.cap,1)
		if k.error
		{
			if(k.message = "binary is not a Firefox executable")
			{
				; its all in my mind not tested, 32/64ahk 64OS 32/64ff broken down in simple three step logic
				ffbinary := A_ProgramFiles "\Mozilla Firefox\firefox.exe" ; check ff in default location, cover all 32AHKFFOS, 64AHKFFOS
				if !FileExist(ffbinary)
					ffbinary := RegExReplace(ffbinary, " (x86)") ; in case 64OS 32AHK 64FF checking 64ff loc
				else if !FileExist(ffbinary)
					ffbinary := A_ProgramFiles " (x86)\Mozilla Firefox\firefox.exe" ; in case 64OS has 64ahk checking 32ff loc
				else
				{
					msgbox,48,Rufaydium WebDriver Support,% k.message "`n`nDriver is unable to locate Firefox binary and, Rufaydium is also unable to detect Firefox default location.`n`nIf you see this message repeatedly please file a bug report."
					return
				}
				this.capabilities.Setbinary(ffbinary)
				return This.NewSession()
			}
			else if RegExMatch(k.message,"version ([\d.]+).*\n.*version is (\d+.\d+.\d+)")
			{
				MsgBox, 52,Rufaydium WebDriver Support,% k.message "`n`nPlease press Yes to download latest driver"
				IfMsgBox Yes
				{
					this.driver.exit()
					i := this.driver.GetDriver(k.message)
					if !FileExist(i)
					{
						Msgbox,64,Rufaydium WebDriver Support,Unable to download driver`nRufaydium exiting.
						ExitApp
					}
					This.Driver := new RunDriver(i,This.Driver.Param)
					return This.NewSession()
				}
			}
			else
			{
				msgbox, 48,Rufaydium WebDriver Support Error,% k.error "`n`n" k.message
				return k
			}
		}
		window := []
		window.Name := This.driver.Name
		window.debuggerAddress := StrReplace(k.capabilities[This.driver.options].debuggerAddress,"localhost","http://127.0.0.1")
		window.address := this.DriverUrl "/session/" k.SessionId
		if This.driver.Name = "geckodriver"
		{
			IniWrite, % k.SessionId, % this.driver.dir "/ActiveSessions.ini", % This.driver.Name, % k.SessionId
		}

		return new Session(window)
	}

	Sessions() ; get all Sessions Details
	{
		return this.send(this.DriverUrl "/sessions","GET")
	}

	getSessions() ; get all Sessions for Rufaydium
	{
		if !this.capabilities.options
		{
			Msgbox,64,Rufaydium WebDriver Support, % "Unknown Driver Loaded.`nPlease read readme and manually set capabilities for " this.Driver.Name ".exe"
			return
		}
		this.Driver.Options := this.capabilities.options

		if This.driver.Name = "geckodriver"
		{
			IniRead, SessionList, % this.driver.dir "/ActiveSessions.ini", % This.driver.Name
			Windows := []
			for k, se in StrSplit(SessionList,"`n")
			{
				se := RegExReplace(se, "(.*)=(.*)", "$1")
				r :=  this.Send(this.DriverUrl "/session/" se "/url","GET")
				if r.error
					IniDelete, % this.driver.dir "/ActiveSessions.ini", % This.driver.Name, % se
				else
				{
					s := []
					s.id := Se
					s.Name := This.driver.Name
					s.address := this.DriverUrl "/session/" s.id
					windows[k] := new Session(s)
				}
			}
			return windows
		}

		windows := []
		for k, se in this.Sessions()
		{
			chromeOptions := Se["capabilities",This.driver.options]
			s := []
			s.id := Se.id
			s.Name := This.driver.Name
			s.debuggerAddress := StrReplace(chromeOptions.debuggerAddress,"localhost","http://127.0.0.1")
			s.address := this.DriverUrl "/session/" s.id
			windows[k] := new Session(s)
		}
		return windows
	}

	getSession(i:=0,t:=0)
	{
		if i
		{
			S := this.getSessions()[i]
			if t
			{
				S.SwitchTab(t)
			}
			else
				S.ActiveTab()
			return S
		}
	}

	getSessionByUrl(URL)
	{
		for k, w in this.getSessions()
		{
			w.SwitchbyURL(URL)
			if instr(w.URL,URL)
				return w
		}
	}

	getSessionByTitle(Title)
	{
		for k, s in this.getSessions()
		{
			s.SwitchbyTitle(Title)
			if instr(s.title,Title)
				return s
		}
	}

	QuitAllSessions()
	{
		for k, s in this.getSessions()
			s.Quit()
	}

	Status()
	{
		return Rufaydium.Request( this.DriverUrl "/status","GET")
	}
}


Class Session
{

	__new(i)
	{
		this.id := i.id
		this.Address := i.address
		this.debuggerAddress := i.debuggerAddress
		this.currentTab := this.Send("window","GET")
		switch i.name
		{
			case "chromedriver" :
				this.CDP := new CDP(this.Address)
			case "msedgedriver" :
				this.CDP := new CDP(this.Address)
			case "geckodriver" :

			case "operadriver" :
				this.CDP := new CDP(this.Address)
		}
	}

	__Delete()
	{
		;this.Quit()
	}

	Quit()
	{
		this.Send(this.address ,"DELETE")
	}

	close()
	{
		Tabs := this.Send("window","DELETE")
		this.Switch(this.currentTab := tabs[tabs.Length()])
	}

	send(url,Method,Payload:= 0,WaitForResponse:=1)
	{
		if !instr(url,"HTTP")
			url := this.address "/" url
		if (Payload = 0) and (Method = "POST")
			Payload := Json.null
		try r := Json.load(Rufaydium.Request(url,Method,Payload,WaitForResponse)).value ; Thanks to GeekDude for his awesome cJson.ahk
		if(r.error = "chrome not reachable") ; incase someone close browser manually but session is not closed for driver
			this.quit() ; so we close session for driver at cost of one time response wait lag
		if r
			return r
	}

	NewTab(i:=1)
	{
		This.currentTab := this.Send("window/new","POST",{"type":"tab"}).handle
		if i
			This.Switch(This.currentTab)
	}

	NewWindow(i:=1) ; by https://github.com/hotcheesesoup
	{
		This.currentTab := this.Send("window/new","POST",{"type":"window"}).handle
		if i 
			This.Switch(This.currentTab)
	}

	Detail()
	{
		return Json.load(Rufaydium.Request(this.debuggerAddress "/json","GET"))
	}

	GetTabs()
	{
		return this.Send("window/handles","GET")
	}

	Switch(Tabid)
	{
		this.currentTab := Tabid
		this.Send("window","POST",{"handle":Tabid})
	}

	Title
	{
		get
		{
			return this.Send("title","GET")
		}
	}

	ActiveTab()
	{
		if !this.debuggerAddress ; does not work for Firefox
			return
		this.Switch("CDwindow-" this.Detail()[1].id ) ; First id always Current Handle
	}

	SwitchTab(i:=0)
	{
		return this.Switch(This.currentTab := this.GetTabs()[i])
	}

	SwitchbyTitle(Title:="")
	{
		; Rufaydium will soon use CDP Target's methods to re-access sessions and pages 
		; might able to access pages even after restarting webdriver
		; Targets := this.CDP.GetTargets() 
		handles := this.GetTabs()
		try pages := this.Detail() ; if Browser closed by user this will closed the session
		if !pages
			this.quit()
		if isobject(this.CDP) ;&& Targets
		{	
			for k , handle in handles
			{
				for i, t in pages ;Targets.targetInfos
				{
					if instr(Handle,t.id)
					{
						if instr(t.Title, Title)
						{
							This.currentTab := handle ; "CDwindow-" t.targetid
							this.Switch(This.currentTab )
							;this.CDP.Switch(t.targetid)
							return
						}
					}
				}
			}
		}	
		else
		{
			for k , handle in handles
			{
				this.switch(handle)
				if instr(this.title(),Title)
				{
					This.currentTab := handle
					break
				}
			}
			this.Switch(This.currentTab )
		}
	}

	SwitchbyURL(url:="",Silent:=1)
	{
		; Rufaydium will soon use CDP Target's methods to re-access sessions and pages 
		; might able to access pages even after restarting webdriver
		;Targets := this.CDP.GetTargets() 
		handles := this.GetTabs()
		try pages := this.Detail() ; if Browser closed by user this will closed the session
		if !pages
			this.quit()

		if isobject(this.CDP)
		{	
			for k , handle in handles
			{
				for i, t in pages ;Targets.targetInfos
				{
					if instr(Handle,t.id)
					{
						if instr(t.url, url)
						{
							This.currentTab := Handle ;"CDwindow-" t.targetid
							this.Switch(This.currentTab )
							;this.CDP.Switch(t.targetid)
							return
						}
					}
				}
			}
		}	
		else
		{
			for k , handle in handles
			{
				this.switch(handle)
				if instr(this.url,url)
				{
					This.currentTab := handle
					break
				}
			}
			this.Switch(This.currentTab )
		}
	}

	url
	{
		get
		{
			return this.Send("url","GET")
		}

		set
		{
			return this.Send("url","POST",{"url":RegExReplace(Value,"^(?!\w+[:\/])(.*)","https://$1",,1)})
		}
	}

	Refresh()
	{
		return this.Send("refresh","POST")
	}

	IsLoading
	{
		get
		{
			return this.Send("is_loading","GET")
		}
	}

	timeouts()
	{
		return this.Send("timeouts","GET")
	}

	Navigate(url)
	{
		this.url := url
	}

	Forward()
	{
		return this.Send("forward","POST") ; not tested
	}

	Back()
	{
		return this.Send("back","POST") ; not tested
	}

	GetRect()
	{
		return this.Send("window/rect","GET")
	}

	SetRect(x:=1,y:=1,w:=0,h:=0)
	{
		if !w
			w := A_ScreenWidth - 0
		if !h
			h := A_ScreenHeight - (A_ScreenHeight * 5 / 100)
		return this.Send("window/rect","POST",{"x":x,"y":y,"width":w,"height":h})
	}

	X
	{
		get
		{
			rect := this.GetRect()
			return rect.x
		}

		Set
		{
			msgbox, % value
			return this.Send("window/rect","POST",{"x":value})
		}
	}

	Y
	{
		get
		{
			rect := this.GetRect()
			return rect.y
		}

		Set
		{
			return this.Send("window/rect","POST",{"y":value})
		}
	}

	width
	{
		get
		{
			rect := this.GetRect()
			return rect.width
		}

		Set
		{
			return this.Send("window/rect","POST",{"width":value})
		}
	}

	height
	{
		get
		{
			rect := this.GetRect()
			return rect.height
		}

		Set
		{
			return this.Send("window/rect","POST",{"height":value})
		}
	}

	Maximize()
	{
		return this.Send("window/maximize","POST",json.null)
	}

	Minimize()
	{
		return this.Send("window/minimize","POST",json.null)
	}

	FullScreen()
	{
		return this.Send("window/fullscreen","POST",json.null)
	}

	FramesLength()
	{
		return this.ExecuteSync("return window.length")
	}

	Frame(i)
	{
		return this.Send("frame","POST",{"id":i})
	}

	ParentFrame()
	{
		return this.Send("frame/parent","POST",json.null)
	}

	HTML
	{
		get
		{
			return this.Send("source","GET",0,1)
		}
	}

	ActiveElement()
	{
		for i, elementid in this.Send("element/active","GET")
		{
			address := RegExReplace(this.address "/element/" elementid,"(\/shadow\/.*)\/element","/element")
			address := RegExReplace(address "/element/" elementid,"(\/element\/.*)\/element","/element")
			return New WDElement(address,i)
		}
	}

	findelement(u,v)
	{
		r := this.Send("element","POST",{"using":u,"value":v},1)
		for i, elementid in r
		{
			if instr(elementid,"no such")
				return 0
			address := RegExReplace(this.address "/element/" elementid,"(\/shadow\/.*)\/element","/element")
			address := RegExReplace(address "/element/" elementid,"(\/element\/.*)\/element","/element")
			return New WDElement(address,i)
		}
	}

	findelements(u,v)
	{
		e := []
		for k, element in this.Send("elements","POST",{"using":u,"value":v},1)
		{
			for i, elementid in element
			{
				address := RegExReplace(this.address "/element/" elementid,"(\/shadow\/.*)\/element","/element")
				address := RegExReplace(address "/element/" elementid,"(\/element\/.*)\/element","/element")
				e[k-1] := New WDElement(address,i)
			}
		}

		if e.count() > 0
			return e
		return 0
	}

	shadow()
	{
		for i,  elementid in this.Send("shadow","GET")
		{
			address := RegExReplace(this.address "/element/" elementid,"(\/element\/.*)\/element","/shadow")
			return new ShadowElement(address)
		}
	}

	getElementByID(id)
	{
		return this.findelement(by.selector,"#" id)
	}

	QuerySelector(Path)
	{
		return this.findelement(by.selector,Path)
	}

	QuerySelectorAll(Path)
	{
		return this.findelements(by.selector,Path)
	}

	getElementsbyClassName(Class)
	{
		return this.findelements(by.selector,"[class='" Class "']")
	}

	getElementsbyTagName(Name)
	{
		return this.findelements(by.TagName,Name)
	}

	getElementsbyName(Name)
	{
		return this.findelements(by.selector,"[Name='" Name "']")
	}

	getElementsbyXpath(xPath)
	{
		return this.findelements(by.xPath,xPath)
	}

	ExecuteSync(Script,Args*)
	{
		return this.Send("execute/sync","POST", { "script":Script,"args":[Args*]},1)
	}

	ExecuteAsync(Script,Args*)
	{
		return this.Send("execute/async","POST", { "script":Script,"args":Args*},1)
	}

	GetCookies()
	{
		return this.Send("cookie","GET")
	}

	GetCookieName(Name)
	{
		return this.Send("cookie/" Name,"GET")
	}

	AddCookie(CookieObj)
	{
		return this.Send("cookie","POST",CookieObj)
	}

	Alert(Action,Text:=0)
	{
		switch Action
		{
			case "accept": i := "/alert/accept", m := "POST"
			case "dismiss": i := "/alert/dismiss", m := "POST"
			case "GET": i := "/alert/text", m := "GET"
			case "Send": i := "/alert/text", m := "POST"
		}

		if Text
			return this.Send(this.address i,m,{"text":Text})
		else
			return this.Send(this.address i,m)
	}

	Screenshot(location:=0)
	{
		Base64Canvas :=  this.Send("screenshot","GET")
		if Base64Canvas
		{
			nBytes := Base64Dec( Base64Canvas, Bin ) ; thank you Skan :)
			File := FileOpen(location, "w")
			File.RawWrite(Bin, nBytes)
			File.Close()
		}
	}

	Print(PDFLocation,Options:=0)
	{
		if !instr(PDFLocation,".pdf")
		{
			msgbox, ,Rufaydium, error: File location be ".pdf"
			return
		}

		if this.Capabilities.HeadlessMode
		{
			Base64pdfData := this.Send("print","POST",Options) ; does not work
			if !Base64pdfData.error
			{
				nBytes := Base64Dec( Base64pdfData, Bin ) ; thank you Skan :)
				File := FileOpen(PDFLocation, "w")
				File.RawWrite(Bin, nBytes)
				File.Close()
			}
			else
				msgbox, ,Rufaydium, % "Fail to save PDF`nError : " json.Dump(Base64pdfData) "`nPlease define Print Options or use print profiles from PrintOptions.class`nSince Chrome Printing is not available in Headful mode you can try 'wkhtmltopdf' printing"
		}
		else
		{
			if isProgInstalled("wkhtmltox")
			{
				wkhtmltopdf(this.HtML,PDFLocation,options)
			}
			else
			{
				MsgBox,36,Rufaydium, User is required to install "wkhtmltopdf" In order to enable pdf printing without Headless mode`n`nPress Yes to navigate to download page of "wkhtmltox" tool
				IfMsgBox Yes
				{
					this.NewTab()
					this.url := "https://wkhtmltopdf.org/downloads.html"
					MsgBox,64,Rufaydium,Please Download and install "wkhtmltox" now, according to Windows Version then Restart Rufaydium.
				}
			}
		}
	}

	click(i:=0) ; [button: 0(left) | 1(middle) | 2(right)]
	{
		MouseEvent := new mouse()
		MouseEvent.Release(i)
		MouseEvent.Pause(100)
		MouseEvent.Release(i)
		return this.Actions(MouseEvent)
	}

	DoubleClick(i:=0) ; [button: 0(left) | 1(middle) | 2(right)]
	{
		MouseEvent := new mouse()
		; click 1
		MouseEvent.Release(i)
		MouseEvent.Pause(100)
		MouseEvent.Release(i)
		; delay
		MouseEvent.Pause(500)
		; click 2
		MouseEvent.Release(i)
		MouseEvent.Pause(100)
		MouseEvent.Release(i)
		return this.Actions(MouseEvent)
	}

	MBDown(i:=0) ; [button: 0(left) | 1(middle) | 2(right)]
	{
		MouseEvent := new mouse()
		MouseEvent.Press(i)
		return this.Actions(MouseEvent)
	}

	MBup(i:=0) ; [button: 0(left) | 1(middle) | 2(right)]
	{
		MouseEvent := new mouse()
		MouseEvent.Release(i)
		return this.Actions(MouseEvent)
	}

	Move(x,y)
	{
		MouseEvent := new mouse()
		MouseEvent.move(x,y,0)
		return this.Actions(MouseEvent)
	}

	ScrollUP(s:=50)
	{
		WheelEvent := new Scroll()
		WheelEvent.ScrollUP(s)
		r := this.Actions(WheelEvent)
		WheelEvent := ""
		return r
	}

	ScrollDown(s:=50)
	{
		WheelEvent := new Scroll()
		WheelEvent.ScrollDown(s)
		return this.Actions(WheelEvent)
	}

	ScrollLeft(s:=50)
	{
		WheelEvent := new Scroll()
		WheelEvent.ScrollLeft(s)
		return this.Actions(WheelEvent)
	}

	ScrollRight(s:=50)
	{
		WheelEvent := new Scroll()
		WheelEvent.ScrollRight(s)
		return this.Actions(WheelEvent)
	}

	SendKey(Chars)
	{
		KeyboardEvent := new Keyboard()
		KeyboardEvent.SendKey(Chars) ; right now it does not support Key.Class()
		return this.Actions(KeyboardEvent)
	}

	Actions(Interactions*)
	{
		if Interactions.count()
		{
			ActionArray := []
			for i, interaction in Interactions
			{
				ActionArray.push(interaction.perform())
				Interactions.clear()
				Interaction := ""
			}
			return this.Send("actions","POST",{"actions":ActionArray})
		}	
		else
			return this.Send("actions","DELETE")	
	}

	execute_sql()
	{
		return this.Send("execute_sql","POST",{"":""}) ; idk about sql
	}
}

Class by
{
	static selector := "css selector"
	static Linktext := "link text"
	static Plinktext := "partial link text"
	static TagName := "tag name"
	static XPath	:= "xpath"
}

Class PrintOptions ; https://www.w3.org/TR/webdriver2/#print
{
	static A4_Default =
	( LTrim Join
	{
 	"page":{
 		"width": 50,
 		"height": 60
	},
 	"margin":{
 		"top": 2,
 		"bottom": 2,
 		"left": 2,
 		"right": 2
	},
 	"scale": 1,
 	"orientation":"portrait",
	"shrinkToFit": json.true,
 	"background": json.true
	}
	)
}


; https://www.autohotkey.com/boards/viewtopic.php?t=35964
Base64Dec( ByRef B64, ByRef Bin ) {  ; By SKAN / 18-Aug-2017
	Local Rqd := 0, BLen := StrLen(B64)                 ; CRYPT_STRING_BASE64 := 0x1
	DllCall( "Crypt32.dll\CryptStringToBinary", "Str",B64, "UInt",BLen, "UInt",0x1
         , "UInt",0, "UIntP",Rqd, "Int",0, "Int",0 )
	VarSetCapacity( Bin, 128 ), VarSetCapacity( Bin, 0 ),  VarSetCapacity( Bin, Rqd, 0 )
	DllCall( "Crypt32.dll\CryptStringToBinary", "Str",B64, "UInt",BLen, "UInt",0x1
         , "Ptr",&Bin, "UIntP",Rqd, "Int",0, "Int",0 )
	Return Rqd
}

Base64Enc( ByRef Bin, nBytes, LineLength := 64, LeadingSpaces := 0 ) { ; By SKAN / 18-Aug-2017
	Local Rqd := 0, B64, B := "", N := 0 - LineLength + 1  ; CRYPT_STRING_BASE64 := 0x1
	DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin ,"UInt",nBytes, "UInt",0x1, "Ptr",0,   "UIntP",Rqd )
	VarSetCapacity( B64, Rqd * ( A_Isunicode ? 2 : 1 ), 0 )
	DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin, "UInt",nBytes, "UInt",0x1, "Str",B64, "UIntP",Rqd )
	If ( LineLength = 64 and ! LeadingSpaces )
		Return B64
	B64 := StrReplace( B64, "`r`n" )
	Loop % Ceil( StrLen(B64) / LineLength )
		B .= Format("{1:" LeadingSpaces "s}","" ) . SubStr( B64, N += LineLength, LineLength ) . "`n"
	Return RTrim( B,"`n" )
}

isProgInstalled(Prog)
{
	shell := ComObjCreate("Shell.Application")
	programsFolder := shell.NameSpace("::{26EE0668-A00A-44D7-9371-BEB064C98683}\8\::{7B81BE6A-CE2B-4676-A29E-EB907A5126C5}")
	items := programsFolder.Items()
	for k in items
		if instr(k.name,prog)
			return true
	return false
}


wkhtmltopdf(HtML,pdf,options)
{
	htmlloc := StrReplace(pdf, ".pdf",".html")
	
	while FileExist(pdf)
		FileDelete, % pdf

	while FileExist(htmlloc)
		FileDelete, % htmlloc

	FileAppend, % HtML, % htmlloc

	while !FileExist(htmlloc)
		sleep, 200

	RegRead, wkhtmltopdf, HKLM, Software\wkhtmltopdf, PdfPath

	if IsObject(options)
	{
		cmd := wkhtmltopdf " --zoom " options.scale

		cmd .= " --margin-bottom "	options.margin.bottom
		cmd .= " --margin-left "	options.margin.left
		cmd .= " --margin-right "	options.margin.right
		cmd .= " --margin-top "		options.margin.top

		cmd .= " --page-height "	options.page.height
		cmd .= " --page-width " 	options.page.height

		cmd .= " --orientation " chr(34) options.orientation chr(34)

		if options.background
			cmd .= " --enable-smart-shrinking "
		else
			cmd .= " --disable-smart-shrinking "

		if options.background
			cmd .= " --background "
		else
			cmd .= " --no-background "	
		
		cmd .= " " chr(34) htmlloc chr(34) " " chr(34) pdf chr(34)
		runwait, %  cmd,,Hide
	}	
	else if IsObject(options)
		runwait, % wkhtmltopdf " " options " " chr(34) htmlloc chr(34) " " chr(34) pdf chr(34),,Hide
	else
		runwait, % wkhtmltopdf " --background " chr(34) htmlloc chr(34) " " chr(34) pdf chr(34),,Hide
	FileDelete, % htmlloc
}