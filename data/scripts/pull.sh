# Pull test data from ua-parser-js.
git clone -n --depth=1 --filter=tree:0 https://github.com/faisalman/ua-parser-js/
cd ua-parser-js
git sparse-checkout set --no-cone /test/data/ua
git checkout