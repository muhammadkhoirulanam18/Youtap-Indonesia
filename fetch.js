const fs = require('fs');
fetch('https://www.youtap.id/')
  .then(res => res.text())
  .then(text => fs.writeFileSync('live.html', text))
  .catch(err => console.error(err));
