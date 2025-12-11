Option Explicit

Sub InstallLibrarySystem()
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    Dim ws As Worksheet
    Dim i As Integer
    
    On Error Resume Next
    
    For i = Worksheets.Count To 1 Step -1
        If Worksheets(i).Name <> "Students" And Worksheets(i).Name <> "Transactions" And _
           Worksheets(i).Name <> "Reports" And Worksheets(i).Name <> "ReceiptTemplate" And _
           Worksheets(i).Name <> "Settings" Then
            Worksheets(i).Delete
        End If
    Next i
    
    Call CreateSheets
    Call SetupHeaders
    Call SetupSettings
    Call ImportSampleData
    Call SetupReceiptTemplate
    
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True
    
    MsgBox "Installation Complete! All sheets and headers are ready." & vbCrLf & _
           "Please verify Settings sheet (B1-B3) and run RefreshAllPhotos", vbInformation
End Sub

Sub CreateSheets()
    Dim sheetNames As Variant
    Dim i As Integer
    Dim ws As Worksheet
    
    sheetNames = Array("Students", "Transactions", "Reports", "ReceiptTemplate", "Settings")
    
    For i = LBound(sheetNames) To UBound(sheetNames)
        On Error Resume Next
        Set ws = Worksheets(sheetNames(i))
        On Error GoTo 0
        
        If ws Is Nothing Then
            Worksheets.Add.Name = sheetNames(i)
        End If
        Set ws = Nothing
    Next i
End Sub

Sub SetupHeaders()
    Dim ws As Worksheet
    
    Set ws = Worksheets("Students")
    ws.Range("A1:L1").Value = Array("StudentID", "Name", "FatherName", "Mobile", "Gender", _
                                     "AdmissionDate", "Plan", "ExpiryDate", "Locker", _
                                     "FixedSeat", "PhotoPath", "Status")
    ws.Rows(1).Font.Bold = True
    ws.Rows(1).Interior.Color = RGB(200, 200, 200)
    
    Set ws = Worksheets("Transactions")
    ws.Range("A1:H1").Value = Array("TransID", "Date", "StudentID", "Type", "Amount", _
                                     "MonthPaidFor", "Description", "Source")
    ws.Rows(1).Font.Bold = True
    ws.Rows(1).Interior.Color = RGB(200, 200, 200)
    
    Set ws = Worksheets("Reports")
    ws.Range("A1").Value = "Library Management Dashboard"
    ws.Range("A1").Font.Size = 16
    ws.Range("A1").Font.Bold = True
    
    Set ws = Worksheets("Settings")
    ws.Range("A1").Value = "LibraryName:"
    ws.Range("A2").Value = "LogoPath:"
    ws.Range("A3").Value = "PlaceholderPhotoPath:"
    ws.Range("B1").Value = "Sakshi Library"
    ws.Columns("A").ColumnWidth = 25
    ws.Columns("B").ColumnWidth = 50
End Sub

Sub SetupSettings()
    Dim ws As Worksheet
    Set ws = Worksheets("Settings")
    
    If Trim(ws.Range("B1").Value) = "" Then ws.Range("B1").Value = "Sakshi Library"
    If Trim(ws.Range("B2").Value) = "" Then ws.Range("B2").Value = ThisWorkbook.Path & "\logo.png"
    If Trim(ws.Range("B3").Value) = "" Then ws.Range("B3").Value = ThisWorkbook.Path & "\placeholder.png"
End Sub

Sub ImportSampleData()
    Dim wsStudents As Worksheet
    Dim wsTrans As Worksheet
    Dim lastRow As Long
    
    Set wsStudents = Worksheets("Students")
    Set wsTrans = Worksheets("Transactions")
    
    If wsStudents.Range("A2").Value = "" Then
        wsStudents.Range("A2").Value = "S0001"
        wsStudents.Range("B2").Value = "Rajesh Kumar"
        wsStudents.Range("C2").Value = "Mahesh Kumar"
        wsStudents.Range("D2").Value = "9876543210"
        wsStudents.Range("E2").Value = "Male"
        wsStudents.Range("F2").Value = DateSerial(2024, 1, 15)
        wsStudents.Range("G2").Value = "Monthly"
        wsStudents.Range("H2").Value = DateSerial(2024, 3, 31)
        wsStudents.Range("L2").Value = "Active"
        
        wsStudents.Range("A3").Value = "S0002"
        wsStudents.Range("B3").Value = "Priya Sharma"
        wsStudents.Range("C3").Value = "Vikram Sharma"
        wsStudents.Range("D3").Value = "9876543211"
        wsStudents.Range("E3").Value = "Female"
        wsStudents.Range("F3").Value = DateSerial(2024, 2, 1)
        wsStudents.Range("G3").Value = "Monthly"
        wsStudents.Range("H3").Value = DateSerial(2024, 4, 30)
        wsStudents.Range("L3").Value = "Active"
        
        wsStudents.Range("A4").Value = "S0003"
        wsStudents.Range("B4").Value = "Amit Patel"
        wsStudents.Range("C4").Value = "Ramesh Patel"
        wsStudents.Range("D4").Value = "9876543212"
        wsStudents.Range("E4").Value = "Male"
        wsStudents.Range("F4").Value = DateSerial(2024, 2, 15)
        wsStudents.Range("G4").Value = "Quarterly"
        wsStudents.Range("H4").Value = DateSerial(2024, 5, 31)
        wsStudents.Range("L4").Value = "Active"
    End If
    
    If wsTrans.Range("A2").Value = "" Then
        wsTrans.Range("A2").Value = "T0001"
        wsTrans.Range("B2").Value = DateSerial(2024, 1, 15)
        wsTrans.Range("C2").Value = "S0001"
        wsTrans.Range("D2").Value = "Income"
        wsTrans.Range("E2").Value = 500
        wsTrans.Range("F2").Value = "Jan-2024"
        wsTrans.Range("G2").Value = "Payment for Jan-2024"
        wsTrans.Range("H2").Value = "Cash"
        
        wsTrans.Range("A3").Value = "T0002"
        wsTrans.Range("B3").Value = DateSerial(2024, 2, 1)
        wsTrans.Range("C3").Value = "S0002"
        wsTrans.Range("D3").Value = "Income"
        wsTrans.Range("E3").Value = 500
        wsTrans.Range("F3").Value = "Feb-2024"
        wsTrans.Range("G3").Value = "Payment for Feb-2024"
        wsTrans.Range("H3").Value = "Cash"
        
        wsTrans.Range("A4").Value = "T0003"
        wsTrans.Range("B4").Value = DateSerial(2024, 2, 15)
        wsTrans.Range("C4").Value = "S0003"
        wsTrans.Range("D4").Value = "Income"
        wsTrans.Range("E4").Value = 1200
        wsTrans.Range("F4").Value = "Feb-2024"
        wsTrans.Range("G4").Value = "Payment for Feb-2024"
        wsTrans.Range("H4").Value = "Online"
        
        wsTrans.Range("A5").Value = "T0004"
        wsTrans.Range("B5").Value = DateSerial(2024, 2, 20)
        wsTrans.Range("C5").Value = "S0001"
        wsTrans.Range("D5").Value = "Income"
        wsTrans.Range("E5").Value = 500
        wsTrans.Range("F5").Value = "Feb-2024"
        wsTrans.Range("G5").Value = "Payment for Feb-2024"
        wsTrans.Range("H5").Value = "Cash"
    End If
End Sub

Sub SetupReceiptTemplate()
    Dim ws As Worksheet
    Set ws = Worksheets("ReceiptTemplate")
    
    ws.Range("A1").Value = "Library Name:"
    ws.Range("A2").Value = "Logo:"
    ws.Range("A4").Value = "Student Name:"
    ws.Range("A5").Value = "Father Name:"
    ws.Range("A6").Value = "Mobile:"
    ws.Range("A7").Value = "Student ID:"
    ws.Range("A8").Value = "Plan:"
    ws.Range("A9").Value = "Old Expiry:"
    ws.Range("A10").Value = "New Expiry:"
    ws.Range("A11").Value = "Month Paid For:"
    ws.Range("A12").Value = "Amount:"
    ws.Range("A13").Value = "Transaction ID:"
    ws.Range("A14").Value = "Receipt Date:"
    
    ws.Columns("A").ColumnWidth = 20
    ws.Columns("B").ColumnWidth = 30
    ws.Columns("C").ColumnWidth = 10
    ws.Columns("D").ColumnWidth = 20
    
    ws.Range("A1").Font.Bold = True
    ws.Range("A4:A14").Font.Bold = True
End Sub

