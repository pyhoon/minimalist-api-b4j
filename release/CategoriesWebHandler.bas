B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
'Web Handler class
'Version 5.40
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
	Dim FullElements() As String = WebApiUtils.GetUriElements(Request.RequestURI)
	Elements = WebApiUtils.CropElements(FullElements, 2) ' 2 For Web handler
	If App.MethodAvailable2(Method, "/categories", Me) = False Then
		WebApiUtils.ReturnHtmlMethodNotAllowed(Response)
		Return
	End If
	If Elements.Length = 0 Then
		ReturnPage
		Return
	End If
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ReturnPage
	Dim strScripts As String
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("category.html")
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", Main.ReturnHelpElement)
	strMain = WebApiUtils.BuildHtml(strMain, App.ctx)
	strScripts = $"<script src="${App.ServerUrl}/assets/scripts/category.js"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHtml(strMain, Response)
End Sub

