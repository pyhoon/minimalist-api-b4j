B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
'Api Handler class
'Version 5.40
Sub Class_Globals
	Private App As EndsMeet
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Method As String
	Private Elements() As String
	Private ElementId As Int
End Sub

Public Sub Initialize
	App = Main.app
	HRM.Initialize
	Main.SetApiMessage(HRM)
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Dim FullElements() As String = WebApiUtils.GetUriElements(Request.RequestURI)
	Elements = WebApiUtils.CropElements(FullElements, 3) ' 3 For Api handler
	If ElementMatch("") Then
		If App.MethodAvailable2(Method, "/api/products", Me) Then
			Select Method
				Case "GET"
					GetProducts
					Return
				Case "POST"
					PostProduct
					Return
			End Select
		End If
		ReturnMethodNotAllow
		Return
	Else If ElementMatch("id") Then
		If App.MethodAvailable2(Method, "/api/products/*", Me) Then
			Select Method
				Case "GET"
					GetProductById(ElementId)
					Return
				Case "PUT"
					PutProductById(ElementId)
					Return
				Case "DELETE"
					DeleteProductById(ElementId)
					Return
			End Select
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

Private Sub GetProducts
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	HRM.ResponseCode = 200
	Dim OrderKeys As List = Array("id", "category_id", "product_code", "product_name", "product_price", "created_date", "modified_date")
	Dim CloneList As MinimaList = Main.ProductsList.Clone
	For Each M1 As Map In CloneList.List
		If HRM.OrderedKeys Then M1.Put("__order", OrderKeys)
	Next
	HRM.ResponseData = CloneList.List
	ReturnApiResponse
End Sub

Private Sub GetProductById (id As Int)
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	HRM.ResponseCode = 200
	Dim OrderKeys As List = Array("id", "category_id", "product_code", "product_name", "product_price", "created_date", "modified_date")
	Dim M1 As Map = Main.ProductsList.Clone.Find(id)
	If HRM.OrderedKeys Then M1.Put("__order", OrderKeys)
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub

Private Sub PostProduct
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
	Dim RequiredKeys As List = Array As String("category_id", "product_code", "product_name") ' "product_price" is optional
	For Each requiredkey As String In RequiredKeys
		If data.ContainsKey(requiredkey) = False Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"Key '${requiredkey}' not found"$
			ReturnApiResponse
			Return
		End If
	Next
	' Check conflict Category Name
	Dim M1 As Map = Main.ProductsList.FindByKey("product_code", data.Get("product_code"))
	If M1.Size > 0 Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		ReturnApiResponse
		Return
	End If

	If Not(data.ContainsKey("created_date")) Then
		data.Put("created_date", WebApiUtils.CurrentDateTime)
	End If

	Main.ProductsList.Add(data)
	If Main.KVS_ENABLED Then Main.WriteKVS("ProductsList", Main.ProductsList)

	Dim CloneList As MinimaList = Main.ProductsList.Clone
	Dim M1 As Map = CloneList.Last
	Dim OrderKeys As List = Array("id", "category_id", "product_code", "product_name", "product_price", "created_date", "modified_date")
	If HRM.OrderedKeys Then M1.Put("__order", OrderKeys)

	HRM.ResponseCode = 201
	HRM.ResponseMessage = "Product created successfully"
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub

Private Sub PutProductById (id As Int)
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
	
	If data.ContainsKey("catid") Then
		data.Put("category_id", data.Get("catid"))
		data.Remove("catid")
	End If
	
	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("category_id", "product_code", "product_name") ' "product_price" is optional
	For Each requiredkey As String In RequiredKeys
		If data.ContainsKey(requiredkey) = False Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"Key '${requiredkey}' not found"$
			ReturnApiResponse
			Return
		End If
	Next
	' Check conflict Product Code
	Dim L1 As List = Main.ProductsList.FindAll(Array("product_code"), Array(data.Get("product_code")))
	For Each M As Map In L1
		If id <> M.Get("id") Then
			HRM.ResponseCode = 409
			HRM.ResponseError = "Product Code already exist"
			ReturnApiResponse
			Return
		End If
	Next
	
	' Find row by id
	Dim M1 As Map = Main.ProductsList.Find(id)
	If M1.Size = 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
	If Not(data.ContainsKey("modified_date")) Then
		data.Put("modified_date", WebApiUtils.CurrentDateTime)
	End If
				
	For Each Key As String In data.Keys
		Select Key
			Case "id", "category_id"
				M1.Put(Key, data.Get(Key).As(Int))
			Case "product_price"
				M1.Put(Key, data.Get(Key).As(Double))
			Case Else
				M1.Put(Key, data.Get(Key))
		End Select
	Next
	If Main.KVS_ENABLED Then Main.WriteKVS("ProductsList", Main.ProductsList)
		
	Dim M2 As Map = Main.ProductsList.CopyObject(M1)
	Dim OrderKeys As List = Array("id", "category_id", "product_code", "product_name", "product_price", "created_date", "modified_date")
	If HRM.OrderedKeys Then M2.Put("__order", OrderKeys)
	
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product updated successfully"
	HRM.ResponseObject = M2
	ReturnApiResponse
End Sub

Private Sub DeleteProductById (id As Int)
	Log($"${Request.Method}: ${Request.RequestURI}"$)
	Dim Index As Int = Main.ProductsList.IndexFromId(id)
	If Index < 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
	Main.ProductsList.Remove(Index)
	If Main.KVS_ENABLED Then Main.WriteKVS("ProductsList", Main.ProductsList)
		
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product Deleted"
	ReturnApiResponse
End Sub