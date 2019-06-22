// Set the current title and url
chrome.tabs.query({'active': true, 'windowId': chrome.windows.WINDOW_ID_CURRENT},
   function(tabs){
      document.getElementById('title').value = tabs[0].title;
      document.getElementById('url').value = tabs[0].url;
   }
);

document.getElementById("tags").addEventListener("keydown", function(e) {
    if (!e) { var e = window.event; }
    // Enter is pressed
    if (e.keyCode == 13) { submitFunction(); }
}, false);

// Submit button
var submit = document.querySelector("input[type=submit]");

// Submit event
submit.addEventListener("click", submitFunction);

function submitFunction (e) {
    var bookmark = {};

    bookmark.account = document.querySelector("input[name=account]").value;
    bookmark.tags = document.querySelector("input[name=tags]").value;
    bookmark.title = document.querySelector("input[name=title]").value;
    bookmark.url = document.querySelector("input[name=url]").value;

    postData("http://localhost:5000/add", JSON.stringify(bookmark))
        .then(function(data) {
            if(data) {
                alert("success!");
                window.close();
            }            
        })
        .catch(error => console.error(error));
}

// Fetch helper method
function postData(url = '', data = "") {
    return fetch(url, {
        method: 'POST',
        mode: 'no-cors',
        headers: {
            'Content-Type': 'application/json',
        },
        body: data,
    }).then(function(response) {
        return response;
    });
}
