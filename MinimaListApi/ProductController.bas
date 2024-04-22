B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Controller
' Version 1.06
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Method As String
	Private Version As String
	Private Elements() As String
	Private ApiVersionIndex As Int
	Private ControllerIndex As Int
	Private ElementLastIndex As Int
	Private FirstIndex As Int
	Private FirstElement As String
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Private Sub ReturnApiResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

' API Router
Public Sub RouteApi
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ElementLastIndex = Elements.Length - 1
	ApiVersionIndex = Main.Element.ApiVersionIndex
	Version = Elements(ApiVersionIndex)
	ControllerIndex = Main.Element.ApiControllerIndex
	If ElementLastIndex > ControllerIndex Then
		FirstIndex = ControllerIndex + 1
		FirstElement = Elements(FirstIndex)
	End If

	Select Method
		Case "GET"
			RouteGet
		Case "POST"
			RoutePost
		Case "PUT"
			RoutePut
		Case "DELETE"
			RouteDelete
		Case Else
			Log("Unsupported method: " & Method)
			WebApiUtils.ReturnMethodNotAllow(Response)
	End Select
End Sub

' Router for GET request
Private Sub RouteGet
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					GetProducts
					Return
				Case FirstIndex					
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					GetProduct(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for POST request
Private Sub RoutePost
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					PostProduct
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for PUT request
Private Sub RoutePut
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					PutProduct(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for DELETE request
Private Sub RouteDelete
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					DeleteProduct(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub GetProducts
	' #Plural = Products
	' #Version = v2
	' #Desc = Read all Products

	HRM.ResponseCode = 200
	HRM.ResponseData = Main.ProductList.List
	ReturnApiResponse
End Sub

Private Sub GetProduct (id As Long)
	' #Plural = Products
	' #Version = v2
	' #Desc = Read one Product by id
	' #Elements = [":id"]

	HRM.ResponseCode = 200
	HRM.ResponseObject = Main.ProductList.Find(id)
	ReturnApiResponse
End Sub

Private Sub PostProduct
	' #Plural = Products
	' #Version = v2
	' #Desc = Add a new Product
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
	Else If data.ContainsKey("") Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid key value"
	Else
		' Make it compatible with Web API Client v1
		If data.ContainsKey("cat_id") Then
			data.Put("category_id", data.Get("cat_id"))
			data.Remove("cat_id")
		End If
		If data.ContainsKey("code") Then
			data.Put("product_code", data.Get("code"))
			data.Remove("code")
		End If
		If data.ContainsKey("name") Then
			data.Put("product_name", data.Get("name"))
			data.Remove("name")
		End If
		If data.ContainsKey("price") Then
			data.Put("product_price", data.Get("price"))
			data.Remove("price")
		End If
		If Main.ProductList.FindAll(Array("product_code"), Array(data.Get("product_code"))).Size > 0 Then
			HRM.ResponseCode = 409
			HRM.ResponseError = "Product Code already exist"
			ReturnApiResponse
			Return
		End If
		
		If Not(data.ContainsKey("created_date")) Then
			data.Put("created_date", WebApiUtils.CurrentDateTime)
		End If
		Main.ProductList.Add(data)
		HRM.ResponseCode = 201
		HRM.ResponseObject = Main.ProductList.Last
		HRM.ResponseMessage = "Product created"
		If Main.KVS_ENABLED Then Main.WriteKVS("ProductList", Main.ProductList)
	End If
	ReturnApiResponse
End Sub

Private Sub PutProduct (id As Long)
	' #Plural = Products
	' #Version = v2
	' #Desc = Update Product by id
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}
	' #Elements = [":id"]

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
	Else
		If data.ContainsKey("") Then
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid key value"
		Else
			Dim M1 As Map = Main.ProductList.Find(id)
			If M1.Size = 0 Then
				HRM.ResponseCode = 404
				HRM.ResponseError = "Data not found"
			Else
				' Make it compatible with Web API Client v1
				If data.ContainsKey("cat_id") Then
					data.Put("category_id", data.Get("cat_id"))
					data.Remove("cat_id")
				End If
				If data.ContainsKey("code") Then
					data.Put("product_code", data.Get("code"))
					data.Remove("code")
				End If
				If data.ContainsKey("name") Then
					data.Put("product_name", data.Get("name"))
					data.Remove("name")
				End If
				If data.ContainsKey("price") Then
					data.Put("product_price", data.Get("price"))
					data.Remove("price")
				End If
				For Each item As Map In Main.ProductList.FindAll(Array("product_code"), Array(data.Get("product_code")))
					If id <> item.Get("id") Then
						HRM.ResponseCode = 409
						HRM.ResponseError = "Product Code already exist"
						ReturnApiResponse
						Return
					End If
				Next

				If Not(data.ContainsKey("updated_date")) Then
					data.Put("updated_date", WebApiUtils.CurrentDateTime)
				End If
				For Each Key As String In data.Keys
					M1.Put(Key, data.Get(Key))
				Next
				HRM.ResponseCode = 200
				HRM.ResponseObject = M1
				If Main.KVS_ENABLED Then Main.WriteKVS("CategoryList", Main.CategoryList)
			End If
		End If
	End If
	ReturnApiResponse
End Sub

Private Sub DeleteProduct (id As Long)
	' #Plural = Products
	' #Version = v2
	' #Desc = Delete Product by id
	' #Elements = [":id"]

	Dim Index As Int = Main.ProductList.IndexFromId(id)
	If Index < 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	Else
		'If Index <= Main.ProductList.List.Size - 1 Then
		Main.ProductList.Remove(Index)
		HRM.ResponseCode = 200
		If Main.KVS_ENABLED Then Main.WriteKVS("ProductList", Main.ProductList)
		'End If
	End If
	ReturnApiResponse
End Sub