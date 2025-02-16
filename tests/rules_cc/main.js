const fs = require('fs');
const path = require('path');

const directoryPath = path.join(__dirname);

fs.readdir(directoryPath, (err, files) => {
    if (err) {
        return console.log('Unable to scan directory: ' + err);
    } 
    files.forEach(file => {
        console.log(file);
    });
});
