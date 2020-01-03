## OneDrive library
## ------------
##
## *Readme generated with [Nim to Markdown](https://github.com/ThomasTJdev/nimtomd)*
##
## This is a simple library to get information on files and folders in OneDrive.
## The library requires a public shared url to your OneDrive folder,
## which allows public access to files.
##
## When querying your OneDrive data, you get the data on the folder, and
## information on possible sub-folders and files. Normal querying only
## travel 1 level down, but the lib includes a *deep-diver*, which currently
## goes 3 levels down.
##
## The library output objects for files (`OnedriveFile`) and for folders
## (`OnedriveFolder`).
##
## The library uses the ole URL `https://api.onedrive.com/v1.0/shares/u!`
## which is not requiring any external libraries or accounts at OneDrive.
## This library does not support Microsoft Graph at the moment. PR's are
## welcome :)
##
## Requirements
## ------------
##
## The lib uses `packedjson` instead of `json`.
##
## Examples
## --------
##
## Required code
## =============
##
## The examples all uses this code. To access your OneDrive library
## you need to share a folder, which will provide you with a public
## URL. Take care of that URL, since everyone can use it to access
## your files.
##
## .. code-block::Nim
##    import onedrive
##    let publicUrl = "https://OneDrive-public-shared-url.com"
##    let accessUrl = onedriveUrl(publicUrl)
##
## Get 3 levels down and print
## ==============
##
## This example first gets the root folders information, and thereafter
## gets the 3 next levels of data. Finally it prints the result.
##
## .. code-block::Nim
##    # First access root data
##    let root = onedriveRootFull(accessUrl)
##
##    # Then deep dive 3 levels
##    let dive = onedriveFolderDive(accessUrl, root)
##
##    # Print the OneDrive structure
##    onedrivePrettyPath(dive)
##    # ├─ Test
##    # │ ├─ 2019-12-24 - Receipt.pdf
##    # │ ├─ flag_DK.png
##    # │ ├─ flag_UK.png
##    # │ ├─ SubFolder1
##    # │ │ ├─ Zone_final2.jpg
##    # │ │ ├─ newyear.jpeg
##    # │ │ ├─ SubAnother
##    # │ │ ├─ SubSubFolder
##    # │ │ │  └─ Guide_background.jpg
##    # │ │ └─ SubSubSub3
##    # │ │     └─ Informed.jpg
##    # │ ├─ SubFolder2
##    # │ │ └─ logo.png
##    # │ ├─ SubFolderEmpty
##
##
## Loop through subfolders names
## =============
## .. code-block::Nim
##    let folder = onedriveFolderFull(accessUrl, "SubFolder1")
##    echo "Main folder: " & folder.name
##
##    # Loop through folder names
##    for f in folder.childFolders:
##      echo "Folder name: " & f.name
##
##    # Loop through file names
##    for f in folder.childFiles:
##      echo "File name: " & f.name
##
## Get raw JSON result
## =============
##
## If you prefer the raw JSON output, then use the code below.
##
## .. code-block::Nim
##    let rootFolder         = accessUrl
##    let rootFolderFull     = accessUrl & "?expand=children"
##    let rootFolderChildren = accessUrl & "/children"
##    let folder             = accessUrl & ":/" & subfolderName
##    let folderFull         = accessUrl & ":/" & subfolderName & "?expand=children"
##    let folderChildren     = accessUrl & ":/" & subfolderName & ":/children"
##
##    let result = onedriveGetJson(folderFull)

import packedjson

from httpClient import newHttpClient, getContent
from base64 import encode

type
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


proc onedriveUrl*(publicUrl: string): string =
  ## Generate the onedrive url, which is used in all calls.
  ##
  ## You should use this to generate the access url:
  ## let accessUrl = onedriveUrl("publicurl.com")

  let publicUrlEncoded = encode(publicUrl)

  "https://api.onedrive.com/v1.0/shares/u!" & publicUrlEncoded & "/root"


proc onedriveGetJson*(url: string): JsonNode =
  ## Get the raw JSON result.
  ##
  ## Only use this, if you need the raw JSON and are parsing it yourself.

  # Init connection
  var client = newHttpClient()
  parseJson(client.getContent(url))


proc onedriveCreateFile(jobj: JsonNode): OnedriveFile =
  ## Create a onedrive file object

  # File data
  var file: OnedriveFile
  file.id = jobj["id"].getStr()
  file.createdByUser = jobj["createdBy"]["user"]["displayName"].getStr()
  file.createdByUserId = jobj["createdBy"]["user"]["id"].getStr()
  file.createdDateTime = jobj["createdDateTime"].getStr()
  file.lastModifiedByUser = jobj["lastModifiedBy"]["user"]["displayName"].getStr()
  file.lastModifiedByUserId = jobj["lastModifiedBy"]["user"]["id"].getStr()
  file.lastModifiedDateTime = jobj["lastModifiedDateTime"].getStr()
  file.name = jobj["name"].getStr()
  file.parentId = jobj["parentReference"]["id"].getStr()
  file.size = jobj["size"].getInt()
  file.webUrl = jobj["webUrl"].getStr()
  file.downloadUrl = jobj["@content.downloadUrl"].getStr()
  file.fileSha1Hash = jobj["file"]["hashes"]["sha1Hash"].getStr()
  file.fileMimeType = jobj["file"]["mimeType"].getStr()
  if hasKey(jobj, "image"):
    file.fileExt = "image"
    file.fileHeight = jobj["image"]["height"].getInt()
    file.fileWidth = jobj["image"]["width"].getInt()

  return file


proc onedriveCreateFolder(jobj: JsonNode): OnedriveFolder =
  ## Create a onedrive folder object

  # Folder data
  var folder: OnedriveFolder
  folder.id = jobj["id"].getStr()
  folder.createdByUser = jobj["createdBy"]["user"]["displayName"].getStr()
  folder.createdByUserId = jobj["createdBy"]["user"]["id"].getStr()
  folder.createdDateTime = jobj["createdDateTime"].getStr()
  folder.lastModifiedByUser = jobj["lastModifiedBy"]["user"]["displayName"].getStr()
  folder.lastModifiedByUserId = jobj["lastModifiedBy"]["user"]["id"].getStr()
  folder.lastModifiedDateTime = jobj["lastModifiedDateTime"].getStr()
  folder.name = jobj["name"].getStr()

  folder.parentDriveId = jobj["parentReference"]["driveId"].getStr()
  folder.parentDriveType = jobj["parentReference"]["driveType"].getStr()
  if hasKey(jobj["parentReference"], "id"):
    folder.parentId = jobj["parentReference"]["id"].getStr()
    folder.parentName = jobj["parentReference"]["name"].getStr()
    folder.parentPath = jobj["parentReference"]["path"].getStr()
    folder.parentShareId = jobj["parentReference"]["shareId"].getStr()

  folder.size = jobj["size"].getInt()
  folder.webUrl = jobj["webUrl"].getStr()
  folder.childCount = jobj["folder"]["childCount"].getInt()

  if hasKey(jobj, "shared"):
    folder.sharedEffectiveRoles = jobj["shared"]["effectiveRoles"].getStr()

  return folder


#[
proc onedriveCreateChildren(jobj: JsonNode, rootOri: OnedriveFolder): OnedriveFolder =
  ## Create structure for chilren

  var root = rootOri

  # Folder and files
  if hasKey(jobj, "value"):

    for child in items(jobj["value"]):

      # If folder
      if hasKey(child, "folder"):
        var folder: OnedriveFolder
        folder = onedriveCreateFolder(child)

        root.childFolders.add(folder)

      # If file
      else:
        var file: OnedriveFile
        file = onedriveCreateFile(child)

        root.childFiles.add(file)

  return root
]#

proc onedriveCreateChildrenFolders(jobj: JsonNode): seq[OnedriveFolder] =
  ## Create structure for chilren

  var folders: seq[OnedriveFolder]

  # Folder and files
  if hasKey(jobj, "value"):

    for child in items(jobj["value"]):

      # If folder
      if hasKey(child, "folder"):
        var folder: OnedriveFolder
        folder = onedriveCreateFolder(child)

        folders.add(folder)

  return folders


proc onedriveCreateChildrenFiles(jobj: JsonNode): seq[OnedriveFile] =
  ## Create structure for chilren

  var files: seq[OnedriveFile]

  # Folder and files
  if hasKey(jobj, "value"):

    for child in items(jobj["value"]):

      # If folder
      if not hasKey(child, "folder"):
        var file: OnedriveFile
        file = onedriveCreateFile(child)

        files.add(file)

  return files


proc onedriveCreateFull(jobj: JsonNode): OnedriveFolder =
  ## Create full folder structure

  var root: OnedriveFolder
  root = onedriveCreateFolder(jobj)

  # Folder and files
  if hasKey(jobj, "children"):

    for child in items(jobj["children"]):

      # If folder
      if hasKey(child, "folder"):
        var folder: OnedriveFolder
        folder = onedriveCreateFolder(child)

        root.childFolders.add(folder)

      # If file
      else:
        var file: OnedriveFile
        file = onedriveCreateFile(child)

        root.childFiles.add(file)

  return root


proc onedriveRoot*(accessUrl: string): OnedriveFolder =
  ## Get root folder data

  let url = accessUrl
  let jobj = onedriveGetJson(url)

  return onedriveCreateFolder(jobj)


proc onedriveRootFull*(accessUrl: string): OnedriveFolder =
  ## Get root folder and data for folder and files in top level

  let url = accessUrl & "?expand=children"
  let jobj = onedriveGetJson(url)

  return onedriveCreateFull(jobj)


proc onedriveRootChildren*(accessUrl: string, folderOri: OnedriveFolder): OnedriveFolder =
  ## Walk through subfolder and appends files and folders to the
  ## passed OnedriveFolder.
  ##
  ## Only for root folder. Use `onedriveRootFull()` instead.

  let url = accessUrl & "/children"
  let jobj = onedriveGetJson(url)

  let folders = onedriveCreateChildrenFolders(jobj)
  let files   = onedriveCreateChildrenFiles(jobj)

  var folder = folderOri
  folder.childFolders = folders
  folder.childFiles = files
  return folder


proc onedriveFolder*(accessUrl, subfolderName: string): OnedriveFolder =
  ## Gets folder data

  let url = accessUrl & ":/" & subfolderName
  let jobj = onedriveGetJson(url)

  return onedriveCreateFolder(jobj)


proc onedriveFolderFull*(accessUrl, subfolderName: string): OnedriveFolder =
  ## Gets folder data and data for all files and folders in the folder level

  let url = accessUrl & ":/" & subfolderName & "?expand=children"
  let jobj = onedriveGetJson(url)

  return onedriveCreateFull(jobj)


proc onedriveFolderChildren*(accessUrl, subfolderName: string, folderOri: OnedriveFolder): OnedriveFolder =
  ## Walk through subfolder and appends files and folders to the
  ## passed OnedriveFolder.

  let url = accessUrl & ":/" & subfolderName & ":/children"
  let jobj = onedriveGetJson(url)

  let folders = onedriveCreateChildrenFolders(jobj)
  let files   = onedriveCreateChildrenFiles(jobj)

  var folder = folderOri
  folder.childFolders = folders
  folder.childFiles = files
  return folder


proc onedriveFolderDive*(accessUrl: string, folderOri: OnedriveFolder): OnedriveFolder =
  ## Walk through files and folders and dive nth folders down
  ##
  ## DRY - quick and dirty needs recursive

  var folder = folderOri
  var c = 0

  # Level 1
  for n in folder.childFolders:
    let res = onedriveFolderChildren(accessUrl, n.name, n)
    folder.childFolders[c] = res

    # Level 2
    var v = 0
    for k in folder.childFolders[c].childFolders:
      # To access sub folders, whole path is needed
      let folderName = n.name & "/" & k.name
      # Lookup files and folders
      let res = onedriveFolderChildren(accessUrl, folderName, k)
      folder.childFolders[c].childFolders[v] = res

      # Level 3
      var b = 0
      for o in folder.childFolders[c].childFolders[v].childFolders:
        # To access sub folders, whole path is needed
        let folderName = n.name & "/" & k.name & "/" & o.name
        # Lookup files and folders
        let res = onedriveFolderChildren(accessUrl, folderName, o)
        folder.childFolders[c].childFolders[v].childFolders[b] = res
        # Level 3
        b += 1

      # Level 2
      v += 1

    # Level 1
    c += 1

  return folder


proc onedrivePrettyPath*(folder: OnedriveFolder) =
  ## Prints the folder structure.
  ##
  ## Does not print pretty - just print..

  echo "├─ " & folder.name

  if folder.childFiles.len() > 0:
    for b in folder.childFiles:
      echo "│ ├─ " & b.name

  if folder.childFolders.len() > 0:

    # Level 1
    for b in folder.childFolders:
      echo "│ ├─ " & b.name

      if b.childFiles.len() > 0:
        for fb in b.childFiles:
          if b.childFolders.len() > 0:
            echo "│ │ ├─ " & fb.name
          else:
            echo "│ │ └─ " & fb.name

      # Level 2
      if b.childFolders.len() > 0:
        for c in b.childFolders:
          if c.childFiles.len() > 0:
            echo "│ │ └─ " & c.name
          else:
            echo "│ │ ├─ " & c.name

          if c.childFiles.len() > 0:
            for fc in c.childFiles:
              echo "│ │   └─ " & fc.name

          # Level 3
          if c.childFolders.len() > 0:
            for d in c.childFolders:
              if d.childFiles.len() > 0:
                echo "│ │ └─ " & d.name
              else:
                echo "│ │ ├─ " & d.name

              if d.childFiles.len() > 0:
                for fd in d.childFiles:
                  echo "│ │     └─ " & fd.name