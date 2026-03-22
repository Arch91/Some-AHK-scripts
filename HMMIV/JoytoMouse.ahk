; Increase the following value to make the mouse cursor move faster:
JoyMultiplier = 0.30

; Decrease the following value to require less joystick displacement-from-center
; to start moving the mouse.  However, you may need to calibrate your joystick
; -- ensuring it's properly centered -- to avoid cursor drift. A perfectly tight
; and centered joystick could use a value of 1:
JoyThreshold = 3

LeftStickIsMoved := false
LeftMouseButtonClicked := false
RightMouseButtonClicked := false
LArrowIsPressed := false
DArrowIsPressed := false
RArrowIsPressed := false
UArrowIsPressed := false
Joy1ButtonIsPressed := false
Joy2ButtonIsPressed := false
Joy3ButtonIsPressed := false
;Joy3ButtonIsHolded := false
Joy4ButtonIsPressed := false
;Joy4ButtonIsHolded := false
;Joy5ButtonIsHolded := false
;Joy6ButtonIsPressed := false
Joy7ButtonIsPressed := false
Joy8ButtonIsPressed := false
Joy9ButtonIsPressed := false
Joy10ButtonIsPressed := false

; It could be useful for finding out the coordinates for MouseClick relating to a game screen
; resolution in the certain places, but I decided to just use static x,y values for 1024x768 resolution.
;total_width = 0
;total_height = 0

MouseXPos = 0
MouseYPos = 0

; If your system has more than one joystick, increase this value to use a joystick
; other than the first:
JoystickNumber = 1

; END OF CONFIG SECTION -- Don't change anything below this point unless you want
; to alter the basic nature of the script.

#SingleInstance

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
; Copipasted the code related to JoytoMouse reapplying :p Do not actually understand the Delta meaning
; and the smooth moving parts of it... So mostly left the calculation proccess untouched.

#Persistent
SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick.

return  ; End of auto-execute section.

; The subroutines below do not use KeyWait because that would sometimes trap the
; WatchJoystick quasi-thread beneath the wait-for-button-up thread, which would
; effectively prevent mouse-dragging with the joystick.

WatchJoystick:
IfWinActive, Heroes 4
{
;	if total_width = 0
;		WinGetPos,,, total_width, total_height, A
	MouseNeedsToBeMoved := false ; Set default.
	SetFormat, float, 03
	GetKeyState, JoyX, %JoystickNumber%JoyX
	GetKeyState, JoyY, %JoystickNumber%JoyY
	GetKeyState, JoyR, %JoystickNumber%JoyR
	GetKeyState, JoyU, %JoystickNumber%JoyU
	GetKeyState, JoyZ, %JoystickNumber%JoyZ
	GetKeyState, JoyPOV, %JoystickNumber%JoyPOV

	if (JoyU < 46) || (JoyU > 54)
	{
		MouseNeedsToBeMoved := true
		DeltaX := JoyU - JoyThresholdLower
	}
	else
		DeltaX = 0
	;if (JoyR > %JoyThresholdUpper%) || (JoyR < %JoyThresholdLower%)
	if (JoyR < 46) || (JoyR > 54)
	{
		MouseNeedsToBeMoved := true
		DeltaY := JoyR - JoyThresholdLower
	}
	else
		DeltaY = 0

	if MouseNeedsToBeMoved
	{
		SetMouseDelay, -1  ; Makes movement smoother.
		MouseMove, DeltaX * JoyMultiplier, DeltaY * JoyMultiplier, 0, R
	}

	if !LeftMouseButtonClicked && (JoyZ > 60)
	{
		LeftMouseButtonClicked := true
		MouseClick, left,,, 1, 0, D  ; Hold down the left mouse button.
	}
	else if LeftMouseButtonClicked && (JoyZ <= 60)
	{
		LeftMouseButtonClicked := false
		MouseClick, Left,,, 1, 0, U  ; Release the left mouse button.
	}
		if !RightMouseButtonClicked && (JoyZ < 40)
	{
		RightMouseButtonClicked := true
		MouseClick, right,,, 1, 0, D  ; Hold down the right mouse button.
	}
	else if RightMouseButtonClicked && (JoyZ >= 40)
	{
		RightMouseButtonClicked := false
		MouseClick, right,,, 1, 0, U  ; Release the right mouse button.
	}

	if ((JoyX < 38) || (JoyX > 62) || (JoyY < 38) || (JoyY > 62))
	{
		LeftStickIsMoved := true
		if ((JoyX - 50) == 0) && ((50 - JoyY) < 0)
			Angle = 270
		else if ((50 - JoyY) == 0) && ((JoyX - 50) < 0)
			Angle = 0
		else if ((JoyX - 50) == 0) && ((50 - JoyY) > 0)
			Angle = 90
		else if ((50 - JoyY) == 0) && ((JoyX - 50) > 0)
			Angle = 180
		else
		{
			Angle := ATan(((JoyY - 50)) / (JoyX - 50)) * 180 / 3.141592653589793
			if ((JoyX - 50) > 0) && ((50 - JoyY) > 0) || ((JoyX - 50) > 0) && ((50 - JoyY) < 0)
				Angle := Angle + 180
			else if ((JoyX - 50) < 0) && ((50 - JoyY) < 0)
				Angle := Angle + 360
		}

		if (Angle >= 338) && (Angle < 360) || (Angle >= 0) && (Angle < 23)
			Send {Ctrl down}{Left down}{Up up}{Right up}{Down up}
		else if (Angle >= 23) && (Angle < 68)
			Send {Ctrl down}{Left down}{Up down}{Right up}{Down up}
		else if (Angle >= 68) && (Angle < 113)
			Send {Ctrl down}{Up down}{Right up}{Down up}{Left up}
		else if (Angle >= 113) && (Angle < 158)
			Send {Ctrl down}{Up down}{Right down}{Down up}{Left up}
		else if (Angle >= 158) && (Angle < 203)
			Send {Ctrl down}{Right down}{Up up}{Down up}{Left up}
		else if (Angle >= 203) && (Angle < 248)
			Send {Ctrl down}{Right down}{Down down}{Up up}{Left up}
		else if (Angle >= 248) && (Angle < 293)
			Send {Ctrl down}{Down down}{Up up}{Right up}{Left up}
		else if (Angle >= 293) && (Angle < 338)
			Send {Ctrl down}{Down down}{Left down}{Up up}{Right up}
	}
	else if ((JoyX >= 38) && (JoyX <= 62) && (JoyY >= 38) && (JoyY <= 62))
	{
		if LeftStickIsMoved
		{
			LeftStickIsMoved := false
			Send {Ctrl up}{Up up}{Right up}{Down up}{Left up}
		}
	}

	If JoyPOV = 27000 ;Left arrow
	{
		if !LArrowIsPressed
		{
			LArrowIsPressed := true
			Send {Left down} ; move an army left
		}
	}
	else If JoyPOV = 18000 ;Down arrow
; I consider using L1+../R1+.. up/down combos for moving an army to those up-/down-left, up-/down-right
; diagonal directions is functionally better, because it's more precise, and easier than hitting D-pad diagonal arrows in correct way.
	{
		if !DArrowIsPressed
		{
			DArrowIsPressed := true
			if GetKeyState(JoystickNumber . "Joy5")
				Send {Numpad1} ; move an army to the down-left diagonal
			else if GetKeyState(JoystickNumber . "Joy6")
				Send {Numpad3} ; move an army to the down-right diagonal
			else
				Send {Down down} ; move an army down
		}
	}
	else If JoyPOV = 9000 ;Right arrow
	{
		if !RArrowIsPressed
		{
			RArrowIsPressed := true
			Send {Right down} ; move an army right
		}
	}
	else If JoyPOV = 0 ;Up arrow
	{
		if !UArrowIsPressed
		{
			UArrowIsPressed := true
			if GetKeyState(JoystickNumber . "Joy5")
				Send {Numpad7} ; move an army to the up-left diagonal
			else if GetKeyState(JoystickNumber . "Joy6")
				Send {Numpad9} ; move an army to the up-right diagonal
			else
				Send {Up down} ; move an army up
		}
	}
	else If JoyPOV = -1
	{
		if LArrowIsPressed || DArrowIsPressed ||  RArrowIsPressed || UArrowIsPressed
		{
			LArrowIsPressed := false
			DArrowIsPressed := false
			RArrowIsPressed := false
			UArrowIsPressed := false
			Send {Left up}{Up up}{Right up}{Down up}
		}
	}

	if (!Joy1ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy1")
	{
		if GetKeyState(JoystickNumber . "Joy6")
			Send {Enter} ; move an army to 'that' direction, OK
		else ; Better use MouseClick on the 'wait' button instead of hitting 'd'
		{
			MouseGetPos, MouseXPos, MouseYPos
			MouseClick, left, 954, 136 ; in battle - click on the defense button (for 1024x768)
			MouseMove, MouseXPos, MouseYPos, 0
		}
		Joy1ButtonIsPressed := true
	}
	else if Joy1ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy1")
		Joy1ButtonIsPressed := false

	if (!Joy2ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy2")
	{
		if GetKeyState(JoystickNumber . "Joy6")
			Send {Esc} ; cancel things
		else ; Better use MouseClick on the 'wait' button instead of hitting 'w'
		{
			MouseGetPos, MouseXPos, MouseYPos
			MouseClick, left, 954, 190 ; in battle - click on the wait button (for 1024x768)
			MouseMove, MouseXPos, MouseYPos, 0
		}
		Joy2ButtonIsPressed := true
	}
	else if Joy2ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy2")
		Joy2ButtonIsPressed := false

	if (!Joy3ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy3")
	{
		if GetKeyState(JoystickNumber . "Joy5")
			Send {PgDn} ; scroll the list of the towns down
		else if GetKeyState(JoystickNumber . "Joy6")
			Send {e} ; end the turn
		else
			Send {h} ; choicing the (next) army
		Joy3ButtonIsPressed := true
	}
	else if Joy3ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy3")
		Joy3ButtonIsPressed := false

	if (!Joy4ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy4")
	{
		if GetKeyState(JoystickNumber . "Joy5")
			Send {PgUp} ; scroll the list of the towns up
;		else if GetKeyState(JoystickNumber . "Joy6") Unneeded, because 'c' is for spells either way
		else
			Send {c} ; choicing the spell to cast, either on the map or in battle
;		else
;		{
;			MouseGetPos, MouseXPos, MouseYPos
;			MouseClick, left, 954, 78
;			MouseMove, MouseXPos, MouseYPos, 0
;		}
		Joy4ButtonIsPressed := true
	}
	else if Joy4ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy4")
		Joy4ButtonIsPressed := false

	if (!Joy7ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy7")
	{
		Send !{l} ; Load Game
		Joy7ButtonIsPressed := true
	}
	else if Joy7ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy7")
		Joy7ButtonIsPressed := false

	if (!Joy8ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy8")
	{
		Send !{s} ; Save Game
		Joy8ButtonIsPressed := true
	}
	else if Joy8ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy8")
		Joy8ButtonIsPressed := false

	if (!Joy9ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy9")
	{
		if GetKeyState(JoystickNumber . "Joy5")
			Send {d} ; dig
		else
			Send {p} ; puzzles (oracles)
		Joy9ButtonIsPressed := true
	}
	else if Joy9ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy9")
		Joy9ButtonIsPressed := false

	if (!Joy10ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy10")
	{
		if GetKeyState(JoystickNumber . "Joy5")
			Send {u} ; underground / upsurface landscape toggle
		else if GetKeyState(JoystickNumber . "Joy6")
			Send {m} ; market
		else
			Send {v} ; map (world)
		Joy10ButtonIsPressed := true
	}
	else if Joy10ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy10")
		Joy10ButtonIsPressed := false
	
	return
}
