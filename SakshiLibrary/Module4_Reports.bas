Option Explicit

Sub ShowActiveStudents()
    Dim wsStudents As Worksheet
    Dim statusCol As Long
    
    Set wsStudents = Worksheets("Students")
    statusCol = GetColNum(wsStudents, "Status")
    
    wsStudents.AutoFilterMode = False
    wsStudents.Range("A1").AutoFilter
    wsStudents.AutoFilter Field:=statusCol, Criteria1:="Active"
End Sub

Sub ShowInactiveStudents()
    Dim wsStudents As Worksheet
    Dim statusCol As Long
    
    Set wsStudents = Worksheets("Students")
    statusCol = GetColNum(wsStudents, "Status")
    
    wsStudents.AutoFilterMode = False
    wsStudents.Range("A1").AutoFilter
    wsStudents.AutoFilter Field:=statusCol, Criteria1:="Inactive"
End Sub

Sub ShowTotalStudents()
    Dim wsStudents As Worksheet
    wsStudents.AutoFilterMode = False
End Sub

Sub ShowThisMonthIncome()
    Dim wsTrans As Worksheet
    Dim dateCol As Long
    Dim typeCol As Long
    Dim monthStart As Date
    Dim monthEnd As Date
    
    Set wsTrans = Worksheets("Transactions")
    dateCol = GetColNum(wsTrans, "Date")
    typeCol = GetColNum(wsTrans, "Type")
    
    monthStart = DateSerial(Year(Date), Month(Date), 1)
    monthEnd = DateSerial(Year(Date), Month(Date) + 1, 0)
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=dateCol, Criteria1:=">=" & monthStart, Operator:=xlAnd, Criteria2:="<=" & monthEnd
    wsTrans.AutoFilter Field:=typeCol, Criteria1:="Income"
End Sub

Sub ShowThisMonthExpense()
    Dim wsTrans As Worksheet
    Dim dateCol As Long
    Dim typeCol As Long
    Dim monthStart As Date
    Dim monthEnd As Date
    
    Set wsTrans = Worksheets("Transactions")
    dateCol = GetColNum(wsTrans, "Date")
    typeCol = GetColNum(wsTrans, "Type")
    
    monthStart = DateSerial(Year(Date), Month(Date), 1)
    monthEnd = DateSerial(Year(Date), Month(Date) + 1, 0)
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=dateCol, Criteria1:=">=" & monthStart, Operator:=xlAnd, Criteria2:="<=" & monthEnd
    wsTrans.AutoFilter Field:=typeCol, Criteria1:="Expense"
End Sub

Sub ShowMonthTransactions(monthText As String)
    Dim wsTrans As Worksheet
    Dim monthCol As Long
    
    Set wsTrans = Worksheets("Transactions")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=monthCol, Criteria1:=monthText
End Sub

Sub ShowRevenueBySource(monthText As String)
    Dim wsTrans As Worksheet
    Dim monthCol As Long
    Dim typeCol As Long
    
    Set wsTrans = Worksheets("Transactions")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    typeCol = GetColNum(wsTrans, "Type")
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=monthCol, Criteria1:=monthText
    wsTrans.AutoFilter Field:=typeCol, Criteria1:="Income"
End Sub

Sub FilterThisMonthActive()
    Dim wsStudents As Worksheet
    Dim statusCol As Long
    Dim expiryCol As Long
    Dim monthEnd As Date
    
    Set wsStudents = Worksheets("Students")
    statusCol = GetColNum(wsStudents, "Status")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    monthEnd = DateSerial(Year(Date), Month(Date) + 1, 0)
    
    wsStudents.AutoFilterMode = False
    wsStudents.Range("A1").AutoFilter
    wsStudents.AutoFilter Field:=statusCol, Criteria1:="Active"
    wsStudents.AutoFilter Field:=expiryCol, Criteria1:=">=" & monthEnd
End Sub

Sub FilterPreviousMonthActive()
    Dim wsStudents As Worksheet
    Dim statusCol As Long
    Dim expiryCol As Long
    Dim prevMonthEnd As Date
    
    Set wsStudents = Worksheets("Students")
    statusCol = GetColNum(wsStudents, "Status")
    expiryCol = GetColNum(wsStudents, "ExpiryDate")
    prevMonthEnd = DateSerial(Year(Date), Month(Date), 0)
    
    wsStudents.AutoFilterMode = False
    wsStudents.Range("A1").AutoFilter
    wsStudents.AutoFilter Field:=statusCol, Criteria1:="Active"
    wsStudents.AutoFilter Field:=expiryCol, Criteria1:="<=" & prevMonthEnd
End Sub

Sub FilterByMonth(monthText As String)
    Dim wsTrans As Worksheet
    Dim monthCol As Long
    
    Set wsTrans = Worksheets("Transactions")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=monthCol, Criteria1:=monthText
End Sub

Sub FilterInactive()
    Dim wsStudents As Worksheet
    Dim statusCol As Long
    
    Set wsStudents = Worksheets("Students")
    statusCol = GetColNum(wsStudents, "Status")
    
    wsStudents.AutoFilterMode = False
    wsStudents.Range("A1").AutoFilter
    wsStudents.AutoFilter Field:=statusCol, Criteria1:="Inactive"
End Sub

Sub FilterMonthComplete(monthText As String)
    Dim wsTrans As Worksheet
    Dim monthCol As Long
    Dim typeCol As Long
    
    Set wsTrans = Worksheets("Transactions")
    monthCol = GetColNum(wsTrans, "MonthPaidFor")
    typeCol = GetColNum(wsTrans, "Type")
    
    wsTrans.AutoFilterMode = False
    wsTrans.Range("A1").AutoFilter
    wsTrans.AutoFilter Field:=monthCol, Criteria1:=monthText
    wsTrans.AutoFilter Field:=typeCol, Criteria1:="Income"
End Sub

