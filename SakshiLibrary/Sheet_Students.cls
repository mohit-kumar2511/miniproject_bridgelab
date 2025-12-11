Option Explicit

Private Sub Worksheet_Change(ByVal Target As Range)
    Dim nameCol As Long
    Dim fatherCol As Long
    Dim mobileCol As Long
    Dim affectedCol As Long
    
    Application.EnableEvents = False
    
    nameCol = GetColNum(Me, "Name")
    fatherCol = GetColNum(Me, "FatherName")
    mobileCol = GetColNum(Me, "Mobile")
    
    affectedCol = Target.Column
    
    If affectedCol = nameCol Or affectedCol = fatherCol Or affectedCol = mobileCol Then
        ValidateStudentRow Target.Row
    End If
    
    Application.EnableEvents = True
End Sub

