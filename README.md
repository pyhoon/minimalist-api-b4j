# MinimaList API Server

Version: 3.00

Build REST API Server with MinimaList using B4X project template

---

**Depends on following libraries:** 
- [EndsMeet.b4xlib](https://github.com/pyhoon/EndsMeet)
- [WebApiUtils.b4xlib](https://github.com/pyhoon/WebApiUtils-B4J)
- [MinimaListUtils.b4xlib](https://github.com/pyhoon/MinimaListUtils-B4X)
- KeyValueStore

## Features
- Similar to Pakai Server but use MinimaListUtils instead of MiniORMUtils library.
- **MinimaList** is a library for storing key-value pairs or Map into List.
- This API server can run without an SQL database.
- Optionally, MinimaList can be persisted using KeyValueStore library.
- Clients
	- Build-in front-end client (web)
	- Compatible with Web API Client (1.05).b4xtemplate (B4X UI apps)

### Code Example
```basic
Private Sub GetCategory (id As Long)
	Dim M1 As Map = Main.CategoryList.Find(id)
	If M1.Size > 0 Then
		HRM.ResponseCode = 200
	Else
		HRM.ResponseCode = 404
	End If
	HRM.ResponseObject = M1
	ReturnApiResponse
End Sub
```
To seed dummy data in MinimaList API Server, browse to:
http://127.0.0.1:8080/?seed=1

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
