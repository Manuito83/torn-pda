# 📲 Torn PDA - Share File Handler

This handler allows you to share a file (e.g., CSV, text, image) from your user script to the native app, which will then trigger the system share sheet (allowing you to save to files, share to other apps, etc.).

## Handler Name
`shareFile`

## Parameters
The handler expects a single object with the following properties:
- `base64Data` (string, required): The file content encoded in Base64.
- `fileName` (string, required): The name of the file to be created (e.g., "export.csv").

## Return Value
Returns a Promise that resolves to an object:
- `status`: "success" or "error"
- `message`: Description of the result

## Example Usage

Here is an example of how to modify a script that generates a CSV file to work with Torn PDA. We use a helper function to convert the text to Base64, which is the format required by the handler.

```javascript
// Helper function to convert text to Base64 (supports UTF-8)
function toBase64(text) {
  return btoa(unescape(encodeURIComponent(text)));
}

function downloadCSV(data, filename) {
  // Check if running in Torn PDA
  if (window.flutter_inappwebview) {
    
    window.flutter_inappwebview.callHandler('shareFile', {
      base64Data: toBase64(data), // Convert content to Base64
      fileName: filename
    }).then(function(result) {
      console.log("Share result:", result);
    }).catch(function(error) {
      console.error("Share error:", error);
    });

  } else {
    // Fallback for standard desktop/browser behavior
    const blob = new Blob([data], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }
}

// Example data generation
const csvContent = "Name,Value\nItem 1,100\nItem 2,200";
downloadCSV(csvContent, "items_export_test.csv");
```

### Handling Binary Data (e.g., Images)

If you are dealing with binary data (like an image blob), you need to convert it to a base64 string first.

```javascript
function shareImage(blob, filename) {
  var reader = new FileReader();
  reader.readAsDataURL(blob); 
  reader.onloadend = function() {
    // reader.result contains the Base64 string (including the data URL prefix)
    var base64data = reader.result;
    
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('shareFile', {
        base64Data: base64data,
        fileName: filename
      });
    }
  }
}
```

### Other File Types (e.g., Excel/XLSX, PDF, ZIP)

The handler works with **any** file type. The process is always the same:
1. Obtain the file content (usually as a `Blob` or `ArrayBuffer`).
2. Convert it to a Base64 string.
3. Pass the Base64 string and the correct filename (with extension) to the handler.

Since User Scripts often don't have access to external libraries, you will likely be working with raw data or `Blob` objects. The following helper function is universal: it takes a `Blob` (which can contain anything: PDF, Excel, ZIP, etc.) and shares it.

```javascript
function shareBlob(blob, filename) {
  var reader = new FileReader();
  reader.readAsDataURL(blob); 
  reader.onloadend = function() {
    // reader.result contains the Base64 string (including the data URL prefix)
    var base64data = reader.result;
    
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('shareFile', {
        base64Data: base64data,
        fileName: filename
      });
    }
  }
}

// Example: If you fetched a file from a URL
// fetch('https://example.com/report.xlsx')
//   .then(res => res.blob())
//   .then(blob => shareBlob(blob, 'report.xlsx'));
```

If you have a `Blob` or `ArrayBuffer` of any other file type (PDF, ZIP, etc.), you can use the same `FileReader` approach shown in the Image example above to get the Base64 string.

