@echo off
@rem Syncs F1 (newer) -> F2 (newer)-> F1, thus F1 = F2.

@rem /S = Subdirectories
@rem /XO = excludes older files
@rem /dcopy:t = copies directory timestamp
@rem /R:2 = retries 2
robocopy %1 %2 /s /xo /dcopy:t /R:2 /log:Sync.txt
robocopy %2 %1 /s /xo /dcopy:t /R:2 /log+:Sync.txt
start Sync.txt

echo on