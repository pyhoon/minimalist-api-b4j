B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
'Api Handler class
'Version 5.30
Sub Class_Globals
	Private App As EndsMeet
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Method As String
	Private Elements() As String
	Private ElementId As Int
	Private ElementKey As String
End Sub

Public Sub Initialize
	App = Main.app
	HRM.Initialize
	HRM = App.SetApiMessage(HRM, App.api)
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Dim FullElements() As String = WebApiUtils.GetUriElements(Request.RequestURI)
	Elements = WebApiUtils.CropElements(FullElements, 3)
	If ElementMatch("") Then
		If App.MethodAvailable2(Method, "/api/find", Me) Then
			Select Method
				Case "GET"
					GetAllProducts
					Return
				Case "POST"
					SearchByKeywords
					Return
			End Select
		End If
		ReturnMethodNotAllow
		Return
	End If
	If ElementMatch("key/id") Then
		If App.MethodAvailable2(Method, "/api/find/products-by-category_id/*", Me) Then
			If ElementKey = "products-by-category_id" Then
				GetProductsByCategoryId(ElementId)
				Return
			End If
		End If
		ReturnMethodNotAllow
		Return
	End If
	ReturnBadRequest
End Sub

Private Sub ElementMatch (Pattern As String) As Boolean
	Select Pattern
		Case ""
			If Elements.Length = 0 Then
				Return True
			End If
		Case "id"
			If Elements.Length = 1 Then
				If IsNumber(Elements(0)) Then
					ElementId = Elements(0)
					Return True
				End If
			End If
		Case "key/id"
			If Elements.Length = 2 Then
				ElementKey = Elements(0)
				If IsNumber(Elements(1)) Then
					ElementId = Elements(1)
					Return True
				End If
			End If
	End Select
	Return False
End Sub

Private Sub ReturnApiResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(HRM, Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(HRM, Response)
End Sub

Public Sub GetAllProducts
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim FindList As MinimaList = Main.ProductsList.Clone
	For Each M1 As Map In FindList.List
		Dim category_name As String = Main.CategoriesList.Find(M1.Get("category_id")).Get("category_name")
		M1.Put("category_name", category_name)
		RenameKeys(M1)
	Next
	HRM.ResponseCode = 200
	HRM.ResponseData = FindList.List
	ReturnApiResponse
End Sub

Public Sub GetProductsByCategoryId (id As Int)
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim FindList As MinimaList = Main.ProductsList.Clone
	FindList.List = FindList.FindAll(Array("category_id"), Array(id))
	For Each M1 As Map In FindList.List
		Dim category_name As String = Main.CategoriesList.Find(M1.Get("category_id")).Get("category_name")
		M1.Put("category_name", category_name)
		RenameKeys(M1)
	Next
	HRM.ResponseCode = 200
	HRM.ResponseData = FindList.List
	ReturnApiResponse
End Sub

Public Sub SearchByKeywords
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim str As String = WebApiUtils.RequestDataText(Request)
	If WebApiUtils.ValidateContent(str, HRM.PayloadType) = False Then
		HRM.ResponseCode = 422
		HRM.ResponseError = $"Invalid ${HRM.PayloadType} payload"$
		ReturnApiResponse
		Return
	End If
	If HRM.PayloadType = WebApiUtils.MIME_TYPE_XML Then
		Dim data As Map = WebApiUtils.ParseXML(str)		' XML payload
	Else
		Dim data As Map = WebApiUtils.ParseJSON(str)	' JSON payload
	End If
	' Check whether required keys are provided
	If data.ContainsKey("keyword") = False Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'keyword' not found"
		ReturnApiResponse
		Return
	End If
	Dim SearchForText As String = data.Get("keyword")
	Dim FindList As MinimaList = Main.ProductsList.Clone
	FindList.List = FindList.FindAnyLike(Array("product_code", "product_name", "category_name"), Array As String(SearchForText, SearchForText, SearchForText))
	For Each M1 As Map In FindList.List
		Dim category_name As String = Main.CategoriesList.Find(M1.Get("category_id")).Get("category_name")
		M1.Put("category_name", category_name)
		RenameKeys(M1)
	Next
	HRM.ResponseCode = 200
	HRM.ResponseData = FindList.List
	ReturnApiResponse
End Sub

Private Sub RenameKeys (M1 As Map) 'As Map
	M1.Put("code", M1.Get("product_code"))
	M1.Put("name", M1.Get("product_name"))
	M1.Put("price", M1.Get("product_price"))
	M1.Put("catid", M1.Get("category_id"))
	M1.Put("category", M1.Get("category_name"))
	M1.Remove("category_id")
	M1.Remove("category_name")
	M1.Remove("product_code")
	M1.Remove("product_name")
	M1.Remove("product_price")
	Dim OrderKeys As List = Array("id", "catid", "code", "name", "category", "price")
	If HRM.OrderedKeys Then M1.Put("__order", OrderKeys)
End Sub