Bug report from a user:

> When I un-check a note that was done, the activity log shows "Completed: …" for it again. Un-checking should not create an activity entry at all.

Find the cause and fix it. Add a regression test the way this project tests things. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
