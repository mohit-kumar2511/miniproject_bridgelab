Option Explicit

Sub RefreshAllPhotos()
    Dim wsStudents As Worksheet
    Dim wsSettings As Worksheet
    Dim lastRow As Long
    Dim idCol As Long
    Dim photoCol As Long
    Dim i As Long
    Dim studentID As String
    
    Set wsStudents = Worksheets("Students")
    Set wsSettings = Worksheets("Settings")
    
    idCol = GetColNum(wsStudents, "StudentID")
    photoCol = GetColNum(wsStudents, "PhotoPath")
    lastRow = wsStudents.Cells(wsStudents.Rows.Count, idCol).End(xlUp).Row
    
    For i = 2 To lastRow
        studentID = wsStudents.Cells(i, idCol).Value
        If studentID <> "" Then
            UpdatePhotoDisplay i
        End If
    Next i
End Sub

Sub UpdatePhotoDisplay(row As Long)
    Dim wsStudents As Worksheet
    Dim wsSettings As Worksheet
    Dim idCol As Long
    Dim photoCol As Long
    Dim studentID As String
    Dim photoPath As String
    Dim placeholderPath As String
    Dim shapeName As String
    Dim existingShape As Shape
    Dim newShape As Shape
    Dim targetCell As Range
    
    Set wsStudents = Worksheets("Students")
    Set wsSettings = Worksheets("Settings")
    
    idCol = GetColNum(wsStudents, "StudentID")
    photoCol = GetColNum(wsStudents, "PhotoPath")
    placeholderPath = wsSettings.Range("B3").Value
    
    studentID = wsStudents.Cells(row, idCol).Value
    photoPath = wsStudents.Cells(row, photoCol).Value
    
    If Trim(photoPath) = "" Then
        photoPath = placeholderPath
    End If
    
    shapeName = "Photo_S_" & studentID
    
    On Error Resume Next
    Set existingShape = wsStudents.Shapes(shapeName)
    If Not existingShape Is Nothing Then
        existingShape.Delete
    End If
    On Error GoTo 0
    
    Set targetCell = wsStudents.Cells(row, photoCol)
    
    On Error Resume Next
    Set newShape = wsStudents.Shapes.AddPicture(photoPath, msoFalse, msoTrue, targetCell.Left, targetCell.Top, 50, 50)
    newShape.Name = shapeName
    newShape.Placement = xlMoveAndSize
    On Error GoTo 0
End Sub

