# oss-launch demo: a bare repo goes from a failing OSS audit to 16/16.
# Regenerate on any machine with vhs + ttyd + ffmpeg installed:
#   cd <repo> && vhs demo/oss-launch.tape   ->   docs/media/demo.gif
#
# (On this project's Windows dev box vhs could not run headless, so the committed GIF was
#  rendered from the same real audit output via a Playwright capture. This tape is the
#  portable, canonical way to regenerate it.)

Output docs/media/demo.gif

Set Shell bash
Set FontSize 18
Set Width 1200
Set Height 760
Set Theme "Dracula"
Set Padding 20
Set TypingSpeed 45ms

Hide
Type "REPO=$(pwd)" Enter
Type "alias audit='bash $REPO/scripts/audit.sh'" Enter
Type "bash $REPO/demo/scaffold.sh init /tmp/widget-cli" Enter
Type "cd /tmp/widget-cli && clear" Enter
Show

Type "# a bare repo. what is missing to open-source it?" Enter
Sleep 800ms
Type "audit ." Enter
Sleep 2500ms
Type "# /oss-launch scans, asks, and generates the files" Enter
Sleep 700ms
Type "bash $REPO/demo/scaffold.sh apply ." Enter
Sleep 900ms
Type "ls -a" Enter
Sleep 1500ms
Type "audit ." Enter
Sleep 3000ms
