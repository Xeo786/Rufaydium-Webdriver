
class capabilities
{
    static Simple := {"capabilities":{"":""}}
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