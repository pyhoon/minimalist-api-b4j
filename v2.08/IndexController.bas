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

Public Sub Show
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
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
	strMain = WebApiUtils.BuildHtml(strMain, Main.Config)
	If Main.SimpleResponse.Enable Then
		If Main.SimpleResponse.Format = "Map" Then
			strJSFile = "webapi.search.simple.map.js"
		Else
			strJSFile = "webapi.search.simple.js"
		End If
	Else
		strJSFile = "webapi.search.js"
	End If
	strScripts = $"<script src="${Main.Config.Get("ROOT_URL")}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub

Public Sub GetSearch
	Dim CombineList As List
	CombineList.Initialize
	Dim L1 As List = Main.ProductsList.CopyList
	
	For Each M1 As Map In L1
		Dim catid As Long = M1.Get("category_id")
		Dim category_name As String = Main.CategoriesList.Find(catid).Get("category_name")
		M1.Put("category_name", category_name)
		CombineList.Add(M1)
	Next
	
	HRM.ResponseCode = 200
	HRM.ResponseData = CombineList
	ReturnApiResponse
End Sub

Public Sub PostSearch
	Dim CombineList As List
	CombineList.Initialize
	Dim L1 As List = Main.ProductsList.CopyList
	
	For Each M1 As Map In L1
		Dim catid As Long = M1.Get("category_id")
		Dim category_name As String = Main.CategoriesList.Find(catid).Get("category_name")
		M1.Put("category_name", category_name)
		CombineList.Add(M1)
	Next

	Dim SearchForText As String
	Dim Data As Map = WebApiUtils.RequestData(Request)
	
	If Data.IsInitialized Then
		SearchForText = Data.Get("keywords")
	End If
	
	If SearchForText = "" Then
		HRM.ResponseCode = 200
		HRM.ResponseData = CombineList
	Else
		Dim CL As MinimaList
		CL.Initialize
		CL.List = CombineList
		Dim L2 As List = CL.FindAnyLike(Array("product_code", "product_name", "category_name"), Array As String(SearchForText, SearchForText, SearchForText))
		HRM.ResponseCode = 200
		HRM.ResponseData = L2
	End If
	ReturnApiResponse
End Sub

' Seed some dummy data into MimimaList
Public Sub SeedData
	If Main.CategoriesList.List.Size = 0 Then
		Dim M1 As Map = CreateMap("category_name": "Hardwares", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoriesList.Add(M1)
		Dim M1 As Map = CreateMap("category_name": "Toys", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoriesList.Add(M1)
		Main.WriteKVS("CategoriesList", Main.CategoriesList)
	End If

	If Main.ProductsList.List.Size = 0 Then
		Dim M2 As Map = CreateMap("category_id": 2, _
		"product_code": "T001", _
		"product_name": "Teddy Bear", _
		"product_price": 99.9, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductsList.Add(M2)
		Dim M2 As Map = CreateMap("category_id": 1, _
		"product_code": "H001", _
		"product_name": "Hammer", _
		"product_price": 15.75, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductsList.Add(M2)
		Dim M2 As Map = CreateMap("category_id": 2, _
		"product_code": "T002", _
		"product_name": "Optimus Prime", _
		"product_price": 1000, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductsList.Add(M2)
		Main.WriteKVS("ProductsList", Main.ProductsList)
	End If
	WebApiUtils.ReturnLocation(Main.Config.Get("ROOT_PATH"), Response)
End Sub