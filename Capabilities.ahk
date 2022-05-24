
class Capabilities
{
    static Simple := {"cap":{"capabilities":{"":""}}}
    static _ucof := false
    static _hmode := false
    __new(browser,Options,platform:="windows",notify:=false)
    {
        this.options := Options
        this.cap := {}
        this.cap.capabilities := {}
        this.cap.capabilities.alwaysMatch := { this.options :{"w3c":json.true}}
        this.cap.capabilities.alwaysMatch.browserName := browser
        this.cap.capabilities.alwaysMatch.platformName := platform
        if(notify = false)
            this.AddexcludeSwitches("enable-automation")
        this.cap.capabilities.firstMatch := [{}]
        this.cap.desiredCapabilities := {}
        this.cap.desiredCapabilities.browserName := browser
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
                for i, arg in this.cap.capabilities.alwaysMatch[this.Options].args
                    if (arg = "--headless")
                        this.RemoveArg(arg)
	        }	
        }

        get
        {
            return capabilities._hmode
        }
    }
    
    setUserProfile(profileName:="Default", userDataDir:="") ; user data dir doesnt change often, use the default
	{
		if !userDataDir
			userDataDir := "C:/Users/" A_UserName "/AppData/Local/Google/Chrome/User Data"
        userDataDir := StrReplace(userDataDir, "\", "/")

        for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
        {
            if instr(argtbr,"--user-data-dir=") or instr(argtbr,"--profile-directory=") ; remove if arg already has profile
                this.cap.capabilities.alwaysMatch[this.Options].RemoveAt(i)
        }
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
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

    RemoveArg(arg)
    {
	    for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
	    {
	        if (argtbr = arg)
		    this.cap.capabilities.alwaysMatch[this.Options].args.RemoveAt(i)
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
        this.cap.capabilities.alwaysMatch := { this.options :{"prefs":{"dom.ipc.processCount": 8,"javascript.options.showInConsole": json.false()}}}
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
        arg := strreplace(arg,"--","-")
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].args)
            this.cap.capabilities.alwaysMatch[this.Options].args := []
        this.cap.capabilities.alwaysMatch[this.Options].args.push(arg)
    }

    RemoveArg(arg)
    {
        arg := strreplace(arg,"--","-")
	    for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
	    {
	        if (argtbr = arg)
		    this.cap.capabilities.alwaysMatch[this.Options].RemoveAt(i)
	    }
    }

    setUserProfile(profileName:="Profile1") ; user data dir doesnt change often, use the default
	{
        userDataDir := A_AppData "\Mozilla\Firefox\Profiles\"
        profileini := A_AppData "\Mozilla\Firefox\profiles.ini"
        IniRead, profilePath , % profileini, % profileName, Path
        for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
        {
            if (argtbr = "-profile") or instr(argtbr,"\Mozilla\Firefox\Profiles\")
                this.cap.capabilities.alwaysMatch[this.Options].RemoveAt(i)
        }
        this.addArg("-profile")
        this.addArg(StrReplace(A_AppData "\Mozilla\Firefox\" profilePath, "\", "/"))
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
    Addextensions(crxlocation)
    {
        ; if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
        ;     this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        ; crxlocation := StrReplace(crxlocation, "\", "/")
        ; this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }
}

class OperaCapabilities extends ChromeCapabilities
{
    Addextensions(crxlocation)
    {
        ; if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
        ;     this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        ; crxlocation := StrReplace(crxlocation, "\", "/")
        ; this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
    }
}