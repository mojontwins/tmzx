' pageditor.bas
' creates pages

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

#include "file.bi"
#include "fbpng.bi"
#include "fbgfx.bi"
#include once "crt.bi"

#include "cmdlineparser.bi"
#include "mtparser.bi"
#include "gui.bi"
#include "keycodes.bi"
#include "mtfuncs.bi"

Const MODE_TEXT = 0
Const MODE_DRAW = 1
Const MODE_EDITING = 2

Type TypeCell
	charNum As uByte
	attr As uByte
	ink As uByte
	paper As uByte
	extra As uByte
End Type

Dim Shared As TypeCell fullScreen (21, 31) 
Dim Shared As Any Ptr fullFont (7, 7, 95)
Dim Shared As Double lastT
Dim Shared As Integer flipFlop
Dim Shared As Any Ptr whiteCell
Dim Shared As Any Ptr curCell
Dim Shared As Any Ptr gridCell

Dim Shared As Integer speccyColours (7) = { _
	&HFF000000, _
	&HFF0000CC, _
	&HFFCC0000, _
	&HFFCC00CC, _
	&HFF00CC00, _
	&HFF00CCCC, _
	&HFFCCCC00, _
	&HFFCCCCCC _
}

Sub savePage (fOut As Integer)
	Put #fOut, , fullScreen ()
End Sub

Sub loadPage (fIn As Integer)
	Get #fIn, , fullScreen ()
End Sub

Sub usage ()
	Puts "$ pageditor.exe page=NNN"
	Puts "Will create new if page NNN does not exist, edit it otherwise."
End Sub

Sub loadBinFontAndPaint (img As Any Ptr, yOf As Integer, c1 As Integer, c2 As Integer)
	Dim As Integer f, x, y, xx, yy, n, c
	Dim As uByte d 

	y = yOf: x = 0
	f = FreeFile
	Open "spectrum.bin" For Binary As #f
	For n = 0 To 95
		For yy = 0 To 7
			Get #f, , d
			For xx = 0 To 7
				If (d And (2^(7-xx))) Then c = speccyColours (c1) Else c = speccyColours (c2)
				Line img, (2*(x+xx),2*(y+yy))-(1+2*(x+xx),1+2*(y+yy)),c,b
			Next xx
		Next yy
		x = x + 8
	Next n
	Close f
End Sub

Sub fastFontCreate
	Dim As Any Ptr workEre
	Dim As Integer c1, c2, n

	workEre = ImageCreate (768*2, 16, RGB (0, 0, 0))

	For c2 = 0 To 7
		For c1 = 0 To 7
			loadBinFontAndPaint workEre, 0, c1, c2
			For n = 0 To 95
				fullFont (c1, c2, n) = ImageCreate (16, 16, RGB (0,0,0))
				Get workEre, (n*16, 0) - (15+n*16, 15), fullFont (c1, c2, n) 
			Next n
		Next c1
	Next c2

	ImageDestroy workEre
End Sub

Sub fastFontDelete
	Dim As Integer c1, c2, n
	For c2 = 0 To 7
		For c1 = 0 To 7
			For n = 0 To 95
				ImageDestroy fullFont (c1, c2, n)
			Next n
		Next c1
	Next c2
End Sub

Sub fillrand 
	Dim As Integer y, x

	For y = 0 To 21
		For x = 0 To 31
			fullScreen (y, x).ink = Int (Rnd * 8)
			fullScreen (y, x).paper = Int (Rnd * 8)
			fullScreen (y, x).charNum = Int (Rnd * 16) + 128
	Next x, y
End Sub

Sub draw2x2BinaryBlock (x As Integer, y As Integer, c1 As Integer, c2 As Integer, pattern As Integer)
	Dim As Integer c
	If pattern And 1 Then c = speccyColours (c1) Else c = speccyColours (c2)
	Line (x + 8, y) - (x + 15, y + 7), c, BF 
	If pattern And 2 Then c = speccyColours (c1) Else c = speccyColours (c2)
	Line (x, y) - (x + 7, y + 7), c, BF
	If pattern And 4 Then c = speccyColours (c1) Else c = speccyColours (c2)
	Line (x + 8, y + 8) - (x + 15, y + 15), c, BF
	If pattern And 8 Then c = speccyColours (c1) Else c = speccyColours (c2)
	Line (x, y + 8) - (x + 7, y + 15), c, BF   
End Sub

Sub drawCell (x As Integer, y As Integer)
	Dim As uByte d
	d = fullScreen (y, x).charNum
	If d >= 32 And d < 128 Then
		d = d - 32
		Put (x*16, y*16), fullFont (fullScreen (y, x).ink, fullScreen (y, x).paper, d), Pset
	ElseIf d >= 128 And d < 144 Then
		d = d - 128
		draw2x2BinaryBlock x*16, y*16, fullScreen (y, x).ink, fullScreen (y, x).paper, d
	End If
End Sub

Sub drawCellGrid (x As Integer, y As Integer)
	Put (16*x, 16*y), gridCell, ALPHA
End Sub

Sub fullScreenBlit
	Dim As Integer y, x
	Dim As uByte d
	For y = 0 To 21
		For x = 0 To 31
			drawCell x, y
		Next x
	Next y
End Sub

Sub initFullScreen
	Dim As Integer y, x
	For y = 0 To 21
		For x = 0 To 31
			fullScreen (y, x).ink = 7
			fullScreen (y, x).paper = 0
			fullScreen (y, x).charNum = 32
	Next x, y
End Sub

Sub overlayGrid
	Dim As Any Ptr cell 
	Dim As Integer y, x
	For y = 0 To 21
		For x = 0 To 31
			Put (16*x, 16*y), gridCell, ALPHA
		Next x
	Next y
End Sub

Sub addPixelToCell (x As Integer, y As Integer, cN As Integer)
	Dim As Integer cellX, cellY, pixelX, pixelY, xx, yy
	Dim As Integer virtCell (1,1)
	Dim As Integer c1, c2, i, cM, f
	Dim As Integer freqs (7)
	Dim As uByte d
	
	' First, get cell and pixel coordinates
	cellX = x\2
	cellY = y\2
	pixelX = x And 1
	pixelY = y And 1

	' Now compose a virtual cell from the existing cell
	d = fullScreen (cellY, cellX).charNum

	If d < 128 Then d = 0 Else d = d - 128

	c1 = fullScreen (cellY, cellX).ink
	c2 = fullScreen (cellY, cellX).paper

	If d And 1 Then virtCell (0,1) = c1 Else virtCell (0,1)= c2
	If d And 2 Then virtCell (0,0) = c1 Else virtCell (0,0)= c2
	If d And 4 Then virtCell (1,1) = c1 Else virtCell (1,1)= c2
	If d And 8 Then virtCell (1,0) = c1 Else virtCell (1,0)= c2

	' Paint new pixel
	virtCell (pixelY, pixelX) = cN

	' Find the most used colour for colour 2
	For i = 0 To 7: freqs (i) = 0: Next i

	For yy = 0 To 1: For xx = 0 To 1
		If virtCell (yy,xx) <> cN Then freqs (virtCell (yy, xx)) = freqs (virtCell (yy	, xx)) + 1
	Next xx, yy

	cM = 0: f = freqs (cN)
	For i = 1 To 7
		If freqs (i) > f Then cM = i: f = freqs (cM)
	Next i

	' Make sure cN >= cM
	If cM < cN Then Swap cM, cN

	' Encode new char.
	fullScreen (cellY, cellX).ink = cN
	fullScreen (cellY, cellX).paper = cM

	d = 0
	If virtCell (0, 1) = cN then d = d Or 1
	If virtCell (0, 0) = cN Then d = d Or 2
	If virtCell (1, 1) = cN Then d = d Or 4
	If virtCell (1, 0) = cN Then d = d Or 8

	fullScreen (cellY, cellX).charNum = 128 + d
End Sub

Sub colorPalette (c1 As Integer, c2 As Integer)
	Dim As Integer i
	For i = 0 To 7
		Line (256+16*i, 8+352)-(15+256+16*i, 8+383), speccyColours (i), bf
		Line (256+16*i, 8+352)-(256+16*i, 8+383), 64
		Line (256+16*i, 8+352)-(15+256+16*i, 8+352), 64
		Line (256+16*i, 8+368)-(15+256+16*i, 8+368), 64
		If c1 = i Then 
			Line (256+16*i+2, 8+354)-(256+16*i+13, 8+365), RGB (127,127,127), B
		End If
		If c2 = i Then 
			Line (256+16*i+2, 8+354+16)-(256+16*i+13, 8+365+16), RGB (127,127,127), B
		End If
	Next i
End Sub

Sub removeMainButtons
	Line (0, 384-16-8)-(255, 399), RGB (127,127,127), BF
End Sub

Function dialogYesNo (caption As String) As Integer
	Dim As Integer res 
	Dim As Integer x0, y0
	Dim As Button buttonYes
	Dim As Button buttonNo
	Dim As Any Ptr rvrtimg

	rvrtimg = ImageCreate (512, 48, 0)
	Get (0,352)-(511, 399), rvrtimg

	While (MultiKey (1) Or Window_Event_close): Wend

	res = 0
	removeMainButtons

	x0 = 512 \ 2 - 90
	y0 = 400 \ 2 - 28

	Line (x0, y0)-(x0 + 179, y0 + 55), RGBA (127,127,127,127), BF 
	Line (x0, y0)-(x0 + 179, y0 + 55), 0, B

	Var Label_a =	Label_New	(x0 + 8, y0 + 8, 18*8, 20, caption, black, RGB (127,127,127))
	buttonYes = 	Button_New	(x0 + 8, y0 + 8 + 20, 112, 20, "Seguro, Paco")
	buttonNo = 		Button_New 	(x0 + 8 + 112 + 4, y0 + 8 + 20, 48, 20, "Huy!")

	Do
		If Button_Event (buttonYes) Then	res = -1: Exit Do
		If Button_Event (buttonNo) Then 	res = 0: Exit Do
		If Window_Event_Close Then 			res = -1: Exit Do
		If MultiKey (1) Then 				res = 0: Exit Do
		If MultiKey (SC_ENTER) Then			res = -1: Exit Do
	Loop

	While (MultiKey (1) Or Window_Event_close): Wend

	Put (0,352), rvrtimg, PSET
	ImageDestroy rvrtimg

	Return res
End Function

Sub ShowCursor (x As Integer, y As Integer)
	If Timer - lastT >= 0.5 Then
		flipFlop = 1 - flipFlop
		lastT = Timer
		drawCell (x, y)

		If flipFlop = 1 Then
			Put (16*x, 16*y), whiteCell, Xor
		End If
	End If
End Sub

Sub editOrNew 
	Dim As Integer fIn
	fIn = FreeFile
	Open sclpGetValue ("page") & ".ttx" For Binary As #fIn
	If Lof (fIn) = 0 Then
		Close #fIn
		Kill sclpGetValue ("page") & ".ttx"
		initFullScreen
	Else
		loadPage fIn
		Close #fIn
	End If
End Sub

Dim As Integer editX, editY
Dim As Integer mainC1, mainC2
Dim As Integer mode, oldmode
Dim As Integer mx, my, mbtn, pbtn, x, y, i, kc, initX
Dim As Integer oldx, oldy
Dim As Integer fOut
Dim As String k, pageName
Dim As String mandatory (0) = { "page" }

' Buttons
Dim As Button buttonSave
Dim As Button buttonRevert
Dim As Button buttonClear
Dim As Button buttonExit

Dim As Button buttonDraw
Dim As Button buttonText

sclpParseAttrs
If Not (sclpCheck (mandatory ())) Then 
	usage
	End
End If

pageName = sclpGetValue ("page")

If Len (pageName) <> 3 Or Val (pageName) < 100 Or Val (pageName) > 999 Then
	usage
	End
End If

OpenWindow 512, 400, "Mojon Twins' PagEditor"

buttonSave = Button_New (8, 384 - 8, 48, 16, "Save")
buttonRevert = Button_New (8+48, 384 - 8, 64, 16, "Revert")
buttonClear = Button_new (8+48+64, 384 - 8, 56, 16, "Clear")
buttonExit = Button_New (8+48+64+56, 384 - 8, 48, 16, "Exit")

buttonDraw = Button_New (8, 384-16-8, 48, 16, "Draw")
buttonText = Button_New (8+48, 384-16-8, 48, 16, "Text")

whiteCell = ImageCreate (16, 16, RGB(255,255,255))
curCell = ImageCreate (16, 16)
gridCell = ImageCreate (16, 16, RGBA (0,0,0,0))
Line gridCell, (0,0)-(15,0), RGBA (127, 127, 127, 127)
Line gridCell, (0,0)-(0,15), RGBA (127, 127, 127, 127)
	
fastFontCreate

editOrNew
fullScreenBlit
overlayGrid
colorPalette 7,0

editX = 0: editY = 0
mainC1 = 7: MainC2 = 0
lastT = Timer
flipFlop = 0

mode = MODE_TEXT
oldmode = &HFF

Do
	pbtn = mbtn
	Getmouse mx, my, , mbtn
	pbtn = (pbtn XOR mbtn) AND mbtn

	If my > 352+8 And (pbtn And 1) And mx >= 256 And mx < 384 Then
		If my >= 8+352 And my < 8+352+16 Then mainC1 = (mx-256)\16
		If my >= 8+352+16 And my < 8+352+32 Then mainC2 = (mx-256)\16
		colorPalette mainC1, mainC2
	End If

	If oldmode <> mode Then
		Line (256+128+16,352+16)-(256+128+16+31,352+16+15), RGB (127,127,127), BF
		Select Case mode
			Case MODE_TEXT
				Draw String (256+128+16,352+16), "TEXT", RGB (255,0,0)
			Case MODE_DRAW
				Draw String (256+128+16,352+16), "DRAW", RGB (255,0,0)
		End Select
		oldmode = mode
	End If

	If mode = MODE_EDITING Then
		ShowCursor editX, editY
		k = Inkey
		If k <> "" Then 
			kc = Asc (k)
			If kc >= 32 And kc < 128 Then
				fullScreen (editY, editX).ink = mainC1
				fullScreen (editY, editX).paper = mainC2
				fullScreen (editY, editX).charNum = Asc (k)
				drawCell editX, editY
				drawCellGrid editX, editY
				editX = editX + 1
				If editX = 32 Then
					editX = 0
					editY = editY + 1
					If editY = 22 Then editY = 0
				End If
			End If
		End If

		If k = Chr (13) Then
			If editY < 21 Then
				drawCell editX, editY
				drawCellGrid editX, editY
				editX = initX
				editY = editY + 1
			End If
		End If

		If k = Chr (8) Then
			If editX > initX Then 
				fullScreen (editY, editX).charNum = 32
				drawCell editX, editY
				drawCellGrid editX, editY
				editX = editX - 1
			End If
		End If

		If Len (k) > 1 Then
			x = editX: y = editY
			Select Case Asc (Mid (k, 2, 1))
				Case 72:
					editY = editY - 1: If editY < 0 Then editY = 21
				Case 75:
					editX = editX - 1: If editX < 0 Then editX = 31
				Case 77:
					editX = editX + 1: If editX > 31 Then editX = 0
				Case 80:
					editY = editY + 1: If editY > 21 Then editY = 0
			End Select 
			If x <> editX Or y <> editY Then
				drawCell x, y
				drawCellGrid x, y
			End If
		End If

		If k = Chr(27) Then mode = MODE_TEXT

		' Inside editing area?
		If mx >= 0 And mx < 512 And my > 0 And my < 352 Then
			If pbtn And 1 Then
				x = mx \ 16
				y = my \ 16
				drawCell editX, editY
				drawCellGrid editX, editY
				editX = x: initX = x
				editY = y
				mode = MODE_EDITING
			End If
		End If

	Else

		' Inside editing area?
		If mx >= 0 And mx < 512 And my > 0 And my < 352 Then
			If mode = MODE_TEXT Then
				x = mx \ 16
				y = my \ 16

				If pbtn And 1 Then
					drawCell editX, editY
					drawCellGrid editX, editY
					editX = x: initX = x
					editY = y
					mode = MODE_EDITING
				End If
			Else
				If mbtn And 1 Then
					x = mx \ 8
					y = my \ 8
					addPixelToCell x, y, MainC1
					drawCell x\2, y\2
					drawCellGrid x\2, y\2
				End If
				If mbtn And 2 Then
					x = mx \ 8
					y = my \ 8
					addPixelToCell x, y, MainC2
					drawCell x\2, y\2
					drawCellGrid x\2, y\2
				End If
			End If
		End If

	End If

	If Button_Event (buttonDraw) Then
		drawCell editX, editY
		drawCellGrid editX, editY
		mode = MODE_DRAW
	End If

	If Button_Event (buttonText) Then
		mode = MODE_TEXT
	End If

	If Button_Event (buttonSave) Then
		Kill sclpGetValue ("page") & ".ttx"
		fOut = FreeFile
		Open sclpGetValue ("page") & ".ttx" For Binary As #fOut
		savePage fOut
		Close #fOut
	End If

	If Button_Event (buttonRevert) Then
		If dialogYesNo ("Recargar, Seguro?") Then
			editOrNew
			fullScreenBlit
			overlayGrid
		End If
	End If

	If Button_Event (buttonClear) Then
		If dialogYesNo ("Borrar todo, Seguro?") Then
			initFullScreen
			fullScreenBlit
			overlayGrid
		End if
	End If

	If Button_Event (buttonExit) Then
		If dialogYesNo ("Seguro que quieres salir?") Then Exit Do 
		fullScreenBlit
		overlayGrid
	End If	
Loop

fastFontDelete
ImageDestroy whiteCell
ImageDestroy curCell
ImageDestroy gridCell
