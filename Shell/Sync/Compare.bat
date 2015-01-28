@echo off
@rem Compares Folder 1 with Folder 2 
robocopy %1 %2 /s /l /log:Compare.txt
start Compare.txt
echo on