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

' Web Router
Public Sub RouteWeb
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ElementLastIndex = Elements.Length - 1
	ControllerIndex = Main.Element.WebControllerIndex
	If ElementLastIndex > ControllerIndex Then
		FirstIndex = ControllerIndex + 1
		FirstElement = Elements(FirstIndex)
	End If
	
	Select Method
		Case "GET"
			Select ElementLastIndex
				Case ControllerIndex
					ShowPage
					Return
			End Select
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
					GetCategories
					Return
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					GetCategory(FirstElement)
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
					PostCategories
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
					PutCategory(FirstElement)
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
					DeleteCategory(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub GetCategories
	' #Version = v2
	' #Desc = Read all items in Categories

	HRM.ResponseCode = 200
	HRM.ResponseData = Main.CategoriesList.List
	ReturnApiResponse
End Sub

Private Sub GetCategory (id As Long)
	' #Version = v2
	' #Desc = Read one item in Category by id
	' #Elements = [":id"]
	
	Dim M1 As Map = Main.CategoriesList.Find(id)
	If M1.Size > 0 Then
		HRM.ResponseCode = 200
	Else
		HRM.ResponseCode = 404
	End If
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub

Private Sub PostCategories
	' #Version = v2
	' #Desc = Add a new item into Categories
	' #Body = {<br>&nbsp;"name": "category_name"<br>}
	
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
	
	' Make it compatible with Web API Client v1
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	' Check conflict Category Name
	Dim M1 As Map = Main.CategoriesList.FindByKey("category_name", data.Get("category_name"))
	If M1.Size > 0 Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category Name already exist"
		ReturnApiResponse
		Return
	End If
	
	If Not(data.ContainsKey("created_date")) Then
		data.Put("created_date", WebApiUtils.CurrentDateTime)
	End If
	
	Main.CategoriesList.Add(data)
	If Main.KVS_ENABLED Then Main.WriteKVS("CategoriesList", Main.CategoriesList)
	
	HRM.ResponseCode = 201
	HRM.ResponseMessage = "Category created successfully"
	HRM.ResponseObject = Main.CategoriesList.Last
	ReturnApiResponse
End Sub

Private Sub PutCategory (id As Long)
	' #Version = v2
	' #Desc = Update Category by id
	' #Body = {<br>&nbsp;"name": "category_name"<br>}
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
	
	Dim M1 As Map = Main.CategoriesList.Find(id)
	If M1.Size = 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
	' Make it compatible with Web API Client v1
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	' Check conflict Category Name
	Dim L1 As List = Main.CategoriesList.FindAll(Array("category_name"), Array(data.Get("category_name")))
	For Each M As Map In L1
		If id <> M.Get("id") Then
			HRM.ResponseCode = 409
			HRM.ResponseError = "Category Name already exist"
			ReturnApiResponse
			Return
		End If
	Next
	
	If Not(data.ContainsKey("modified_date")) Then
		data.Put("modified_date", WebApiUtils.CurrentDateTime)
	End If
	
	For Each Key As String In data.Keys
		Select Key
			Case "id"
				M1.Put(Key, data.Get(Key).As(Long))
			Case Else
				M1.Put(Key, data.Get(Key))
		End Select
	Next
	Main.WriteKVS("CategoriesList", Main.CategoriesList)
	
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Category Updated"
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub

Private Sub DeleteCategory (id As Long)
	' #Version = v2
	' #Desc = Delete Category by id
	' #Elements = [":id"]

	Dim Index As Int = Main.CategoriesList.IndexFromId(id)
	If Index < 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Id not found"
		ReturnApiResponse
		Return
	End If
	
	Main.CategoriesList.Remove(Index)
	Main.WriteKVS("CategoriesList", Main.CategoriesList)
	
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Category Deleted"
	ReturnApiResponse
End Sub

' Return Web Page
Private Sub ShowPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("category.html")
	Dim strHelp As String
	Dim strJSFile As String
	Dim strScripts As String
	
	If Main.SHOW_API_ICON Then
		strHelp = $"        <li class="nav-item">
          <a class="nav-link mr-3 font-weight-bold text-white" href="${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}help"><i class="fas fa-cog" title="API"></i> API</a>
	</li>"$
	Else
		strHelp = ""
	End If
	
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", strHelp)
	strMain = WebApiUtils.BuildHtml(strMain, Main.config)
	If Main.SimpleResponse.Enable Then
		If Main.SimpleResponse.Format = "Map" Then
			strJSFile = "webapi.category.simple.map.js"
		Else
			strJSFile = "webapi.category.simple.js"
		End If
	Else
		strJSFile = "webapi.category.js"
	End If
	strScripts = $"<script src="${Main.Config.Get("ROOT_URL")}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub