class Capabilities
{
    static Simple := {"cap":{"capabilities":{"":""}}}, olduser := {}
    static _ucof := false, _hmode := false, _incog := false, _Uprompt := "dismiss", _Bidi := false
    __new(browser,Options,platform:="windows",notify:=false)
    {
        this.options := Options
        this.cap := {}
        this.cap.capabilities := {}
        this.cap.capabilities.alwaysMatch := { this.options :{"w3c":json.true}}
        this.cap.capabilities.alwaysMatch.webSocketUrl := json.false
        this.cap.capabilities.alwaysMatch.browserName := browser
        this.cap.capabilities.alwaysMatch.platformName := platform
        this.cap.capabilities.alwaysMatch.unhandledPromptBehavior := capabilities._Uprompt
        if(notify = false)
            this.AddexcludeSwitches("enable-automation")
        this.cap.capabilities.firstMatch := [{}]
        this.cap.desiredCapabilities := {}
        this.cap.desiredCapabilities.browserName := browser
    }

    BiDi[]
    {
        Set
        {
            if value
            {
                capabilities._Bidi := true
                this.cap.capabilities.alwaysMatch.webSocketUrl := json.true
            }      
            else
            {
                capabilities._Bidi := false
                this.cap.capabilities.alwaysMatch.webSocketUrl := json.false    
            }   
        }

        Get
        {
            return capabilities._Bidi
        }
    }

    UserPrompt[]
    {
        set
        {
            switch Value
            {
                Case "dismiss": capabilities._Uprompt := "dismiss"
                Case "accept": capabilities._Uprompt := "accept"
                Case "dismiss and notify": capabilities._Uprompt := "dismiss and notify"
                Case "accept and notify": capabilities._Uprompt := "accept and notify"
                Case "ignore": capabilities._Uprompt := "ignore"
                Default: unset := 1
            }
            if unset
            {
                Prompt := "Warning: wrong UserPrompt has been passed.`n"
                . "Use following case-sensitive parameters:`n"
                . chr(34) "dismiss" chr(34) "`n"
                . chr(34) "accept" chr(34) "`n"
                . chr(34) "dismiss, and, notify" chr(34) "`n"
                . chr(34) "accept, and, notify" chr(34) "`n"
                . chr(34) "ignore" chr(34) "`n"
                . "`n`nPress OK to continue"
                msgbox,48,Rufaydium Capabilities Error, % Prompt
                return
            }
            this.cap.capabilities.alwaysMatch.unhandledPromptBehavior := capabilities._Uprompt
        }

        Get
        {
            return capabilities._Uprompt
        }
    }

    HeadlessMode[]
    {
        set 
        {
            if value
            {
                this.addArg("--headless")
                capabilities._hmode := true
            }
            else
            {
                capabilities._hmode := false
                this.RemoveArg("--headless")
	        }	
        }

        get
        {
            return capabilities._hmode
        }
    }
    
    IncognitoMode[]
    {
        set 
        {
            if value
            {
                Capabilities.olduser.push(this.RemoveArg("--user-data-dir=","in"))
                Capabilities.olduser.push(this.RemoveArg("--profile-directory=","in"))
                this.addArg("--incognito")
                capabilities._incog := true
            }
            else
            {
                capabilities._incog := false
                for i, arg in this.cap.capabilities.alwaysMatch[this.Options].args
                    if (arg = "--incognito")
                        this.RemoveArg(arg)
                for i, arg in Capabilities.olduser
                    this.addArg(arg)
                Capabilities.olduser := {}
	        }	
        }

        get
        {
            return capabilities._incog
        }
    }

    Setbinary(location)
    {
        this.cap.capabilities.alwaysMatch[this.Options].binary := StrReplace(location, "\", "/")
    }

    Resetbinary()
    {
        this.cap.capabilities.alwaysMatch[this.Options].Delete("binary")
    }

    /*
    Following methods can manually be added as I haven't used them and do not know their parameters and also I don't see the need to add

    ChromeOption Methods    
    detach
    localState              
    prefs
    minidumpPath
    mobileEmulation
    perfLoggingPrefs
    windowTypes
    */

}

class ChromeCapabilities extends Capabilities
{
    setUserProfile(profileName:="Profile 1", userDataDir:="") ; Default is sample profile used everytime to create new profile 
	{
        if this.IncognitoMode
            return
		if !userDataDir
			userDataDir := StrReplace(A_AppData, "\Roaming") "\Local\Google\Chrome\User Data"
        userDataDir := StrReplace(userDataDir, "\", "/")
        ; removing previous args if any
        this.RemoveArg("--user-data-dir=","in")
        this.RemoveArg("--profile-directory=","in")
        ; adding new profile args
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
        
        if !fileExist( userDataDir "\" profileName )
        {
            Prompt := "Warning: Following Profile is Directory does not exist`n"
            . chr(34) userDataDir "\" profileName  chr(34) "`n"
            . "`n`nRufaydium is going to create profile directory Manually exitapp"
            . "`nPress OK to continue / Manually exitapp"
            msgbox,48,Rufaydium Capabilities, % Prompt
            fileCreateDir, % userDataDir "\" profileName
        }	
	}

    useCrossOriginFrame[]
    {
        set {
            if value
            {
                this.addArg("--disable-site-isolation-trials")
		        this.addArg("--disable-web-security")
                capabilities._ucof := true
            }
            else
            {
                capabilities._ucof := false
                for i, arg in this.cap.capabilities.alwaysMatch[this.Options].args
                    if (arg = "--disable-site-isolation-trials") or (arg = "--disable-web-security")
                        this.RemoveArg(arg)
	        }	
        }

        get
        {
            return capabilities._ucof
        }
    }

    addArg(arg) ; args links https://peter.sh/experiments/chromium-command-line-switches/
    {
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].args)
            this.cap.capabilities.alwaysMatch[this.Options].args := []
        this.cap.capabilities.alwaysMatch[this.Options].args.push(arg)
    }

    Addextensions(crxlocation)
    {
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
            this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        crxlocation := StrReplace(crxlocation, "\", "/")
        this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }

    RemoveArg(arg,match="Exact")
    {
	    for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
	    {
            if match = "Exact"
	        {
                if (argtbr = arg)
		            return this.cap.capabilities.alwaysMatch[this.Options].args.RemoveAt(i)
            } 
            else
            {
                if instr(argtbr, arg)
		            return this.cap.capabilities.alwaysMatch[this.Options].args.RemoveAt(i)
            }
	    }
    }

    DebugPort(Port:=9222)
    {
        this.cap.capabilities.alwaysMatch[this.Options].debuggerAddress := "http://127.0.0.1:" Port
    }

    AddexcludeSwitches(switch)
    {
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].excludeSwitches)
            this.cap.capabilities.alwaysMatch[this.Options].excludeSwitches := []
        this.cap.capabilities.alwaysMatch[this.Options].excludeSwitches.push(switch)
    }
}

class FireFoxCapabilities extends Capabilities
{
    __new(browser,Options,platform:="windows",notify:=false)
    {
        this.options := Options
        this.cap := {}
        this.cap.capabilities := {}
        this.cap.capabilities.alwaysMatch := { this.options :{"prefs":{"dom.ipc.processCount": 8,"javascript.options.showInConsole": json.false()}},"webSocketUrl": json.true}
        this.cap.capabilities.alwaysMatch.browserName := browser
        this.cap.capabilities.alwaysMatch.platformName := platform
        this.cap.capabilities.log := {}
        this.cap.capabilities.log.level := "trace"
        this.cap.capabilities.env := {}

        ; ; reg read binary location
        ; this.cap.capabilities.Setbinary("")
        ;this.cap.desiredCapabilities := {}
        ;this.cap.desiredCapabilities.browserName := browser
    }

    DebugPort(Port:=9222)
    {
        ;this.cap.capabilities.alwaysMatch[this.Options].debuggerAddress := "http://127.0.0.1:" Port
        msgbox, debuggerAddress is not support for FireFoxCapabilities
    }

    addArg(arg) ; idk args list
    {
        arg := StrReplace(arg,"--","-")
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].args)
            this.cap.capabilities.alwaysMatch[this.Options].args := []
        this.cap.capabilities.alwaysMatch[this.Options].args.push(arg)
    }

    RemoveArg(arg,match:="Exact")
    {
        arg := StrReplace(arg,"--","-")
	    for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
	    {
            if match = "Exact"
	        {
                if (argtbr = arg)
		            return this.cap.capabilities.alwaysMatch[this.Options].args.RemoveAt(i)
            } 
            else
            {
                if instr(argtbr, arg)
		            return this.cap.capabilities.alwaysMatch[this.Options].args.RemoveAt(i)
            }
	    }
    }

    setUserProfile(profileName:="Profile1",userDataDir:="") ; user data dir doesn't change often, use the default
	{
        if this.IncognitoMode
            return
        if !userDataDir
            userDataDir := A_AppData "\Mozilla\Firefox\"
        profileini := userDataDir "\Profiles.ini"
        if !fileExist( userDataDir "\Profiles\" profileName )
        {
            Prompt := "Warning: Following Profile is Directory does not exist`n"
            . chr(34) userDataDir "\" profileName  chr(34) "`n"
            . "`n`nRufaydium is going to create profile directory Manually exitapp"
            . "`nPress OK to continue / Manually exitapp"
            msgbox,48,Rufaydium Capabilities, % Prompt
            fileCreateDir, % userDataDir "\Profiles\" profileName
            IniWrite, % "Profiles/" profileName , % profileini, % profileName, Path
            IniWrite, % profileName , % profileini, % profileName, Name
            IniWrite, % 1, % profileini, % profileName, IsRelative
        }
        IniRead, profilePath , % profileini, % profileName, Path
        for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
        {
            if (argtbr = "-profile") or instr(argtbr,"\Mozilla\Firefox\Profiles\")
                this.cap.capabilities.alwaysMatch[this.Options].RemoveAt(i)
        }
        this.addArg("-profile")
        this.addArg(StrReplace(userDataDir "\Profiles\" profileName, "\", "/"))
	}

    Addextensions(crxlocation)
    {
        ; if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
        ;     this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        ; crxlocation := StrReplace(crxlocation, "\", "/")
        ; this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }
}

class EdgeCapabilities extends ChromeCapabilities
{
    setUserProfile(profileName:="Profile 1", userDataDir:="") ; default profile is Sample profile
	{
        if this.IncognitoMode
            return
		if !userDataDir
			userDataDir := StrReplace(A_AppData, "\Roaming") "\Local\Microsoft\Edge\User Data"
        userDataDir := StrReplace(userDataDir, "\", "\\")
        ; removing previous args if any
        this.RemoveArg("--user-data-dir=","in")
        this.RemoveArg("--profile-directory=","in")
        ; adding new profile args
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
        if !fileExist( userDataDir "\" profileName )
        {
            Prompt := "Warning: Following Profile is Directory does not exist`n"
            . chr(34) userDataDir "\" profileName  chr(34) "`n"
            . "`n`nRufaydium is going to create profile directory Manually exitapp"
            . "`nPress OK to continue / Manually exitapp"
            msgbox,48,Rufaydium Capabilities, % Prompt
            fileCreateDir, % userDataDir "\" profileName
        }
	}

    InPrivate[]
    {
        set
        {
            if value
                this.IncognitoMode := true
            else
                this.IncognitoMode := false
        }

        get
        {
            return this.IncognitoMode
        }
    }

    IncognitoMode[]
    {
        set 
        {
            if value
            {
                Capabilities.olduser.push(this.RemoveArg("--user-data-dir=","in"))
                Capabilities.olduser.push(this.RemoveArg("--profile-directory=","in"))
                this.addArg("--InPrivate")
                capabilities._incog := true
            }
            else
            {
                capabilities._incog := false
                for i, arg in this.cap.capabilities.alwaysMatch[this.Options].args
                    if (arg = "--InPrivate")
                        this.RemoveArg(arg)
                for i, arg in Capabilities.olduser
                    this.addArg(arg)
                Capabilities.olduser := {}
	        }	
        }

        get
        {
            return capabilities._incog
        }
    }


    Addextensions(crxlocation)
    {
        ; if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
        ;     this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        ; crxlocation := StrReplace(crxlocation, "\", "/")
        ; this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }
}

class BraveCapabilities extends ChromeCapabilities
{
    setUserProfile(profileName:="Default", userDataDir:="")
	{
        if this.IncognitoMode
            return
		if !userDataDir
			userDataDir := StrReplace(A_AppData, "\Roaming") "\Local\BraveSoftware\Brave-Browser\User Data\"
        userDataDir := StrReplace(userDataDir, "\", "/")
        ; removing previous args if any
        this.RemoveArg("--user-data-dir=","in")
        this.RemoveArg("--profile-directory=","in")
        ; adding new profile args
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
        if !fileExist( userDataDir "\" profileName )
        {
            Prompt := "Warning: Following Profile is Directory does not exist`n"
            . chr(34) userDataDir "\" profileName  chr(34) "`n"
            . "`n`nRufaydium is going to create profile directory Manually exitapp"
            . "`nPress OK to continue / Manually exitapp"
            msgbox,48,Rufaydium Capabilities, % Prompt
            fileCreateDir, % userDataDir "\" profileName
        }
	}
}


class OperaCapabilities extends ChromeCapabilities
{
        setUserProfile(profileName:="Opera stable", userDataDir:="") ; not sure is "Opera stable" is default profile
	{
        if this.IncognitoMode
            return
		if !userDataDir
			userDataDir := A_AppData "\opera software" ; not sure is (A_AppData "\opera software\Opera stable") is userDataDir
        userDataDir := StrReplace(userDataDir, "\", "/")
        ; removing previous args if any
        this.RemoveArg("--user-data-dir=","in")
        this.RemoveArg("--profile-directory=","in")
        ; adding new profile args
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
        if !fileExist( userDataDir "\" profileName )
        {
            Prompt := "Warning: Following Profile is Directory does not exist`n"
            . chr(34) userDataDir "\" profileName  chr(34) "`n"
            . "`n`nRufaydium is going to create profile directory Manually exitapp"
            . "`nPress OK to continue / Manually exitapp"
            msgbox,48,Rufaydium Capabilities, % Prompt
            fileCreateDir, % userDataDir "\" profileName
        }
	}

    Addextensions(crxlocation)
    {
        ; if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
        ;     this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        ; crxlocation := StrReplace(crxlocation, "\", "/")
        ; this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }
}