# minimalist-api-b4j

Version: 2.06

Build REST API Server with MinimaList Using B4X Template

---

**Depends on following libraries:** 
- [WebApiUtils.b4xlib](https://github.com/pyhoon/WebApiUtils-B4J)
- [MinimaListUtils.b4xlib](https://github.com/pyhoon/MinimaListUtils-B4X)
- [MinimaListController.jar](https://github.com/pyhoon/MinimaListController-B4J) (optional)

*To connect to SQL database, please check https://github.com/pyhoon/webapi-2-b4j*

## Features
- Similar to Web API Server 2 but use MinimaListUtils instead of MiniORMUtils library.
- **MinimaList** is a library for storing key-value or Map into List.
- This API server can run without an SQL database.
- Optionally, MinimaList can be persisted using KeyValueStore library.
- Clients
	- Build-in front-end client (web)
	- Compatible with Web API Client (1.05).b4xtemplate (B4X UI apps)

### Code Example
```basic
Private Sub GetCategory (id As Long)
	' #Version = v2
	' #Desc = Read one Category by id
	' #Elements = [":id"]
	
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
http://127.0.0.1:19800/web/?seed=1

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
