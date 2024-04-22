﻿B4J=true
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
	Private SecondIndex As Int
	Private SecondElement As String
	Private ThirdIndex As Int
	Private ThirdElement As String
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Private Sub ReturnApiResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

' Api Router
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
	If ElementLastIndex > ControllerIndex + 1 Then
		SecondIndex = ControllerIndex + 2
		SecondElement = Elements(SecondIndex)
	End If
	If ElementLastIndex > ControllerIndex + 2 Then
		ThirdIndex = ControllerIndex + 3
		ThirdElement = Elements(ThirdIndex)
	End If

	Select Method
		Case "GET"
			RouteGet
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
				Case ThirdIndex
					Select FirstElement
						Case "category"
							GetFindCategory(SecondElement, ThirdElement)
							Return
						Case "product"
							GetFindProduct(SecondElement, ThirdElement)
							Return
					End Select					
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub GetFindCategory (keyword As String, value As String)
	' #Version = v2
	' #Desc = Find Category by name
	' #Elements = ["category", ":keyword", ":value"]

	Dim L1 As List
	L1.Initialize
	Select keyword
		Case "category_name", "name"
			L1 = Main.CategoryList.FindAll(Array("category_name"), Array As String(value))
			HRM.ResponseCode = 200
			HRM.ResponseData = L1
		Case Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid keyword value"
	End Select
	ReturnApiResponse
End Sub

Private Sub GetFindProduct (keyword As String, value As String)
	' #Version = v2
	' #Desc = Find Product by id, cid, code or name
	' #Elements = ["product", ":keyword", ":value"]

	Dim L1 As List
	L1.Initialize
	Select keyword
		Case "id"
			If IsNumber(value) Then
				Dim id As Long = value
				Dim M1 As Map = Main.ProductList.Find(id)
				If M1.IsInitialized And M1.Size > 0 Then L1.Add(M1)
				HRM.ResponseCode = 200
			Else
				HRM.ResponseCode = 422
				HRM.ResponseError = "Error Unprocessable Entity"
			End If
		Case "category_id", "cid", "catid"
			If IsNumber(value) Then
				Dim cid As Long = value
				L1 = Main.ProductList.FindAll(Array("category_id"), Array As Long(cid))
				HRM.ResponseCode = 200
			Else
				HRM.ResponseCode = 422
				HRM.ResponseError = "Error Unprocessable Entity"
			End If
		Case "product_code", "code"
			L1 = Main.ProductList.FindAll(Array("product_code"), Array As String(value))
			HRM.ResponseCode = 200
		Case "category_name", "category"
			Dim C1 As Map = Main.CategoryList.FindFirst(Array("category_name"), Array As String(value))
			If C1.IsInitialized And C1.Size > 0 Then
				Dim cid As Long = C1.Get("id")
				L1 = Main.ProductList.FindAll(Array("category_id"), Array As Long(cid))
			End If
			HRM.ResponseCode = 200
		Case "product_name", "name"
			L1 = Main.ProductList.FindAnyLike(Array("product_name"), Array As String(value))
			HRM.ResponseCode = 200
		Case Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid keyword value"
	End Select
	HRM.ResponseData = L1
	ReturnApiResponse
End Sub