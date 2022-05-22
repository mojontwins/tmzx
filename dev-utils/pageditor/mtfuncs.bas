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
