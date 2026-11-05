Bug report from a user:

> When I check off a note and then restart the app, the note is unchecked again. Notes I add and the "newest first" setting do survive a restart.

Find the cause and fix it. Add a regression test the way this project tests things. When you are done, `fvm flutter analyze` must report no issues and `fvm flutter test` must pass.
