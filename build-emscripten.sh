#!/bin/bash
# emscripten 3.1.42
echo -e "\033[01;32m --------------- START -------------------- \033[0m"
now=`date +'%Y-%m-%d %H:%M:%S'`
start_time=$(date --date="$now" +%s)

base_dir=$(cd "$(dirname "$0")";pwd)
mode="release"
if [ $1 ]; then mode=$1; fi

echo "--------|||  BUILD JS  |||--------"
echo "|||  GENERATE |||"
cd physx/
./generate_projects.bat emscripten-js
echo "|||  COMPILE |||"
cd compiler/emscripten-js-$mode
ninja

echo "--------|||  BUILD WASM  |||--------"
cd $base_dir
echo "|||  GENERATE |||"
cd physx/
./generate_projects.bat emscripten-wasm
echo "|||  COMPILE |||"
cd compiler/emscripten-wasm-$mode
ninja

echo "|||  COPY  |||"
cd $base_dir
mkdir -p $base_dir/builds
cp $base_dir/physx/bin/emscripten/$mode/physx.$mode.asm.js $base_dir/builds/physx.$mode.asm.js
cp $base_dir/physx/bin/emscripten/$mode/physx.$mode.wasm.js $base_dir/builds/physx.$mode.wasm.js
cp $base_dir/physx/bin/emscripten/$mode/physx.$mode.wasm.wasm $base_dir/builds/physx.$mode.wasm.wasm

cp -r $base_dir/builds/physx.$mode.asm.js ../../cocos-engine/native/external/emscripten/physx/physx.$mode.asm.js
cp -r $base_dir/builds/physx.$mode.wasm.js ../../cocos-engine/native/external/emscripten/physx/physx.$mode.wasm.js
cp -r $base_dir/builds/physx.$mode.wasm.wasm ../../cocos-engine/native/external/emscripten/physx/physx.$mode.wasm.wasm

echo "|||  FINISH  |||"

now=`date +'%Y-%m-%d %H:%M:%S'`
end_time=$(date --date="$now" +%s);
echo -e "\033[01;32m Time Used: "$((end_time-start_time))"s  \033[1m"
echo -e "\033[01;32m ------------- END -----------------  \033[0m"

read