Option Explicit

Function GetColNum(ws As Worksheet, headerName As String) As Long
    Dim headerRow As Range
    Dim foundCell As Range
    Set headerRow = ws.Rows(1)
    Set foundCell = headerRow.Find(What:=headerName, LookIn:=xlValues, LookAt:=xlWhole, MatchCase:=False)
    If Not foundCell Is Nothing Then
        GetColNum = foundCell.Column
    Else
        GetColNum = 0
    End If
End Function

Function FormatMonthText(dt As Date) As String
    FormatMonthText = Format(dt, "mmm-yyyy")
End Function

Function GenerateStudentID() As String
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim maxNum As Long
    Dim cell As Range
    Dim cellValue As String
    Dim numPart As Long
    
    Set ws = Worksheets("Students")
    lastRow = ws.Cells(ws.Rows.Count, GetColNum(ws, "StudentID")).End(xlUp).Row
    
    maxNum = 0
    If lastRow > 1 Then
        For Each cell In ws.Range(ws.Cells(2, GetColNum(ws, "StudentID")), ws.Cells(lastRow, GetColNum(ws, "StudentID")))
            cellValue = Trim(cell.Value)
            If Left(cellValue, 1) = "S" Then
                numPart = Val(Mid(cellValue, 2))
                If numPart > maxNum Then maxNum = numPart
            End If
        Next cell
    End If
    
    GenerateStudentID = "S" & Format(maxNum + 1, "0000")
End Function

Function GenerateTransID() As String
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim maxNum As Long
    Dim cell As Range
    Dim cellValue As String
    Dim numPart As Long
    
    Set ws = Worksheets("Transactions")
    lastRow = ws.Cells(ws.Rows.Count, GetColNum(ws, "TransID")).End(xlUp).Row
    
    maxNum = 0
    If lastRow > 1 Then
        For Each cell In ws.Range(ws.Cells(2, GetColNum(ws, "TransID")), ws.Cells(lastRow, GetColNum(ws, "TransID")))
            cellValue = Trim(cell.Value)
            If Left(cellValue, 1) = "T" Then
                numPart = Val(Mid(cellValue, 2))
                If numPart > maxNum Then maxNum = numPart
            End If
        Next cell
    End If
    
    GenerateTransID = "T" & Format(maxNum + 1, "0000")
End Function

Function GetStartOfMonth(monthText As String) As Date
    Dim parts() As String
    parts = Split(monthText, "-")
    If UBound(parts) = 1 Then
        GetStartOfMonth = DateSerial(Val(parts(1)), Month("1 " & parts(0) & " 2000"), 1)
    Else
        GetStartOfMonth = DateSerial(Year(Date), Month(Date), 1)
    End If
End Function

Function GetEndOfMonth(monthText As String) As Date
    Dim startDate As Date
    startDate = GetStartOfMonth(monthText)
    GetEndOfMonth = DateSerial(Year(startDate), Month(startDate) + 1, 0)
End Function

