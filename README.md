# Cloud-Bookmarker
Manage bookmarks in the cloud

First create the database:

> perl bin/db-create.pl

> perl bin/db-insert.pl account_name password

Example command line usage:

> plackup bin/app.psgi

> curl http://0:5000/add -X POST -d '{"account":"account_name","title":"Example","url":"https://example.com"}'

Alternatively, use the Chrome external extension that comes in this repo.

Browse the bookmarks at http://0:5000/?a=account_name

* You will need to login first.

To delete a bookmark, click the "x" button.

To update the title or tags of an entry, type in the text input and press the enter key.

*Web user interface:*

![Web user interface](https://raw.githubusercontent.com/ology/Cloud-Bookmarker/master/public/images/CB-Web_UI.png)

*Browser extension:*

![Browser extension](https://raw.githubusercontent.com/ology/Cloud-Bookmarker/master/public/images/CB-Extension.png)
