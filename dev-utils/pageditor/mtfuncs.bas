' General functions I use everywhere.

#include once "crt.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

Function myFileExists (fn As String) As Integer
	Dim fH As Integer
	fH = FreeFile
	Open fn For Binary As #fH
	If Lof (fH) = 0 Then
		Close #fH
		Kill fn
		Return 0
	End If
	Close #fH
	Return -1
End Function

Function invertColour (c As Integer) As Integer
	invertColour = RGB (_
		255 - RGBA_R (c), _
		255 - RGBA_G (c), _
		255 - RGBA_B (c) _
	)
End Function

Function procrust (s As String, l As Integer) As String
	If Len (s) = l Then procrust = s: Exit Function
	If Len (s) > l Then procrust = Left (s, l): Exit Function
	procrust = s & Space (l - Len (s))
End Function

Function withAlpha (alpha As Integer, colour As Integer) As uInteger
	withAlpha = (colour And &H00FFFFFF) Or (alpha Shl 24)
End Function

Sub sanitizeSlashes (ByRef spec As String)
	Dim As Integer i
	For i = 1 To Len (spec)
		If Mid (spec, i, 1) = Chr (92) Then Mid (spec, i, 1) = "/"
	Next
End Sub

Function absoluteToRelative (fileSpec As String, refSpec As String) As String
	Dim As Integer i
	Dim As Integer fi
	Dim As Integer numBacks
	Dim As String res

	sanitizeSlashes fileSpec
	sanitizeSlashes refSpec

	If Right (refSpec, 1) <> "/" Then refSpec = refSpec & "/"

	' Check how much of fileSpec and refSpec are the same
	For i = 1 To Len (fileSpec)
		If i > Len (refSpec) Then Exit For
		If Mid (fileSpec, i, 1) <> Mid (refSpec, i, 1) Then Exit For
	Next i

	fi = i

	numBacks = 0
	If fi <= Len (refSpec) Then
		For i = fi To Len (refSpec)
			If Mid (refSpec, i, 1) = "/" Then numBacks = numBacks + 1
		Next i
	End If

	res = ""
	For i = 1 To numBacks
		res = res & "../"
	Next i

	res = res & Right (fileSpec, Len (fileSpec) - fi + 1)

	Return res
End Function

