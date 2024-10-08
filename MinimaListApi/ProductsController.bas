B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' MinimaList Controller
' Version 1.07
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
	HRM.SimpleResponse = Main.SimpleResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(Response)
End Sub

Private Sub ReturnErrorUnprocessableEntity
	WebApiUtils.ReturnErrorUnprocessableEntity(Response)
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
			ReturnMethodNotAllow
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
						ReturnErrorUnprocessableEntity
						Return
					End If
					GetProduct(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

' Router for POST request
Private Sub RoutePost
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					PostProducts
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

' Router for PUT request
Private Sub RoutePut
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					PutProduct(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

' Router for DELETE request
Private Sub RouteDelete
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					DeleteProduct(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub GetProducts
	' #Version = v2
	' #Desc = Read all Products

	HRM.ResponseCode = 200
	HRM.ResponseData = Main.ProductsList.List
	ReturnApiResponse
End Sub

Private Sub GetProduct (id As Long)
	' #Version = v2
	' #Desc = Read one Product by id
	' #Elements = [":id"]

	HRM.ResponseCode = 200
	HRM.ResponseObject = Main.ProductsList.Find(id)
	ReturnApiResponse
End Sub

Private Sub PostProducts
	' #Version = v2
	' #Desc = Add a new Product
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

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
	
	If data.ContainsKey("product_price") = False Then
		data.Put("product_price", 0)
	End If
	
	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("category_id", "product_code", "product_name") ' "product_price" is optional
	For Each requiredkey As String In RequiredKeys
		If Not(data.ContainsKey(requiredkey)) Then
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
	Main.WriteKVS("ProductsList", Main.ProductsList)

	' Retrieve new row
	HRM.ResponseCode = 201
	HRM.ResponseMessage = "Product created successfully"
	HRM.ResponseObject = Main.ProductsList.Last
	ReturnApiResponse
End Sub

Private Sub PutProduct (id As Long)
	' #Version = v2
	' #Desc = Update Product by id
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}
	' #Elements = [":id"]

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	If data.ContainsKey("") Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid key value"
		ReturnApiResponse
		Return
	End If
	
	Dim M1 As Map = Main.ProductsList.Find(id)
	If M1.Size = 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
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
	
	If Not(data.ContainsKey("modified_date")) Then
		data.Put("modified_date", WebApiUtils.CurrentDateTime)
	End If
				
	For Each Key As String In data.Keys
		Select Key
			Case "id", "category_id"
				M1.Put(Key, data.Get(Key).As(Long))
			Case "product_price"
				M1.Put(Key, data.Get(Key).As(Double))
			Case Else
				M1.Put(Key, data.Get(Key))
		End Select
	Next
	Main.WriteKVS("ProductsList", Main.ProductsList)

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product updated successfully"
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub

Private Sub DeleteProduct (id As Long)
	' #Version = v2
	' #Desc = Delete Product by id
	' #Elements = [":id"]
	
	Dim Index As Int = Main.ProductsList.IndexFromId(id)
	If Index < 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
	Main.ProductsList.Remove(Index)
	Main.WriteKVS("ProductsList", Main.ProductsList)
		
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product Deleted"
	ReturnApiResponse
End Sub