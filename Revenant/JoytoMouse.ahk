; Increase the following value to make the mouse cursor move faster:
JoyMultiplier = 0.30

; Decrease the following value to require less joystick displacement-from-center
; to start moving the mouse.  However, you may need to calibrate your joystick
; -- ensuring it's properly centered -- to avoid cursor drift. A perfectly tight
; and centered joystick could use a value of 1:
JoyThreshold = 3

LastWasRightAxis := false
RStickIsMoved := false
LeftMouseButtonClicked := false
RightMouseButtonClicked := false
LArrowIsPressed := false
UArrowIsPressed := false
RArrowIsPressed := false
DArrowIsPressed := false
Joy1ButtonIsPressed := false
Joy2ButtonIsPressed := false
Joy3ButtonIsPressed := false
Joy3ButtonIsHolded := false
Joy4ButtonIsPressed := false
Joy4ButtonIsHolded := false
Joy5ButtonIsHolded := false
;Joy6ButtonIsPressed := false
;Joy7ButtonIsPressed := false
Joy8ButtonIsPressed := false
Joy9ButtonIsPressed := false
Joy10ButtonIsPressed := false
BowMode := false

; Store the starting time in a variable
;PresentTime := A_TickCount
; - but not here, cause it must be refreshing. That's related to the in-combat dodgings.
FutureCame = 0
HalfSecPassed := true

; Next one is an attempt to guess and attach the center coordinates of mouse circling around the
; character in dependence of panels shown at the screen.
SidePanel = 1 ; 1,12,13 - RightPanel+LowerPanel ,, 0 - Clean Screen with no Panels ,, 2,3 - RightPanel

total_width = 0
total_height = 0

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
IfWinActive, Revenant
{
	; Store the starting time in a variable
	PresentTime := A_TickCount
	if total_width = 0
		WinGetPos,,, total_width, total_height, A
	MouseNeedsToBeMoved := false ; Set default.
	SetFormat, float, 03
	GetKeyState, JoyX, %JoystickNumber%JoyX
	GetKeyState, JoyY, %JoystickNumber%JoyY
	GetKeyState, JoyR, %JoystickNumber%JoyR
	GetKeyState, JoyU, %JoystickNumber%JoyU
	GetKeyState, JoyZ, %JoystickNumber%JoyZ
	GetKeyState, JoyPOV, %JoystickNumber%JoyPOV
	;if (JoyU > %JoyThresholdUpper%) || (JoyU < %JoyThresholdLower%)
	if (JoyX < 43) || (JoyX > 57) || (JoyY < 43) || (JoyY > 57)
	{
		if LastWasRightAxis
			LastWasRightAxis := false
		MouseNeedsToBeMoved := true
	}
	else
	{
		if (JoyU < 46) || (JoyU > 54)
		{
			if !LastWasRightAxis
				LastWasRightAxis := true
			MouseNeedsToBeMoved := true
			DeltaX := JoyU - JoyThresholdLower
		}
		else
			DeltaX = 0
		;if (JoyR > %JoyThresholdUpper%) || (JoyR < %JoyThresholdLower%)
		if (JoyR < 46) || (JoyR > 54)
		{
			if !LastWasRightAxis
				LastWasRightAxis := true
			MouseNeedsToBeMoved := true
			DeltaY := JoyR - JoyThresholdLower
		}
		else
			DeltaY = 0
	}

	if MouseNeedsToBeMoved
	{
		if LastWasRightAxis ; Use right analog stick as mouse
		{
			SetMouseDelay, -1  ; Makes movement smoother.
			MouseMove, DeltaX * JoyMultiplier, DeltaY * JoyMultiplier, 0, R
		}
		else ; Use left analog stick as mouse which is moving around the character
		{
			if ( PresentTime > FutureCame ) && !HalfSecPassed
			{
				RightMouseButtonClicked := false
				HalfSecPassed := true
			}				
			if !RStickIsMoved && ((JoyU < 46) || (JoyU > 54)|| (JoyR < 46) || (JoyR > 54))
			; But priority first, check whether the right analog stick is also moved.
			; Moving right analog stick while left analog stick is moving will trigger the
			; dodge to the appropriate right stick direction.
			{
; The commented below is the formula of degree measurement of a circular arc is using. Gogglize about
; it if you are not quite familiar with it. And so, imagine the reapplying the horizontal and vertical
; axises of the gamepad's analog stick (particularly here, the right one) as they are the X and Y axises
; of the deckardian coordinate system. AutoHotKey accepts right analog stick axises the next way -
; JoyU goes from left to right as from 0 to 100, and JoyR goes from up to down as from 0 to 100.
; Axises U and R will cross in the (50, 50) point, and speaking of decardian representation, R axis
; is inverted.
; That formula will give the result value of the angle AOB which belongs to the circle, the angle's points
; A and B are lying on the circle, and point O is the center of the circle (of analog stick, right?..)
; After reapplying analog stick variables AutoHotKey is giving to stick's axises, we are having:
; A (-50, 0)
; O (0, 0)
; B(JoyU - 50, (-1)*(JoyR - 50))
; - these coordinates. The B point of the coordinates of our right analog stick in the moment we are
; moving it this or that direction, and note that it have (-1) cause it is inverted relating to
; decardian's Y axis reapplying.
;				if JoyR > 50
;					AnglePrev := 360 - ACos(((-50)*(JoyU - 50)) / (50*Sqrt((JoyU ** 2) - 100*JoyU + 5000 - 100*JoyR + (JoyR ** 2)))) * 180 / 3.141592653589793
;				else
;					AnglePrev := ACos(((-50)*(JoyU - 50)) / (50*Sqrt((JoyU ** 2) - 100*JoyU + 5000 - 100*JoyR + (JoyR ** 2)))) * 180 / 3.141592653589793
; However, in the location I found the above formula I was following there was the title of this formula
; that it is for the case when points A and B of the angle AOB are laying ON THE CIRCLE, which means the
; lengths OA and OB are equal, and with our analog stick movements they are mostly not.
; So eventually, with the same reapplying described above, I used another formula with arctangents.
; But arctangents are arctangents, they must be corrected a lil bit for each one zone of four in the
; reapplying to decardian, plus we must be aware of dividing to zero.
				if ((JoyU - 50) == 0) && ((50 - JoyR) < 0)
					Angle = 270
				else if ((50 - JoyR) == 0) && ((JoyU - 50) < 0)
					Angle = 0
				else if ((JoyU - 50) == 0) && ((50 - JoyR) > 0)
					Angle = 90
				else if ((50 - JoyR) == 0) && ((JoyU - 50) > 0)
					Angle = 180
				else
				{
					Angle := ATan(((JoyR - 50)) / (JoyU - 50)) * 180 / 3.141592653589793
					if ((JoyU - 50) > 0) && ((50 - JoyR) > 0) || ((JoyU - 50) > 0) && ((50 - JoyR) < 0)
						Angle := Angle + 180
					else if ((JoyU - 50) < 0) && ((50 - JoyR) < 0)
						Angle := Angle + 360
				}
; Totally, both formulas are correct and provides the equal result :p somehow... The only what matters
; is it works. Uncomment the tooltip below and the 4 lines of code of the Angle formula above to
; see that they provide and equal result. If you care.
;					ToolTip, %Angle%%a_space%%AnglePrev%%a_space%%JoyU%%a_space%%JoyR%
				if GetKeyState("RButton")
				{
					MouseClick, right,,, 1, 0, U  ; Release the right mouse button...
					FutureCame := PresentTime + 500 ; ...for a half of sec, just for a single dodge movement ;p...
					HalfSecPassed := false ; ...but after, let's continue to read R2 for the right mouse button.
				}
			; BUUUT }:[ unfortunately, there is a bug in the engine or something... The diagonal dodgings are not
			; operationable. So, instead of the commented code for 8 directions, will be using just four :/
			; And moreover, when character is facing the enemy diagonal direction, the character
			; have problems to dodge in the 'perpendicular' sides, so that case backward and forward dodges
			; only T_T
			;	if (Angle >= 338) && (Angle < 360) || (Angle >= 0) && (Angle < 23)
			;		Send ^{Left}
			;	else if (Angle >= 23) && (Angle < 68)
			;		Send ^{Home}
			;	else if (Angle >= 68) && (Angle < 113)
			;		Send ^{Up}
			;	else if (Angle >= 113) && (Angle < 158)
			;		Send ^{PgUp}
			;	else if (Angle >= 158) && (Angle < 203)
			;		Send ^{Right}
			;	else if (Angle >= 203) && (Angle < 248)
			;		Send ^{PgDn}
			;	else if (Angle >= 248) && (Angle < 293)
			;		Send ^{Down}
			;	else if (Angle >= 293) && (Angle < 338)
			;		Send ^{End}
				if (Angle >= 315) && (Angle < 360) || (Angle >= 0) && (Angle < 45)
					Send ^{Left}
				else if (Angle >= 45) && (Angle < 135)
					Send ^{Up}
				else if (Angle >= 135) && (Angle < 225)
					Send ^{Right}
				else if (Angle >= 225) && (Angle < 315)
					Send ^{Down}
				RStickIsMoved := true
			}
			else ; if right analog stick is in it's center, (continue to) round the mouse
				 ; cursor around the character.
			RStickIsMoved := false
			{
				if SidePanel = 0
				{
					aroundPos_x_axis := round(total_width*0.47) + total_width//4*(0.02*JoyX - 1)
					aroundPos_y_axis := round(total_height*0.393) + total_height//5*(0.02*JoyY - 1)
				}
				else if (SidePanel = 1) || (SidePanel = 12) || (SidePanel = 13)
				{
					aroundPos_x_axis := round(total_width*0.323) + total_width//4*(0.02*JoyX - 1)
					aroundPos_y_axis := round(total_height*0.33) + total_height//5*(0.02*JoyY - 1)
				}
				else if (SidePanel = 2) || (SidePanel = 3)
				{
					aroundPos_x_axis := round(total_width*0.323) + total_width//4*(0.02*JoyX - 1)
					aroundPos_y_axis := round(total_height*0.393) + total_height//5*(0.02*JoyY - 1)
				}
				MouseMove, aroundPos_x_axis, aroundPos_y_axis, 0
			}
		}
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
	If JoyPOV = 27000 ;Left Arrow
	{
		If ( !LArrowIsPressed )
		{
			LArrowIsPressed := true
; using L1+Left keycombo when there are no any panels will reset SidePanel variable to zero,
; so that should restore the logical attempt of center coordinate of the mouse rounding
; around the character for the left analog stick.
			if GetKeyState(JoystickNumber . "Joy5")
				if GetKeyState(JoystickNumber . "Joy6")
; using L1+R1+Left should fix the annoying screen size calculation
; which sometimes do it for a desktop screen instead of the in-game one :/
					WinGetPos,,, total_width, total_height, A
				else
					SidePanel = 0
			else ; pressing just left arrow button will trigger keyboard's "Space" key button.
			{
				Send, {Space} ;Full Screen hotkey
				if SidePanel != 0
					SidePanel = 0
				else
					SidePanel = 1
			}
		}
	}
	else If JoyPOV = 18000 ;Down Arrow
	{
		If ( !DArrowIsPressed )
		{
		; Toggle map/inventory.
			DArrowIsPressed := true
			if (SidePanel = 0) || (SidePanel = 3)
			{
				Send, {6} ;Map hotkey
				SidePanel = 2
			}
			else if (SidePanel = 1) || (SidePanel = 13)
			{
				Send, {6}
				SidePanel = 12
			}
			else if SidePanel = 2
			{
				Send, {5} ;Inventory hotkey
				SidePanel = 3
			}
			else if SidePanel = 12
			{
				Send, {5} ;Open inventory, both panels, assuming that previous was the map
				SidePanel = 13
			}
		}
	}
;	else If JoyPOV = 9000 ;Right Arrow. Using for Right+JoyButton4 combo for a block, and Right+JoyButton10 combo for a bow mode.
;	{
;	}
;	else If JoyPOV = 0 ;Up Arrow. Using for Up+JoyButton1/2/3 combos for an advanced attack moves.
;	{
;	}
	else If JoyPOV = -1
	{
		if LArrowIsPressed
			LArrowIsPressed := false
		if DArrowIsPressed
			DArrowIsPressed := false
;		if UArrowIsPressed
;			UArrowIsPressed := false
;		if RArrowIsPressed
;			RArrowIsPressed := false
	}

	if (!Joy1ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy1")
	{
		If GetKeyState(JoystickNumber . "Joy6")
			Send {F1} ; 1st invoke hotkey
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F5} ; use 1st item of belt hotkey
		else if JoyPOV = 0
			Send {q} ; 1st advanced attack move hotkey - StepChop, and further (mostly unavoidable) any other q/a/s/d attack will do a kick
		else
			Send {a} ; Swing attack hotkey
		Joy1ButtonIsPressed := true
	}
	else if Joy1ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy1")
		Joy1ButtonIsPressed := false

	if (!Joy2ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy2")
	{
		If GetKeyState(JoystickNumber . "Joy6")
			Send {F2} ; 2nd invoke hotkey
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F6} ; use 2nd item of belt hotkey
		else if JoyPOV = 0
			Send {w} ; 2nd advanced attack move hotkey - looks like hitting "d" while walking but from the stand and more powerful.
		else
			Send {s} ; Thrust attack hotkey
		Joy2ButtonIsPressed := true
	}
	else if Joy2ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy2")
		Joy2ButtonIsPressed := false

	if (!Joy3ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy3")
	{
		if BowMode
		{
			Send {z down} ; shoot an arrow from a bow hotkey. Left-Right to aim while holding it.
			Joy3ButtonIsHolded := true
		}
		else
		{
			If GetKeyState(JoystickNumber . "Joy6")
				Send {F3} ; 3rd invoke hotkey
			else If GetKeyState(JoystickNumber . "Joy7")
				Send {F7} ; use 3rd item of belt hotkey
			else
			{
				Random, ASDrandomizer, 0, 2
				if ASDrandomizer = 0
					Send {a}
				else if ASDrandomizer = 1
					Send {s}
				else if ASDrandomizer = 2
					Send {d}
			}
		}
		Joy3ButtonIsPressed := true
	}
	else if Joy3ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy3")
	{
		Joy3ButtonIsPressed := false
		if Joy3ButtonIsHolded
		{
			Send {z up}
			Joy3ButtonIsHolded := false
		}
	}

	if (!Joy4ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy4")
	{
		If GetKeyState(JoystickNumber . "Joy6")
			Send {F4} ; 4th invoke hotkey
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F8} ; use 4th item of belt hotkey
		else if JoyPOV = 0
			Send {e} ; 3rd advanced attack move hotkey - DragonHit. 5 hits combo.
		else if JoyPOV = 9000
		{
			Send {f down} ; Block (in combat state) hotkey.
			; Don't blame this script for the block is not functional in times - it's the game
			; engine's fault... The enemies are doing blocks but are not able to block your attacks
			; anyway, and they are not moaning. Not literally...
			Joy4ButtonIsHolded := true
		}
		else
			Send {d}
		Joy4ButtonIsPressed := true
	}
	else if Joy4ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy4")
	{
		Joy4ButtonIsPressed := false
		if Joy4ButtonIsHolded
		{
			Send {f up}
			Joy4ButtonIsHolded := false
		}
	}

	if (!Joy5ButtonIsHolded) && GetKeyState(JoystickNumber . "Joy5")
	{
		Send {r down} ; Run hotkey
		Joy5ButtonIsHolded := true
	}
	else if Joy5ButtonIsHolded && !GetKeyState(JoystickNumber . "Joy5")
	{
		Send {r up}
		Joy5ButtonIsHolded := false
	}

	if (!Joy8ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy8")
	{
		Send {Esc} ; Game menu hotkey
		Joy8ButtonIsPressed := true
	}
	else if Joy8ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy8")
		Joy8ButtonIsPressed := false

	if (!Joy9ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy9")
	{
		Send {g} ; Pick-up hotkey
		Joy9ButtonIsPressed := true
	}
	else if Joy9ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy9")
		Joy9ButtonIsPressed := false

	if (!Joy10ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy10")
	{
		If GetKeyState(JoystickNumber . "Joy7")
			Send {F9} ; use 5th item of belt hotkey. Quite not easy to hit such combo XD
		else If JoyPOV = 9000
		{
			Send {x} ; Bow mode/Peaceful state toggle
			if !BowMode
				BowMode := true
			else if BowMode
				BowMode := false
		}
		else
		{
			Send {c} ; Combat/Peaceful state toggle
			if BowMode
				BowMode := false
		}
			
		Joy10ButtonIsPressed := true
	}
	else if Joy10ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy10")
		Joy10ButtonIsPressed := false

	return
}
