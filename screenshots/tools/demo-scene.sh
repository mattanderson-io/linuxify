#!/bin/bash
set -euo pipefail
rm -rf ~/demo
mkdir -p ~/demo/src ~/demo/docs ~/demo/build/cache
cd ~/demo
printf 'hello world\nthe quick brown fox\nerror: connection refused\nwarning: retrying\nhello again\n' > README.txt
printf 'alpha\nbeta\ngamma\ndelta\n' > before.txt
printf 'alpha\nBETA\ngamma\nepsilon\n' > after.txt
printf '#!/bin/sh\necho hi\n' > run.sh && chmod +x run.sh
printf 'INFO  starting\nERROR disk full\nINFO  ok\n' > app.log
printf '{"name":"linuxify-color","tools":["ls","grep","awk"],"count":45}\n' > config.json
head -c 2000 /dev/urandom > image.png
ln -s README.txt link-to-readme
ln -s /nowhere/missing broken-link
tar czf archive.tar.gz README.txt before.txt app.log
zip -q bundle.zip README.txt before.txt
echo "~/demo rebuilt"
