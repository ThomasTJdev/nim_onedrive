# OneDrive library

*Readme generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*

This is a simple library to get information on files and folders in OneDrive.
The library requires a public shared url to your OneDrive folder,
which allows public access to files.

When querying your OneDrive data, you get the data on the folder, and
information on possible sub-folders and files. Normal querying only
travel 1 level down, but the lib includes a *deep-diver*, which currently
goes 3 levels down.

The library output objects for files (`OnedriveFile`) and for folders
(`OnedriveFolder`).

The library uses the ole URL `https://api.onedrive.com/v1.0/shares/u!`
which is not requiring any external libraries or accounts at OneDrive.
This library does not support Microsoft Graph at the moment. PR's are
welcome :)

# Requirements

The lib uses `packedjson` instead of `json`.

# Examples

## Required code

The examples all uses this code. To access your OneDrive library
you need to share a folder, which will provide you with a public
URL. Take care of that URL, since everyone can use it to access
your files.

```nim
 import onedrive
 let publicUrl = "https://OneDrive-public-shared-url.com"
 let accessUrl = onedriveUrl(publicUrl)
```


## Get 3 levels down and print

This example first gets the root folders information, and thereafter
gets the 3 next levels of data. Finally it prints the result.

```nim
 # First access root data
 let root = onedriveRootFull(accessUrl)

 # Then deep dive 3 levels
 let dive = onedriveFolderDive(accessUrl, root)

 # Print the OneDrive structure
 onedrivePrettyPath(dive)
 # ├─ Test
 # │ ├─ 2019-12-24 - Receipt.pdf
 # │ ├─ flag_DK.png
 # │ ├─ flag_UK.png
 # │ ├─ SubFolder1
 # │ │ ├─ Zone_final2.jpg
 # │ │ ├─ newyear.jpeg
 # │ │ ├─ SubAnother
 # │ │ ├─ SubSubFolder
 # │ │ │  └─ Guide_background.jpg
 # │ │ └─ SubSubSub3
 # │ │     └─ Informed.jpg
 # │ ├─ SubFolder2
 # │ │ └─ logo.png
 # │ ├─ SubFolderEmpty
```



## Loop through subfolders names
```nim
 let folder = onedriveFolderFull(accessUrl, "SubFolder1")
 echo "Main folder: " & folder.name

 # Loop through folder names
 for f in folder.childFolders:
   echo "Folder name: " & f.name

 # Loop through file names
 for f in folder.childFiles:
   echo "File name: " & f.name
```


## Get raw JSON result

If you prefer the raw JSON output, then use the code below.

```nim
 let rootFolder         = accessUrl
 let rootFolderFull     = accessUrl & "?expand=children"
 let rootFolderChildren = accessUrl & "/children"
 let folder             = accessUrl & ":/" & subfolderName
 let folderFull         = accessUrl & ":/" & subfolderName & "?expand=children"
 let folderChildren     = accessUrl & ":/" & subfolderName & ":/children"

 let result = onedriveGetJson(folderFull)
```

# Imports
* packedjson

# Types
```nim
  OnedriveFile* = object
    id*: string
    createdByUser*: string
    createdByUserId*: string
    createdDateTime*: string
    lastModifiedByUser*: string
    lastModifiedByUserId*: string
    lastModifiedDateTime*: string
    name*: string
    parentId*: string
    size*: int
    webUrl*: string
    downloadUrl*: string
    fileSha1Hash*: string
    fileMimeType*: string
    fileExt*: string
    fileHeight*: int
    fileWidth*: int
```

```nim
  OnedriveFolder* = object
    id*: string
    createdByUser*: string
    createdByUserId*: string
    createdDateTime*: string
    lastModifiedByUser*: string
    lastModifiedByUserId*: string
    lastModifiedDateTime*: string
    name*: string
    parentDriveId*: string
    parentDriveType*: string
    parentId*: string
    parentName*: string
    parentPath*: string
    parentShareId*: string
    size*: int
    webUrl*: string
    childCount*: int
    childFolders*: seq[OnedriveFolder]
    childFiles*: seq[OnedriveFile]
    sharedEffectiveRoles*: string
```
# Procs
## proc onedriveUrl*
```nim
proc onedriveUrl*(publicUrl: string): string =
```
Generate the onedrive url, which is used in all calls.
You should use this to generate the access url:
let accessUrl = onedriveUrl("publicurl.com")
## proc onedriveGetJson*
```nim
proc onedriveGetJson*(url: string): JsonNode =
```
Get the raw JSON result.
Only use this, if you need the raw JSON and are parsing it yourself.
## proc onedriveRoot*
```nim
proc onedriveRoot*(accessUrl: string): OnedriveFolder =
```
Get root folder data
## proc onedriveRootFull*
```nim
proc onedriveRootFull*(accessUrl: string): OnedriveFolder =
```
Get root folder and data for folder and files in top level
## proc onedriveRootChildren*
```nim
proc onedriveRootChildren*(accessUrl: string, folderOri: OnedriveFolder): OnedriveFolder =
```
Walk through subfolder and appends files and folders to the
passed OnedriveFolder.
Only for root folder. Use `onedriveRootFull()` instead.
## proc onedriveFolder*
```nim
proc onedriveFolder*(accessUrl, subfolderName: string): OnedriveFolder =
```
Gets folder data
## proc onedriveFolderFull*
```nim
proc onedriveFolderFull*(accessUrl, subfolderName: string): OnedriveFolder =
```
Gets folder data and data for all files and folders in the folder level
## proc onedriveFolderChildren*
```nim
proc onedriveFolderChildren*(accessUrl, subfolderName: string, folderOri: OnedriveFolder): OnedriveFolder =
```
Walk through subfolder and appends files and folders to the
passed OnedriveFolder.
## proc onedriveFolderDive*
```nim
proc onedriveFolderDive*(accessUrl: string, folderOri: OnedriveFolder): OnedriveFolder =
```
Walk through files and folders and dive nth folders down
DRY - quick and dirty needs recursive
## proc onedrivePrettyPath*
```nim
proc onedrivePrettyPath*(folder: OnedriveFolder) =
```
Prints the folder structure.
Does not print pretty - just print..
