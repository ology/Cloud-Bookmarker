# Cloud-Bookmarker
Manage bookmarks in the cloud

Example command line usage:

> plackup bin/app.psgi

> curl http://0:5000/add -X POST -d '{"account":"123","title":"Example","url":"https://example.com"}'

Better yet, use the Chrome external extension that comes with this repo.

Browse the bookmarks at http://0:5000/?a=123 by clicking the "Bookmarks" button in the extension.

* You will need to login.

To delete a bookmark, click the "x" button.

To update the url, title or tags of an entry, type in the text input and press the enter key.

Visit the bookmark by clicking the ">" button in the entry.

Check the return status by clicking the "?" button in the entry.  Blue = ok. Red = error.

*Web user interface:*

![Web user interface](https://raw.githubusercontent.com/ology/Cloud-Bookmarker/master/public/images/CB-Web_UI.png)

*Browser extension:*

![Browser extension](https://raw.githubusercontent.com/ology/Cloud-Bookmarker/master/public/images/CB-Extension.png)
