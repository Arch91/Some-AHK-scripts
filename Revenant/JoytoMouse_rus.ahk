; Увеличте это значение если хотите, чтобы курсор двигался быстрее:
JoyMultiplier = 0.30

; У аналогов относительно их центров, в рамках этого скрипта, есть зона несрабатывания, за которое
; отвечает данное значение. Для идеально откалиброванных аналогов это значение будет 1, но такая
; точность не будет нужна даже таким. Ищите JoystickTest.ahk на github для теста вашего джоя.
; Ну а по поводу самодвижущейся мышки из-за не совсем в центр возвращающихся аналогов -
; повышать это значение, и сравнения больше-меньше у JoyX/JoyY/JoyU/JoyR.
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

; Хранить значение времени в моменте при запуске скрипта.
;PresentTime := A_TickCount
; - но не здесь, т.к. оно должно обновляться. Эта переменная участвует в коде касательно уклонений в бою.
FutureCame = 0
HalfSecPassed := true

; Что до этой переменной, оно есть попытка угадывать соответствия центра координат, вокруг которого
; кружит мышка левого аналога, относительно наличия панелей на экране.
SidePanel = 1 ; 1,12,13 - Правая+Нижняя панели ,, 0 - Без панелей ,, 2,3 - Только правая панель

total_width = 0
total_height = 0

; На случай если у вас не один джойстик, задайте какой по счёту инициализации в системе использовать.
JoystickNumber = 1

#SingleInstance

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
; Я скопипастил код касательно преобразования JoytoMouse :p Не особо дались моему пониманию для чего
; нужно Delta, и каким образом можно повлиять на плавность движения мышки... Ну и соответствующие
; вычисления оставил как есть без правки.

#Persistent
SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick. Так для того и скрипт.

return  ; return для SetTimer'а.

; Некоторые умники могут вякнуть, мол, ачё KeyWait не использовал, нафига столько копирующих
; KeyWait функционал переменных?! - вот для таких ответ, что с KeyWait работа AutoHotKey
; ловит сама себя в ловушку ожидания нажатия кнопки, где функционируют не все кнопки пока "не отпустит".

WatchJoystick:
IfWinActive, Revenant
{
	; Хранить значение времени в моменте при запуске скрипта
	PresentTime := A_TickCount
	if total_width = 0
		WinGetPos,,, total_width, total_height, A
	MouseNeedsToBeMoved := false ; Сбрасывать каждый раз.
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
		if LastWasRightAxis ; Использовать правый аналог как мышку
		{
			SetMouseDelay, -1  ; Makes (каким-то образом) movement smoother.
			MouseMove, DeltaX * JoyMultiplier, DeltaY * JoyMultiplier, 0, R
		}
		else ; Использовать левый аналог как мышку, кружащуюся вокруг персонажа
		{
			if ( PresentTime > FutureCame ) && !HalfSecPassed
			{
				RightMouseButtonClicked := false
				HalfSecPassed := true
			}				
			if !RStickIsMoved && ((JoyU < 46) || (JoyU > 54)|| (JoyR < 46) || (JoyR > 54))
			; Но в приоритете будем проверять, а не двигаем ли также и правый аналог.
			; Движение правым аналогом наряда с движением левого спровацирует кувырок уклонения
			; в соответствующее наклону правого аналога направление.
			{
; Что здесь ниже закомментировано, это формула вычисления угла сегмента окружности. Загуглите если
; есть желание понимать о чём идёт речь. Представьте горизонтальную и вертикальную оси аналогового
; стика джоя (конкретно в этой части кода, правого аналога) как соответствующие оси X и Y декардовой
; системы координат. AutoHotKey выдаёт оси правого аналога сл. образом - JoyU идёт слева направо
; с 0 до 100, и JoyR идёт сверху вниз с 0 до 100. Оси U и R пересекаются в точке (50, 50), и касательно
; переобпределения на декардовы стандарты, ось R получается что инвертирована.
; Формула выдаёт результат угла AOB, который принадлежит окружности, где точки A и B лежат на
; окружности и точка O есть центр этой окружности (центр правого аналога, ндэ?..)
; В декардовых стандартах показания AutoHotKey относительно правого аналога будут принимать:
; A (-50, 0)
; O (0, 0)
; B(JoyU - 50, (-1)*(JoyR - 50))
; - вот такие значения. Точка B это положение правого аналога в момент его движения в ту или иную сторону,
; и заметьте, что здесь присутствует (-1), что необходимо при переопределении инвертированной оси R
; в декардову систему.
;				if JoyR > 50
;					AnglePrev := 360 - ACos(((-50)*(JoyU - 50)) / (50*Sqrt((JoyU ** 2) - 100*JoyU + 5000 - 100*JoyR + (JoyR ** 2)))) * 180 / 3.141592653589793
;				else
;					AnglePrev := ACos(((-50)*(JoyU - 50)) / (50*Sqrt((JoyU ** 2) - 100*JoyU + 5000 - 100*JoyR + (JoyR ** 2)))) * 180 / 3.141592653589793
; Как бы то ни было, там, где я нашёл эту формулу, говорилось, что это для случая, когда точки A и B
; угла AOB лежат НА ОКРУЖНОСТИ, из чего можно сделать вывод, что длины отрезков OA и OB одинаковы, что
; в большинство положений аналога будет не верно.
; В последствии, с тем жевышеупомянутым переопределением на декардову систему координат, я воспользовался
; иной формулой с арктангенсами. Но арктангенсы они арктангенсы и есть, нуля не касаются, график не
; единое целое, так что его значения нужно чуть подправить относительно случая где будет находиться
; точка O - в какой из четырёх зон декардовых осей. Ну и на ноль делить низя.
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
; А в итоге, обе формулы выдают одинаковый результат :p каким-то макаром... Главное что? - что оно
; работает. Раскомментируйте tooltip вон внизу и 4 строчки кода формулы у Angle наверху, и убедитесь.
; Если интересно.
;					ToolTip, %Angle%%a_space%%AnglePrev%%a_space%%JoyU%%a_space%%JoyR%
				if GetKeyState("RButton")
				{
					MouseClick, right,,, 1, 0, U  ; Перестать нажимать пр.кн. мыши...
					FutureCame := PresentTime + 500 ; ...на полсекунды, прерыванием, чисто на кувырочек ;p...
					HalfSecPassed := false ; ...но после кувырка, давай продолжай соображать жмётся ли R2 чтоб дальше жать пр.кн.мыши.
				}
			; НООО }:[ в движке или где ли тут баг... Диагональные кувырки-уклонения неработают. Вместо
			; настроченного и закомментированного кода для 8 направлений кувырков используются лишь
			; четыре :/ И более того, с автонаведением на врага и когда перс смотрит в сторону врага,
			; есть проблемы с кувырком в сторону, 'перпендикулярной' тому, куда смотрит персонаж, и в
			; такие моменты работают только кувырки вперёд и назад T_T
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
			else ; если правый аналог по центрам, будем (продолжать) вращать курсор вокруг
				 ; относительно персонажа.
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
		MouseClick, left,,, 1, 0, D  ; Зажать лев.кн.мыши.
	}
	else if LeftMouseButtonClicked && (JoyZ <= 60)
	{
		LeftMouseButtonClicked := false
		MouseClick, Left,,, 1, 0, U  ; Отпустить лев.кн.мыши.
	}
		if !RightMouseButtonClicked && (JoyZ < 40)
	{
		RightMouseButtonClicked := true
		MouseClick, right,,, 1, 0, D  ; Зажать пр.кн.мыши.
	}
	else if RightMouseButtonClicked && (JoyZ >= 40)
	{
		RightMouseButtonClicked := false
		MouseClick, right,,, 1, 0, U  ; Отпустить пр.кн.мыши.
	}
	If JoyPOV = 27000 ;Стрелка влево
	{
		If ( !LArrowIsPressed )
		{
			LArrowIsPressed := true
; нажимайте комбо кнопок L1+Влево когда на экране нет панелей. Это сбросит переменную
; SidePanel на ноль, что наладит логику кода, пытающегося предугадать координаты центра,
; в котором находится персонаж, и вокруг которого вращается мышка на левый аналог.
			if GetKeyState(JoystickNumber . "Joy5")
				if GetKeyState(JoystickNumber . "Joy6")
; нажимайте L1+R1+Left в случае, если при запуске игры с запущенным этим скриптом
; положение центра курсора для левого аналога определяется "ну вообще не там" -
; бывает ошибочно вычисляется разрешением рабочего стала - пересчитает размер
; с разрешением игрового экрана.
					WinGetPos,,, total_width, total_height, A
				else
					SidePanel = 0
			else ; просто нажатие на стрелочку влево нажмёт пробел.
			{
				Send, {Space} ; Full Screen гор.клавиша
				if SidePanel != 0
					SidePanel = 0
				else
					SidePanel = 1
			}
		}
	}
	else If JoyPOV = 18000 ;Стрелка вниз
	{
		If ( !DArrowIsPressed )
		{
		; Toggle map/inventory.
			DArrowIsPressed := true
			if (SidePanel = 0) || (SidePanel = 3)
			{
				Send, {6} ;Карты гор.клавиша
				SidePanel = 2
			}
			else if (SidePanel = 1) || (SidePanel = 13)
			{
				Send, {6}
				SidePanel = 12
			}
			else if SidePanel = 2
			{
				Send, {5} ;Инвентаря гор.клавиша
				SidePanel = 3
			}
			else if SidePanel = 12
			{
				Send, {5} ;Откроет инвентарь при обоих панелях, предполагая, что до этого была открыта карта
				SidePanel = 13
			}
		}
	}
;	else If JoyPOV = 9000 ;Стрелка вправо. Используется для комбо кнопок Right+JoyButton4 - блок, и Right+JoyButton10 - режим лука.
;	{
;	}
;	else If JoyPOV = 0 ;Стрелка вверх. Используется для комбо кнопок Up+JoyButton1/2/3 - продвинутые атаки.
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
			Send {F1} ; Первого заклинания с панели гор.клавиша
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F5} ; использование первого предмета с панели гор.клавиша
		else if JoyPOV = 0
			Send {q} ; первой продвинутой атаки гор.клавиша - рубящий удар с последующим пинком, который в большинстве случаев спровацируется на нажатие других атак, закреплённых за клавишами q/a/s/d
		else
			Send {a} ; Режущей атаки гор.клавиша
		Joy1ButtonIsPressed := true
	}
	else if Joy1ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy1")
		Joy1ButtonIsPressed := false

	if (!Joy2ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy2")
	{
		If GetKeyState(JoystickNumber . "Joy6")
			Send {F2} ; Второго заклинания с панели гор.клавиша
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F6} ; использование второго предмета с панели гор.клавиша
		else if JoyPOV = 0
			Send {w} ; второй продвинутой атаки гор.клавиша - похожа на ту, как нажатие "d" во время ходьбы, только оно с места и более мощнее.
		else
			Send {s} ; Напористой атаки гор.клавиша
		Joy2ButtonIsPressed := true
	}
	else if Joy2ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy2")
		Joy2ButtonIsPressed := false

	if (!Joy3ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy3")
	{
		if BowMode
		{
			Send {z down} ; выстрела стрелы из лука гор.клавиша. Зажав, прицеливайтесь двигая влево-вправо левым аналогом.
			Joy3ButtonIsHolded := true
		}
		else
		{
			If GetKeyState(JoystickNumber . "Joy6")
				Send {F3} ; Третьего заклинания с панели гор.клавиша
			else If GetKeyState(JoystickNumber . "Joy7")
				Send {F7} ; использование третьего предмета с панели гор.клавиша
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
			Send {F4} ; Четвёртого заклинания с панели гор.клавиша
		else If GetKeyState(JoystickNumber . "Joy7")
			Send {F8} ; использование четвёртого предмета с панели гор.клавиша
		else if JoyPOV = 0
			Send {e} ; третей продвинутой атаки гор.клавиша - удар Дракона. В купе можно напинать комбо из пяти ударов.
		else if JoyPOV = 9000
		{
			Send {f down} ; Блока (в состоянии битвы) гор.клавиша.
			; Не сетуйте на этот скрипт если вы жмёте, а блок не рабит - опять виноват движок игры...
			; А вообще, вот враги делают анимацию блока, пытаются блокировать ваши атаки, а никогда
			; у них не получается, и никто из них не жалуется... Потому как никто не выживает...
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
		Send {r down} ; Бега гор.клавиша
		Joy5ButtonIsHolded := true
	}
	else if Joy5ButtonIsHolded && !GetKeyState(JoystickNumber . "Joy5")
	{
		Send {r up}
		Joy5ButtonIsHolded := false
	}

	if (!Joy8ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy8")
	{
		Send {Esc} ; Игрового меню гор.клавиша
		Joy8ButtonIsPressed := true
	}
	else if Joy8ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy8")
		Joy8ButtonIsPressed := false

	if (!Joy9ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy9")
	{
		Send {g} ; Поднятия предмета (дропа) гор.клавиша
		Joy9ButtonIsPressed := true
	}
	else if Joy9ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy9")
		Joy9ButtonIsPressed := false

	if (!Joy10ButtonIsPressed) && GetKeyState(JoystickNumber . "Joy10")
	{
		If GetKeyState(JoystickNumber . "Joy7")
			Send {F9} ; использование пятого предмета с панели гор.клавиша. Не особо удобное комбо кнопок XD
		else If JoyPOV = 9000
		{
			Send {x} ; Переключение между режимом лука и мирным режимом
			if !BowMode
				BowMode := true
			else if BowMode
				BowMode := false
		}
		else
		{
			Send {c} ; Переключение между режимом боя и мирным режимом
			if BowMode
				BowMode := false
		}
			
		Joy10ButtonIsPressed := true
	}
	else if Joy10ButtonIsPressed && !GetKeyState(JoystickNumber . "Joy10")
		Joy10ButtonIsPressed := false

	return
}
