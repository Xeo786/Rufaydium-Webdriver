; CDP.ahk provides access to Devtools over WebDriver that support Chrome DevTools
; CDP.ahk is exactly Chrome DOM.ahk >> https://www.autohotkey.com/boards/viewtopic.php?t=94276&p=418181 
; by Xeo786


class CDP extends Rufaydium
{
	__new(Address)
	{
		this.address := Address
	}
	
	Document()
	{
		; this.call("DOM.getDocument",{"depth": -1,"pierce":json.true()}) ; its slow, this will get all frame nodeid if cross origin enabled
		root := this.call("DOM.getDocument",{"":""}) 
		this.nodeId := root.root.nodeId	
	}
	
	Call(DomainAndMethod, Params:="") ;https://stackoverflow.com/questions/70654898/selenium-4-x-trying-to-post-cdp-unsupportedcommandexception
	{
		Payload := { "params": Params ? Params : {"":""}, "cmd": DomainAndMethod}
		response := this.Send("goog/cdp/execute"
		,"POST"
		,Payload
		,1)
		return response
	}
	
	Evaluate(JS)
	{
		response := this.Call("Runtime.evaluate",
			( LTrim Join
			{
				"expression": JS,
				"objectGroup": "console",
				"includeCommandLineAPI": Json.true,
				"silent": Json.false,
				"returnByValue": Json.false,
				"userGesture": Json.true,
				"awaitPromise": Json.false
			}
			))		
		return response.result
	}
	
	GetDOCwithframe()
	{
		FrmNodeids := this.call("DOM.getDocument",{"depth": -1,"pierce":json.true()})
		i := 0
		frames := []
		for k, v in FrmNodeids
			frames[++i] := New Element(v,this.address)
		return frames
	}
	
	
	requestNode(Objectid)
	{
		return this.nodeId := this.call("DOM.requestNode",{"objectId":Objectid}).nodeId
	}
	
	resolveNode()
	{
		return this.ObjectID := this.call("DOM.resolveNode",{"nodeId":this.nodeId}).object.objectId
	}
	
	navigate(url)
	{
		this.call("Page.navigate",{"url":url})
	}
	
	WaitForLoad(DesiredState:="complete", Interval:=100)
	{
		while this.Evaluate("document.readyState").value != DesiredState
		{
			Sleep, Interval
		}
	}
	
	querySelector(Path)
	{
		nodeId := this.call("DOM.querySelector",{"nodeId":this.nodeId,"selector":path}).nodeId
		return New CDPElement(nodeId,this.address)
	}
	
	getElementByID(ID)
	{
		ID := "#" ID
		nodeId := this.call("DOM.querySelector",{"nodeId":this.nodeId,"selector":ID}).nodeId
		return New CDPElement(nodeId,this.address)
	}
	
	querySelectorAll(path)
	{
		e := []
		NodeIDs := this.call("DOM.querySelectorAll",{"nodeId":this.nodeId,"selector":path}).nodeIDs
		for i, NodeID in NodeIDs
		{
			e[i] := New CDPElement(NodeID,this.address)
		}
		return e
	}
	
	getElementsbyClassName(Class)
	{
		e := []
		Class = [class='%Class%']
		NodeIDs := this.call("DOM.querySelectorAll",{"nodeId":this.nodeId,"selector":Class}).nodeIDs
		for i, NodeID in NodeIDs
		{
			e[i] := New CDPElement(NodeID,this.address)
		}
		return e
	}
	
	getElementsbyName(Name)
	{
		e := []
		Name = [Name='%Name%']
		NodeIDs := this.call("DOM.querySelectorAll",{"nodeId":this.nodeId,"selector":Name}).nodeIDs
		for i, NodeID in NodeIDs
		{
			e[i] := New CDPElement(NodeID,this.address)
		}
		return e
	}
	
	GetelementbyJS(JS) 
	{	
		result := this.Evaluate(JS)
		
		if (result.className = "NodeList")
		{
			objectId := result.objectId
			e := []
			i := 0
			results := this.call("Runtime.getProperties",{"objectId":Objectid}).result
			for key, obj in results
			{
				for k, v in obj
				{
					if (v.subtype = "Node")
					{
						nodeId := this.call("DOM.requestNode",{"objectId":v.Objectid}).nodeId
						e[++i] := New CDPElement(nodeId,this.address)
					}
				}
				
			}
			return e
		}
		else
		{
			objectId := result.objectId
			nodeId := this.call("DOM.requestNode",{"objectId":Objectid}).nodeId
			return New CDPElement(nodeId,this.address)
		}
	}
	
	focus() ; simply focus on node element
	{
		this.call("DOM.focus",{"nodeId":this.nodeId})
	}
	
	getNodeForLocation(x,y)
	{
		nodeid := this.call("DOM.getNodeForLocation",{"x":x,"y":y}).nodeId
		return New CDPElement(nodeId,this.address)
	}
	
	getBoxModel()
	{ ;this return with model having Height and widths and  x y coordinates of Margin padding and border
		return this.call("DOM.getBoxModel",{"nodeId":this.nodeId}).model
	}
	
	getNodeQuads()
	{ ; return quads are x immediately followed by y for each point, points clock-wise
		return this.call("DOM.getContentQuads",{"nodeId":this.nodeId}).quads[1]
	}
	
	; this simply highlight borders of element but 
	; its slow because highlight element by location and extracting location feels little slow
	highlightRect(r:=255,g:=0,b:=0,a:=1)
	{
		Model := this.getBoxModel()
		height := Model.height
		width := Model.width
		; An array of quad vertices, x immediately followed by y for each point, points clock-wise.
		content :=  Model.border ; getting content quad
		toprightx := round(content[1],0)
		toprighty := round(content[2],0)
		
		color := {"r":r,"g":g,"b":b,"a":a}
		this.call("Overlay.enable")
		this.call("Overlay.highlightRect",{"x":toprightx,"y":toprighty,"width":width,"height":height,"outlineColor":color})
	}
	
	; highlight node Configurations:  
	; will be saved into the Element and will be triggered using element.highlight()
	; Type = Solid or Grid
	; Subtype for Solid are "contentColor","paddingColor","borderColor","marginColor","eventTargetColor","shapeColor","shapeMarginColor","cssGridColor"
	; Subtype for Grid are "gridBorderColor","cellBorderColor","rowLineColor","columnLineColor"
	highlightConfigurations(Type,Subtype,r,g,b,a)
	{
		Basetype := ["contentColor","paddingColor","borderColor","marginColor","eventTargetColor","shapeColor","shapeMarginColor","cssGridColor"]
		Gridtype := ["gridBorderColor","cellBorderColor","rowLineColor","columnLineColor","rowGapColor","rowHatchColor","columnGapColor","columnHatchColor","areaBorderColor","gridBackgroundColor"]
		if(Type = "Solid")
		{
			found := 0
			for k, v in Basetype
			{
				if(Subtype == v)
					found := 1
			}
			
			if found
			{
				this.highlightConfig[Subtype] := {"r":r,"g":g,"b":b,"a":a}
			}
			else
			{
				msgbox, Wrong / missing subtype 
			}
		}
		else if(Type = "Grid")
		{
			found := 0
			for k, v in Gridtype
			{
				if(Subtype == v)
					found := 1
			}
			if found
			{
				this.highlightConfig.GridHighlightConfig[Subtype] := {"r":r,"g":g,"b":b,"a":a}
			}
			else
			{
				msgbox, Wrong / missing subtype 
			}
		}
		else
		{
			msgbox, Type Should be "Solid" or "Grid"
		}
	}
	
	; setting up grid parameters true
	GridSet(Param)
	{
		L := ["showGridExtensionLines"
			,"showPositiveLineNumbers"
			,"showNegativeLineNumbers"
			,"showAreaNames"
			,"showLineNames"
			,"showTrackSizes"
			,"gridBorderDash"
			,"cellBorderDash"
			,"rowLineDash"
			,"columnLineDash"]
		for k, v in L
		{
			if(Param = v)
				found := 1	
		}
		
		if found ;GridHighlightConfig 
			this.highlightConfig.GridHighlightConfig[Param] := Json.true
		else
			msgbox,  % "<" Param "> is wrong parameter"
	}
	
	; highlight element and parameters what should be visible while highlight
	highlight(Info:=0,Styles:=0,Rulers:=0,AccInfo:=0,SaveConfig:=0)
	{
		;highlightConfig["contrastAlgorithm"] := "apca"
		if !this.highlightConfig
		{
			msgbox, Please Set Highlight Configuration`nusing Element.highlightConfigurations()
			return
		}
		
		if Info
			this.highlightConfig["showInfo"] := json.true
		
		if Styles
			this.highlightConfig["showStyles"] := json.true
		
		if Rulers
			this.highlightConfig["showRulers"] := json.true
		
		if AccInfo
			this.highlightConfig["showAccessibilityInfo"] := json.true
		
		this.call("Overlay.enable")
		x := this.call("Overlay.highlightNode",{"highlightConfig":this.highlightConfig,"nodeId":this.nodeId})
		tooltip % json.Dump(x)
		if(SaveConfig = 0)
			this.highlightConfig := ""
		return this.highlightConfig
	}
	
	OuterHTML ; extract outerhtml on request
	{
		get
		{
			return this.call("DOM.getOuterHTML",{"nodeId":this.nodeId}).OuterHTML
		}
		
		set
		{
			this.call("DOM.setOuterHTML",{"nodeId":this.nodeId,"outerHTML":value})
		}		
	}
	
	getAttributes()
	{
		for k, v in this.call("DOM.getAttributes",{"nodeId":this.nodeId}).attributes
		{
			if( mod(a_index, 2) != 1)
			{
				this[key] := v
			}
			key := V
		}
	}
	
	; attrib should be case sensative i.e. class, value and or any custom attrib
	getAttribute(attrib)
	{
		for k, v in this.call("DOM.getAttributes",{"nodeId":this.nodeId}).attributes
		{
			if( mod(a_index, 2) != 1)
			{
				if(Key = attrib)
					return v
			}
			key := V
		}
	}
	
	setAttribute(Name,Value)
	{
		this.call("DOM.setAttributeValue",{"nodeId":this.nodeId,"name":Name,"value":Value}).NodeID
		this[Name] := this.getAttribute(Name)
		return Value
	}
	
	;;;;;;;;;;;; events 
	; Str is string 
	; type Allowed Values: keyDown, keyUp, rawKeyDown but...
	; for text parameter is KeyDownRaw and KeyUp are not required
	; in simple type KeyDownRaw and KeyUp are forbidden 
	SendKey(str,type:="keyDown")
	{
		this.focus()
		for k, v in StrSplit(str)
		{
			this.call("Input.dispatchKeyEvent",{"type":type,"text":v})
		}
		
	}
	
	click(relativeX := 10,relativeY := 10)
	{
		Model := this.getBoxModel()
		height := Model.height
		width := Model.width
		; An array of quad vertices, x immediately followed by y for each point, points clock-wise.
		content :=  Model.content ; getting content quad
		toprightx := content[1]
		toprighty := content[2]
		x := round(toprightx + (width / 2),0)
		y := round(toprighty + ( height / 2),0)
		this.ClickCoord(x,y, delay:= 10)
	}
	
	; x and y are coords
	; Delay is delay between button down and button up
	ClickCoord(x,y, delay:= 10)
	{
		MouseEvent := {"type":"mousePressed","button":"left","x":x,"y":y,"clickCount":1}
		this.call("Input.dispatchMouseEvent",MouseEvent)
		sleep, % delay
		MouseEvent := {"type":"mouseReleased","button":"left","x":x,"y":y,"clickCount":1}
		this.call("Input.dispatchMouseEvent",MouseEvent)
	}
	
	getFrameElement(frameID)
	{
		if !frameID
		{
			msgbox, no frame id found
			return
		}
		
		nodeId := this.call("DOM.getFrameOwner",{"frameId":frameID}).nodeId
		if nodeId 
			return New CDPElement(nodeId,this.Address)
	}
	
	GetFrame(i:="")
	{
		Frames := {}
		Getchildframe(this.call("Page.getFrameTree").frametree,Frames)
		if(i = "")
		{
			return Frames
		}
		
		for k, frame in Frames
			for n, p in frame
				if(i = p)
					return frame
	}
}

Getchildframe(childframes,Frames)
{
	bkchildframes := []
	for k, cf in childframes
	{
		
		if(k = "frame")
		{
			if CF.name
				Frames.push({"Name":cf.name,"id":cf.id})
		}
		else if(k = "childFrames")
			bkchildframes.push(cf)
			
		if isobject(cf) and jee_IsNumeric(k)
			Getchildframe(cf,Frames)
	}
	
	if( bkchildframes.length() > 0)
		for j, l in bkchildframes
			Getchildframe(l,Frames)
}

jee_IsNumeric(var){
	static number := "number"
	if var is number
		return true
	return false
}

Class CDPElement extends CDP
{
	__new(nodeId,address)
	{
		this.address := address
		this.nodeId := nodeId
	}
	
	Value
	{
		set
		{
			this.call("DOM.setAttributeValue",{"nodeId":this.nodeId,"name":"value","value":Value}) 
			return value
		}
		
		get
		{
			return this.getAttribute("Value")
		}
	}
	
	Class
	{
		set
		{
			this.call("DOM.setAttributeValue",{"nodeId":this.nodeId,"name":"Class","value":Value}) 
			return value
		}
		
		get
		{
			return this.getAttribute("Class")
		}
	}
	
	id
	{
		set
		{
			this.call("DOM.setAttributeValue",{"nodeId":this.nodeId,"name":"id","value":Value}) 
			return value
		}
		
		get
		{
			return this.getAttribute("id")
		}
	}
	
	innerText
	{
		get
		{
			d  := ComObjCreate("htmlfile")
			d.write(this.outerHTML)
			return d.querySelector("*").innerText
		}
		
		set
		{
			d  := ComObjCreate("htmlfile")
			d.write(ohtml := this.outerHTML)
			iText := d.querySelector("*").innerText
			nHtml := StrReplace(ohtml,itext,value)
			if(ohtml != nHtml)
				this.outerHTML := nHtml
			return value
		}
	}
	
	textContent
	{
		get
		{
			d  := ComObjCreate("htmlfile")
			d.write(this.outerHTML)
			return d.querySelector("*").textContent
		}
		
		set
		{
		}
	}
}

Class CDPPrintOptions ; https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF
{
	static A4_Default =
	( LTrim Join
	{
		"landscape": json.false,
		"printBackground": json.true,
		"scale": 1,
		"paperWidth": 50,
		"paperHeight": 60,
 		"marginTop": 2,
 		"marginBottom": 2,
 		"marginLeft": 2,
 		"marginRight": 2
	}
	)
}
