REM When mining to a local node, you can drop the -s option.
echo ============================================================
echo = Running Cryptix Miner with default .bat. Edit to configure =
echo ============================================================
:start
cryptix-miner -a cryptix:qrjefk2r8wp607rmyvxmgjansqcwugjazpu2kk2r7057gltxetdvk8gl9fs0w -s 127.0.0.1 --port 19201 --threads 4  
goto start
