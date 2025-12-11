Option Explicit

Sub RunValidationAll()
    Dim wsStudents As Worksheet
    Dim lastRow As Long
    Dim i As Long
    
    Set wsStudents = Worksheets("Students")
    lastRow = wsStudents.Cells(wsStudents.Rows.Count, 1).End(xlUp).Row
    
    For i = 2 To lastRow
        ValidateStudentRow i
    Next i
End Sub

Sub ValidateStudentRow(row As Long)
    Dim wsStudents As Worksheet
    Dim nameCol As Long
    Dim fatherCol As Long
    Dim mobileCol As Long
    Dim cellValue As String
    
    Set wsStudents = Worksheets("Students")
    
    nameCol = GetColNum(wsStudents, "Name")
    fatherCol = GetColNum(wsStudents, "FatherName")
    mobileCol = GetColNum(wsStudents, "Mobile")
    
    If nameCol > 0 Then
        cellValue = wsStudents.Cells(row, nameCol).Value
        If cellValue <> "" Then
            cellValue = CleanName(cellValue)
            wsStudents.Cells(row, nameCol).Value = StrConv(cellValue, vbProperCase)
        End If
    End If
    
    If fatherCol > 0 Then
        cellValue = wsStudents.Cells(row, fatherCol).Value
        If cellValue <> "" Then
            cellValue = CleanName(cellValue)
            wsStudents.Cells(row, fatherCol).Value = StrConv(cellValue, vbProperCase)
        End If
    End If
    
    If mobileCol > 0 Then
        cellValue = wsStudents.Cells(row, mobileCol).Value
        If cellValue <> "" Then
            cellValue = CleanMobile(cellValue)
            wsStudents.Cells(row, mobileCol).Value = cellValue
            
            If Len(cellValue) > 10 Or Not IsNumeric(cellValue) Then
                wsStudents.Cells(row, mobileCol).Interior.Color = RGB(255, 255, 0)
            Else
                wsStudents.Cells(row, mobileCol).Interior.Color = xlNone
            End If
        Else
            wsStudents.Cells(row, mobileCol).Interior.Color = xlNone
        End If
    End If
End Sub

Function CleanName(text As String) As String
    Dim result As String
    Dim i As Long
    Dim char As String
    
    result = ""
    For i = 1 To Len(text)
        char = Mid(text, i, 1)
        If (Asc(char) >= 65 And Asc(char) <= 90) Or _
           (Asc(char) >= 97 And Asc(char) <= 122) Or _
           char = " " Or char = "." Or char = "-" Then
            result = result & char
        End If
    Next i
    
    CleanName = result
End Function

Function CleanMobile(text As String) As String
    Dim result As String
    Dim i As Long
    Dim char As String
    
    result = ""
    For i = 1 To Len(text)
        char = Mid(text, i, 1)
        If IsNumeric(char) Then
            result = result & char
        End If
    Next i
    
    If Len(result) > 10 Then
        result = Left(result, 10)
    End If
    
    CleanMobile = result
End Function

