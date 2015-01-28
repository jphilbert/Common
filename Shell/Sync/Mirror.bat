@echo off
@rem Mirrors F1 (newer) -> F2 (newer)-> F1, deleting anything not in F1.
@rem Since it mirrors only newer files, this script subsequently mirrors
@rem F2 back to F1

@rem !!!! NOTE: THIS SCRIPT DELETES FILES !!!!

@rem /S = Subdirectories
@rem /XO = excludes older files
@rem /dcopy:t = copies directory timestamp
@rem /R:2 = retries 2
@rem /mir = mirror

robocopy %1 %2 /s /xo /dcopy:t /R:2 /mir /log:Mirror.txt
robocopy %2 %1 /s /xo /dcopy:t /R:2 /mir /log+:Mirror.txt
start Mirror.txt

echo on