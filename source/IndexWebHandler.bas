B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
'Web Handler class
'Version 3.00
Sub Class_Globals
	Private App As EndsMeet
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Method As String
	Private Elements() As String
End Sub

Public Sub Initialize
	App = Main.app
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	If App.MethodAvailable2(Method, "", Me) = False Then
		WebApiUtils.ReturnHtmlMethodNotAllowed(Response)
		Return
	End If
	If ElementMatch("") Then
		' For demo purpose
		If Request.GetParameter("seed") <> "" Then
			SeedData
			Return
		End If
		ReturnPage
		Return
	End If
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ElementMatch (Pattern As String) As Boolean
	Select Pattern
		Case ""
			If Elements.Length = 0 Then
				Return True
			End If
	End Select
	Return False
End Sub

Private Sub ReturnPage
	Dim strScripts As String
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", Main.ReturnHelpElement)
	strMain = WebApiUtils.BuildHtml(strMain, App.ctx)
	strScripts = $"<script src="${App.ServerUrl}/assets/scripts/search.js"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHtml(strMain, Response)
End Sub

' Seed some dummy data into MimimaList
Private Sub SeedData
	If Main.CategoriesList.List.Size = 0 Then
		Dim M1 As Map = CreateMap("category_name": "Hardwares", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoriesList.Add(M1)
		Dim M1 As Map = CreateMap("category_name": "Toys", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoriesList.Add(M1)
		If Main.KVS_ENABLED Then Main.WriteKVS("CategoriesList", Main.CategoriesList)
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
		If Main.KVS_ENABLED Then Main.WriteKVS("ProductsList", Main.ProductsList)
	End If
	WebApiUtils.ReturnLocation(Main.App.ServerUrl, Response)
End Sub