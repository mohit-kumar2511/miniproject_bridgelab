Option Explicit

Sub GenerateReceiptByTransID(TransID As String, Optional savePDF As Boolean = False)
    Dim wsReceipt As Worksheet
    Dim wsTrans As Worksheet
    Dim wsStudents As Worksheet
    Dim wsSettings As Worksheet
    Dim transRow As Long
    Dim studentID As String
    Dim studentRow As Long
    Dim transIDCol As Long, dateCol As Long, studentIDCol As Long, amountCol As Long, monthCol As Long
    Dim idCol As Long, nameCol As Long, fatherCol As Long, mobileCol As Long, planCol As Long, expiryCol As Long
    Dim libraryName As String
    Dim logoPath As String
    Dim placeholderPath As String
    Dim receiptShape As Shape
    Dim photoPath As String
    Dim oldExpiry As Date
    Dim newExpiry As Date
    
    Set wsReceipt = Worksheets("ReceiptTemplate")
    Set wsTrans = Worksheets("Transactions")
    Set wsStudents = Worksheets("Students")
    Set wsSettings = Worksheets("Settings")
    
    transIDCol = GetColNum(wsTrans, "TransID")
    dateCol = GetColNum(wsTrans, "Date")
    studentIDCol = GetColNum(wsTrans, "StudentID")
    amountCol = GetColNum(wsTrans, "Amount")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    
    transRow = FindTransactionRow(TransID)
    If transRow = 0 Then Exit Sub
    
    studentID = wsTrans.Cells(transRow, studentIDCol).Value
    studentRow = FindStudentRow(studentID)
    If studentRow = 0 Then Exit Sub
    
    idCol = GetColNum(wsStudents, "StudentID")
    nameCol = GetColNum(wsStudents, "Name")
    fatherCol = GetColNum(wsStudents, "FatherName")
    mobileCol = GetColNum(wsStudents, "Mobile")
    planCol = GetColNum(wsStudents, "Plan")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    
    libraryName = wsSettings.Range("B1").Value
    logoPath = wsSettings.Range("B2").Value
    placeholderPath = wsSettings.Range("B3").Value
    
    oldExpiry = CalculateOldExpiryBeforePayment(studentID, TransID)
    newExpiry = wsStudents.Cells(studentRow, expiryCol).Value
    
    wsReceipt.Range("B2").Value = libraryName
    
    On Error Resume Next
    Set receiptShape = wsReceipt.Shapes("LogoImage")
    If receiptShape Is Nothing Then
        Set receiptShape = wsReceipt.Shapes.AddPicture(logoPath, msoFalse, msoTrue, wsReceipt.Range("B3").Left, wsReceipt.Range("B3").Top, 100, 100)
        receiptShape.Name = "LogoImage"
    End If
    On Error GoTo 0
    
    wsReceipt.Range("B5").Value = wsStudents.Cells(studentRow, nameCol).Value
    wsReceipt.Range("B6").Value = wsStudents.Cells(studentRow, fatherCol).Value
    wsReceipt.Range("B7").Value = wsStudents.Cells(studentRow, mobileCol).Value
    wsReceipt.Range("B8").Value = studentID
    wsReceipt.Range("B9").Value = wsStudents.Cells(studentRow, planCol).Value
    wsReceipt.Range("B10").Value = oldExpiry
    wsReceipt.Range("B11").Value = newExpiry
    wsReceipt.Range("B12").Value = wsTrans.Cells(transRow, monthCol).Value
    wsReceipt.Range("B13").Value = wsTrans.Cells(transRow, amountCol).Value
    wsReceipt.Range("B14").Value = TransID
    wsReceipt.Range("B15").Value = wsTrans.Cells(transRow, dateCol).Value
    
    photoPath = wsStudents.Cells(studentRow, GetColNum(wsStudents, "PhotoPath")).Value
    If Trim(photoPath) = "" Then photoPath = placeholderPath
    
    On Error Resume Next
    Set receiptShape = wsReceipt.Shapes("StudentPhoto")
    If Not receiptShape Is Nothing Then receiptShape.Delete
    Set receiptShape = wsReceipt.Shapes.AddPicture(photoPath, msoFalse, msoTrue, wsReceipt.Range("D5").Left, wsReceipt.Range("D5").Top, 80, 80)
    receiptShape.Name = "StudentPhoto"
    On Error GoTo 0
    
    If savePDF Then
        Dim pdfName As String
        pdfName = Replace(libraryName, " ", "_") & "_" & studentID & "_" & Replace(wsTrans.Cells(transRow, monthCol).Value, "-", "_") & "_" & TransID & ".pdf"
        wsReceipt.ExportAsFixedFormat Type:=xlTypePDF, Filename:=ThisWorkbook.Path & "\" & pdfName, Quality:=xlQualityStandard, IncludeDocProperties:=True, IgnorePrintAreas:=False, OpenAfterPublish:=False
    End If
End Sub

Function FindTransactionRow(TransID As String) As Long
    Dim wsTrans As Worksheet
    Dim transIDCol As Long
    Dim lastRow As Long
    Dim i As Long
    
    Set wsTrans = Worksheets("Transactions")
    transIDCol = GetColNum(wsTrans, "TransID")
    lastRow = wsTrans.Cells(wsTrans.Rows.Count, transIDCol).End(xlUp).Row
    
    For i = 2 To lastRow
        If Trim(wsTrans.Cells(i, transIDCol).Value) = TransID Then
            FindTransactionRow = i
            Exit Function
        End If
    Next i
    
    FindTransactionRow = 0
End Function

Function CalculateOldExpiryBeforePayment(studentID As String, excludeTransID As String) As Date
    Dim wsTrans As Worksheet
    Dim studentIDCol As Long
    Dim monthCol As Long
    Dim transIDCol As Long
    Dim dateCol As Long
    Dim lastRow As Long
    Dim i As Long
    Dim lastTransDate As Date
    Dim lastTransMonth As String
    
    Set wsTrans = Worksheets("Transactions")
    
    studentIDCol = GetColNum(wsTrans, "StudentID")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    transIDCol = GetColNum(wsTrans, "TransID")
    dateCol = GetColNum(wsTrans, "Date")
    
    lastRow = wsTrans.Cells(wsTrans.Rows.Count, transIDCol).End(xlUp).Row
    lastTransDate = DateSerial(1900, 1, 1)
    lastTransMonth = ""
    
    For i = 2 To lastRow
        If Trim(wsTrans.Cells(i, studentIDCol).Value) = studentID Then
            If Trim(wsTrans.Cells(i, transIDCol).Value) <> excludeTransID Then
                If IsDate(wsTrans.Cells(i, dateCol).Value) Then
                    If CDate(wsTrans.Cells(i, dateCol).Value) > lastTransDate Then
                        lastTransDate = CDate(wsTrans.Cells(i, dateCol).Value)
                        lastTransMonth = wsTrans.Cells(i, monthCol).Value
                    End If
                End If
            End If
        End If
    Next i
    
    If lastTransMonth <> "" Then
        CalculateOldExpiryBeforePayment = GetEndOfMonth(lastTransMonth)
    Else
        CalculateOldExpiryBeforePayment = DateSerial(1900, 1, 1)
    End If
End Function

