BEGIN {
    FS = " "
}

/\[PROJNAME\]/ {
NEWLINE=$0
gsub(/\[PROJNAME\]/,PROJNAME,NEWLINE)
print NEWLINE
next
}

/\[ANIM\]/ {
NEWLINE=$0
gsub(/\[ANIM\]/,ANIM,NEWLINE)
print NEWLINE
next
}

/\[PROJECTS\]/ {
NEWLINE=$0
print NEWLINE
print ". $DEVS/projects/" PROJNAME ".env"
next
}

{
print $0
}
