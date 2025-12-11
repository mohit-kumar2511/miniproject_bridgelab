Option Explicit

Function AddPayment(studentID As String, payDate As Date, amount As Double, monthText As String, Optional source As String = "Cash") As String
    Dim wsTrans As Worksheet
    Dim wsStudents As Worksheet
    Dim lastRow As Long
    Dim transID As String
    Dim transDateCol As Long, transIDCol As Long, studentIDCol As Long
    Dim typeCol As Long, amountCol As Long, monthCol As Long, descCol As Long, sourceCol As Long
    Dim studentRow As Long
    Dim expiryCol As Long
    Dim currentExpiry As Date
    Dim monthStart As Date
    Dim newExpiry As Date
    
    Set wsTrans = Worksheets("Transactions")
    Set wsStudents = Worksheets("Students")
    
    transIDCol = GetColNum(wsTrans, "TransID")
    transDateCol = GetColNum(wsTrans, "Date")
    studentIDCol = GetColNum(wsTrans, "StudentID")
    typeCol = GetColNum(wsTrans, "Type")
    amountCol = GetColNum(wsTrans, "Amount")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    descCol = GetColNum(wsTrans, "Description")
    sourceCol = GetColNum(wsTrans, "Source")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    
    transID = GenerateTransID()
    lastRow = wsTrans.Cells(wsTrans.Rows.Count, transIDCol).End(xlUp).Row + 1
    
    wsTrans.Cells(lastRow, transIDCol).Value = transID
    wsTrans.Cells(lastRow, transDateCol).Value = payDate
    wsTrans.Cells(lastRow, studentIDCol).Value = studentID
    wsTrans.Cells(lastRow, typeCol).Value = "Income"
    wsTrans.Cells(lastRow, amountCol).Value = amount
    wsTrans.Cells(lastRow, monthCol).Value = monthText
    wsTrans.Cells(lastRow, descCol).Value = "Payment for " & monthText
    wsTrans.Cells(lastRow, sourceCol).Value = source
    
    studentRow = FindStudentRow(studentID)
    If studentRow > 0 Then
        currentExpiry = wsStudents.Cells(studentRow, expiryCol).Value
        monthStart = GetStartOfMonth(monthText)
        
        If IsDate(currentExpiry) And currentExpiry >= monthStart Then
            newExpiry = GetEndOfMonth(monthText)
            If newExpiry > currentExpiry Then
                wsStudents.Cells(studentRow, expiryCol).Value = newExpiry
            End If
        Else
            newExpiry = GetEndOfMonth(monthText)
            wsStudents.Cells(studentRow, expiryCol).Value = newExpiry
        End If
    End If
    
    AddPayment = transID
End Function

Function CreateNewStudentWithPayment(Name As String, FatherName As String, Mobile As String, Plan As String, payDate As Date, monthText As String, amount As Double) As String
    Dim wsStudents As Worksheet
    Dim wsSettings As Worksheet
    Dim lastRow As Long
    Dim studentID As String
    Dim transID As String
    Dim idCol As Long, nameCol As Long, fatherCol As Long, mobileCol As Long
    Dim genderCol As Long, admissionCol As Long, planCol As Long, expiryCol As Long
    Dim lockerCol As Long, seatCol As Long, photoCol As Long, statusCol As Long
    
    Set wsStudents = Worksheets("Students")
    Set wsSettings = Worksheets("Settings")
    
    idCol = GetColNum(wsStudents, "StudentID")
    nameCol = GetColNum(wsStudents, "Name")
    fatherCol = GetColNum(wsStudents, "FatherName")
    mobileCol = GetColNum(wsStudents, "Mobile")
    genderCol = GetColNum(wsStudents, "Gender")
    admissionCol = GetColNum(wsStudents, "AdmissionDate")
    planCol = GetColNum(wsStudents, "Plan")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    lockerCol = GetColNum(wsStudents, "Locker")
    seatCol = GetColNum(wsStudents, "FixedSeat")
    photoCol = GetColNum(wsStudents, "PhotoPath")
    statusCol = GetColNum(wsStudents, "Status")
    
    studentID = GenerateStudentID()
    lastRow = wsStudents.Cells(wsStudents.Rows.Count, idCol).End(xlUp).Row + 1
    
    wsStudents.Cells(lastRow, idCol).Value = studentID
    wsStudents.Cells(lastRow, nameCol).Value = Name
    wsStudents.Cells(lastRow, fatherCol).Value = FatherName
    wsStudents.Cells(lastRow, mobileCol).Value = Mobile
    wsStudents.Cells(lastRow, genderCol).Value = ""
    wsStudents.Cells(lastRow, admissionCol).Value = payDate
    wsStudents.Cells(lastRow, planCol).Value = Plan
    wsStudents.Cells(lastRow, expiryCol).Value = GetEndOfMonth(monthText)
    wsStudents.Cells(lastRow, lockerCol).Value = ""
    wsStudents.Cells(lastRow, seatCol).Value = ""
    wsStudents.Cells(lastRow, photoCol).Value = ""
    wsStudents.Cells(lastRow, statusCol).Value = "Active"
    
    transID = AddPayment(studentID, payDate, amount, monthText, "Cash")
    CreateNewStudentWithPayment = transID
    
    GenerateReceiptByTransID transID, False
End Function

Sub UpdateExpiry(studentID As String, newExpiryDate As Date)
    Dim wsStudents As Worksheet
    Dim studentRow As Long
    Dim expiryCol As Long
    
    Set wsStudents = Worksheets("Students")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    
    studentRow = FindStudentRow(studentID)
    If studentRow > 0 Then
        wsStudents.Cells(studentRow, expiryCol).Value = newExpiryDate
    End If
End Sub

Function FindStudentRow(studentID As String) As Long
    Dim wsStudents As Worksheet
    Dim idCol As Long
    Dim lastRow As Long
    Dim i As Long
    
    Set wsStudents = Worksheets("Students")
    idCol = GetColNum(wsStudents, "StudentID")
    lastRow = wsStudents.Cells(wsStudents.Rows.Count, idCol).End(xlUp).Row
    
    For i = 2 To lastRow
        If Trim(wsStudents.Cells(i, idCol).Value) = studentID Then
            FindStudentRow = i
            Exit Function
        End If
    Next i
    
    FindStudentRow = 0
End Function

