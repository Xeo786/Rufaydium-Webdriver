
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

    Setbinary(location)
    {
        this.cap.capabilities.alwaysMatch[this.Options].binary := StrReplace(location, "\", "/")
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

    addArg(arg) ; args links https://peter.sh/experiments/chromium-command-line-switches/
    {
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].args)
            this.cap.capabilities.alwaysMatch[this.Options].args := []
        this.cap.capabilities.alwaysMatch[this.Options].args.push(arg)
    }

    RemoveArg(arg)
    {
	    for i, argtbr in this.cap.capabilities.alwaysMatch[this.Options].args
	    {
	        if (argtbr = arg)
		    this.cap.capabilities.alwaysMatch[this.Options].RemoveAt(i)
	    }
    }

    Addextensions(crxlocation)
    {
        if !IsObject(this.cap.capabilities.alwaysMatch[this.Options].extensions)
            this.cap.capabilities.alwaysMatch[this.Options].extensions := []
        crxlocation := StrReplace(crxlocation, "\", "/")
        this.cap.capabilities.alwaysMatch[this.Options].extensions.push(crxlocation)
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

	setUserProfile(profileName:="Default", userDataDir:="") ; user data dir doesnt change often, use the default
	{
		if !userDataDir
			userDataDir := "C:/Users/" A_UserName "/AppData/Local/Google/Chrome/User Data"
        userDataDir := StrReplace(userDataDir, "\", "/")
        this.addArg("--user-data-dir=" userDataDir)
        this.addArg("--profile-directory=" profileName)
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

class FireFoxCapabilities extends Capabilities
{
    __new(browser,Options,platform:="windows",notify:=false)
    {
        this.options := Options
        this.cap := {}
        this.cap.capabilities := {}
        this.cap.capabilities.alwaysMatch := { this.options :{"prefs":{ "dom.ipc.processCount": 8,"javascript.options.showInConsole": json.false()}}}
        this.cap.capabilities.alwaysMatch.browserName := browser
        this.cap.capabilities.alwaysMatch.platformName := platform
        this.cap.capabilities.log := {}
        this.cap.capabilities.log.level := "trace"
        this.cap.capabilities.env := {}
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
}