Class Keyboard extends Actions
{
    __new()
    {
        this.Act := {}
        this.Act.actions := []
        this.Act.id := "keyboard"
        this.Act.type := "key"
    }
    
    __Delete()
    {
    }

    SendKey(keys)
    {
        for n, k in StrSplit(keys)
        {
            this.keyDown(k)
            this.keyUp(k)
        }
    }

    keyUp(key)
    {
        this.insert({"type": "keyUp","value":Key})
    }

    keyDown(key)
    {
        this.insert({"type": "keyDown","value":Key})
    }
}

Class Mouse extends Actions
{
    __new(pointerType:="mouse") ; pointerType should be "mouse", "pen", or "touch"
    {
        this.Act := {}
        this.Act.actions := []
        this.Act.id := "mouse"
        this.Act.type := "pointer"
        this.Parameters(pointerType) 
    }

    __Delete()
    {
    }

    click(button:=0,x:=0,y:=0,duration:=500)
    {
        
        this.move(x,y,0)
        this.press(button,duration)
        this.Pause(500)
        this.release(button,duration)
    }

    Press(button:=0)
    {
        i := {"type":"pointerDown","button":button}
        this.insert(i)
    }

    Release(button:=0)
    {
        i := {"type":"pointerUp","button":button}
        this.insert(i)    
    }

    Move(x:=0,y:=0,duration:=10,width:=0,height:=0,pressure:=0,tangentialPressure:=0,tiltX:=0,tiltY:= 0,twist:=0,altitudeAngle:=0,azimuthAngle:=0,origin:="viewport")
    {
        i := {"type": "pointerMove"
            ,"duration": duration, "x": x, "y": y
            ,"origin": origin
            ,"width":width,"height":height
            ,"pressure":pressure,"tangentialPressure":tangentialPressure
            ,"tiltX":tiltX,"tiltY":tiltY, "twist" :twist
            ,"altitudeAngle":altitudeAngle, "azimuthAngle":azimuthAngle}
        this.insert(i)
    }
}

Class Scroll extends Actions
{
    __new(pointerType:="mouse") ; pointerType should be "mouse", "pen", or "touch"
    {
        this.Act := {}
        this.Act.actions := []
        this.Act.id := "Scroll1"
        this.Act.type := "wheel"
    }

    __Delete()
    {
    }
    
    ScrollUP(s:=50)
    {
        this.Scroll(0,-(s))
    }

    ScrollDown(s:=50)
    {
        this.Scroll(0,s)
    }

    ScrollLeft(s:=50)
    {
        this.Scroll(-(s),0)
    }

    ScrollRight(s:=50)
    {
        this.Scroll(s,0)
    }

    Scroll( deltaX:=0, deltaY:=0, x:=0, y:=0, duration:=0,origin:="viewport") 
    {
        i := {"type": "scroll"
            ,"duration": duration, "x": x, "y": y
            ,"deltaX": deltaX, "deltaY": deltaY
            ,"origin": origin}
        this.insert(i)    
    }
}


Class Actions
{
    __Delete()
    {
    }

    Parameters(Pointer)
    {
       this.Act.parameters := {"pointerType": Pointer }
    }
    
    perform()
    {
        return this.Act
    }

    Clear()
    {
        this.Act.Actions := []
    }

    insert(i)
    {
        this.Act.Actions.Push(i)
    }

    Pause(duration:=100)
    {
        this.insert({"type": "pause","duration":duration})
    }

    cancel() 
    {
        this.insert({"type": "pointerCancel"})
    }
}