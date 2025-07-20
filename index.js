const { exec } = require('child_process');
exec('rojo sourcemap default.project.json --output sourcemap.json');
console.log('✅ rojo sourcemap.json generated.');
exec('rojo sourcemap test-place.project.json --output sourcemap.json');
console.log('✅ rojo sourcemap.json generated.');
